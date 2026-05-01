"""
accounts/views.py

All authentication and account management API views.
Design principles:
  - Views are thin: validation in serializers, logic in services.
  - Every endpoint returns a consistent envelope: {status, message, data}.
  - All significant events are written to AuditLog via AuditService.
  - No raw exceptions leak to the client.
"""

from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView

from .models import AuditLog, OTPVerification, User
from .permissions import IsAdminUser, IsOwnerOrAdmin
from .serializers import (
    LoginSerializer,
    PasswordResetConfirmSerializer,
    PasswordResetRequestSerializer,
    ProfileUpdateSerializer,
    RegisterSerializer,
    SendOTPSerializer,
    UserSerializer,
    VerifyOTPSerializer,
)
from .services import AuditService, OTPService


# ---------------------------------------------------------------------------
# Response helper
# ---------------------------------------------------------------------------

def api_response(
    data=None,
    message: str = "",
    status_code: int = status.HTTP_200_OK,
    errors=None,
) -> Response:
    """
    Standardised JSON envelope used across all endpoints:
    {
        "status": "success" | "error",
        "message": "...",
        "data": {...} | null,
        "errors": {...} | null
    }
    """
    return Response(
        {
            "status":  "error" if errors else "success",
            "message": message,
            "data":    data,
            "errors":  errors,
        },
        status=status_code,
    )


# ---------------------------------------------------------------------------
# Registration
# ---------------------------------------------------------------------------

class RegisterView(APIView):
    """
    POST /auth/register/

    Creates a new user account and dispatches an OTP to the provided
    phone number.  Account is active but `is_phone_verified=False` until
    the OTP is confirmed.

    Roles: patient and doctor can self-register.
    Admin accounts require an existing admin to create them.
    """
    permission_classes = [AllowAny]
    throttle_scope     = "registration"   # configure in settings

    def post(self, request):
        serializer = RegisterSerializer(
            data=request.data,
            context={"request": request},
        )
        if not serializer.is_valid():
            return api_response(
                message="Registration failed. Please fix the errors below.",
                errors=serializer.errors,
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        user: User = serializer.save()

        # Fire OTP
        OTPService.send_otp(user, OTPVerification.Purpose.PHONE_REGISTRATION)

        # Audit
        AuditService.log(
            event_type  = AuditLog.EventType.REGISTER,
            user        = user,
            description = f"New {user.role} account registered.",
            request     = request,
            metadata    = {"role": user.role},
        )

        return api_response(
            data    = {"user_id": user.id, "username": user.username},
            message = (
                "Registration successful. A 6-digit OTP has been sent to your "
                "phone number. Please verify to activate your account."
            ),
            status_code = status.HTTP_201_CREATED,
        )


# ---------------------------------------------------------------------------
# OTP
# ---------------------------------------------------------------------------

class SendOTPView(APIView):
    """
    POST /auth/otp/send/

    (Re-)send an OTP to the user's registered phone number.
    Used after registration and for password reset.
    """
    permission_classes = [AllowAny]
    throttle_scope     = "otp"

    def post(self, request):
        serializer = SendOTPSerializer(data=request.data)
        if not serializer.is_valid():
            return api_response(
                message="Unable to send OTP.",
                errors=serializer.errors,
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        phone   = serializer.validated_data["phone_number"]
        purpose = serializer.validated_data["purpose"]
        user    = User.objects.get(phone_number=phone)

        OTPService.send_otp(user, purpose)

        return api_response(
            message=f"OTP sent to {phone}. Valid for 5 minutes.",
        )


class VerifyOTPView(APIView):
    """
    POST /auth/otp/verify/

    Validates the OTP and marks the phone as verified.
    Returns a JWT token pair so the user can proceed immediately
    after registration without a separate login step.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        if not serializer.is_valid():
            return api_response(
                message="OTP verification failed.",
                errors=serializer.errors,
                status_code=status.HTTP_400_BAD_REQUEST,
            )

        user: User = serializer.validated_data["_user"]
        otp: OTPVerification = serializer.validated_data["_otp"]
        purpose = serializer.validated_data["purpose"]

        # Consume the OTP
        otp.consume()

        # Mark phone verified on registration OTP
        if purpose == OTPVerification.Purpose.PHONE_REGISTRATION:
            user.is_phone_verified = True
            user.save(update_fields=["is_phone_verified"])

        # Issue tokens so user is logged in immediately
        refresh = RefreshToken.for_user(user)
        refresh["role"]      = user.role
        refresh["full_name"] = user.get_full_name()

        AuditService.log(
            event_type  = AuditLog.EventType.LOGIN,
            user        = user,
            description = f"Phone verified via OTP ({purpose}).",
            request     = request,
        )

        return api_response(
            data={
                "tokens": {
                    "refresh": str(refresh),
                    "access":  str(refresh.access_token),
                },
                "user": UserSerializer(user).data,
            },
            message="Phone verified successfully.",
        )


# ---------------------------------------------------------------------------
# Login / Logout
# ---------------------------------------------------------------------------

class LoginView(APIView):
    """
    POST /auth/login/

    Accepts username / email / phone_number + password.
    Returns JWT access + refresh tokens on success.
    Enforces account lockout policy.
    """
    permission_classes = [AllowAny]
    throttle_scope     = "login"

    def post(self, request):
        serializer = LoginSerializer(
            data=request.data,
            context={"request": request},
        )
        if not serializer.is_valid():
            # Determine if this was a lockout error or credential error
            errors = serializer.errors
            flat   = str(errors)
            event  = (
                AuditLog.EventType.LOCKOUT
                if "locked" in flat
                else AuditLog.EventType.FAILED_LOGIN
            )

            # Try to resolve the user for audit log (best-effort)
            login_value = request.data.get("login", "")
            audit_user  = LoginSerializer._resolve_user(login_value)

            AuditService.log(
                event_type  = event,
                user        = audit_user,
                description = f"Failed login attempt for identifier '{login_value}'.",
                request     = request,
            )

            return api_response(
                message     = "Login failed.",
                errors      = errors,
                status_code = status.HTTP_401_UNAUTHORIZED,
            )

        user: User   = serializer.validated_data["user"]
        tokens: dict = serializer.validated_data["tokens"]

        AuditService.log(
            event_type  = AuditLog.EventType.LOGIN,
            user        = user,
            description = "Successful login.",
            request     = request,
            metadata    = {"role": user.role},
        )

        return api_response(
            data={
                "tokens": tokens,
                "user":   UserSerializer(user).data,
            },
            message="Login successful.",
        )


class LogoutView(APIView):
    """
    POST /auth/logout/

    Blacklists the refresh token so it cannot be reused.
    Requires the client to send the refresh token in the request body.
    Requires: djangorestframework-simplejwt with token blacklisting enabled.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        refresh_token = request.data.get("refresh")
        if not refresh_token:
            return api_response(
                message     = "Refresh token is required.",
                errors      = {"refresh": "This field is required."},
                status_code = status.HTTP_400_BAD_REQUEST,
            )

        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
        except TokenError as exc:
            return api_response(
                message     = "Token is invalid or already expired.",
                errors      = {"refresh": str(exc)},
                status_code = status.HTTP_400_BAD_REQUEST,
            )

        AuditService.log(
            event_type  = AuditLog.EventType.LOGOUT,
            user        = request.user,
            description = "User logged out and refresh token blacklisted.",
            request     = request,
        )

        return api_response(message="Logged out successfully.")


# ---------------------------------------------------------------------------
# Password Reset
# ---------------------------------------------------------------------------

class PasswordResetRequestView(APIView):
    """
    POST /auth/password/reset/request/

    Sends a password-reset OTP to the user's phone or email.
    """
    permission_classes = [AllowAny]
    throttle_scope     = "otp"

    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return api_response(
                message     = "Could not initiate password reset.",
                errors      = serializer.errors,
                status_code = status.HTTP_400_BAD_REQUEST,
            )

        user: User = serializer.validated_data["_user"]
        OTPService.send_otp(user, OTPVerification.Purpose.PASSWORD_RESET)

        AuditService.log(
            event_type  = AuditLog.EventType.PASSWORD_RESET,
            user        = user,
            description = "Password reset OTP requested.",
            request     = request,
        )

        # Always return a vague success message to prevent user enumeration
        return api_response(
            message=(
                "If an account exists with the provided details, "
                "a reset code has been sent."
            )
        )


class PasswordResetConfirmView(APIView):
    """
    POST /auth/password/reset/confirm/

    Validates the OTP and sets the new password.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        if not serializer.is_valid():
            return api_response(
                message     = "Password reset failed.",
                errors      = serializer.errors,
                status_code = status.HTTP_400_BAD_REQUEST,
            )

        user: User              = serializer.validated_data["_user"]
        otp: OTPVerification    = serializer.validated_data["_otp"]
        new_password: str       = serializer.validated_data["new_password"]

        otp.consume()
        user.set_password(new_password)
        user.reset_login_attempts()   # clear any lockout on successful reset
        user.save()

        AuditService.log(
            event_type  = AuditLog.EventType.PASSWORD_RESET,
            user        = user,
            description = "Password reset completed successfully.",
            request     = request,
        )

        return api_response(message="Password reset successful. You may now log in.")


# ---------------------------------------------------------------------------
# Profile
# ---------------------------------------------------------------------------

class ProfileView(APIView):
    """
    GET  /auth/profile/       — retrieve own profile
    PATCH /auth/profile/      — partial update own profile
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return api_response(
            data    = serializer.data,
            message = "Profile retrieved successfully.",
        )

    def patch(self, request):
        serializer = ProfileUpdateSerializer(
            instance = request.user,
            data     = request.data,
            partial  = True,
            context  = {"request": request},
        )
        if not serializer.is_valid():
            return api_response(
                message     = "Profile update failed.",
                errors      = serializer.errors,
                status_code = status.HTTP_400_BAD_REQUEST,
            )

        user = serializer.save()

        AuditService.log(
            event_type  = AuditLog.EventType.PROFILE_UPDATE,
            user        = user,
            description = "User updated their profile.",
            request     = request,
            metadata    = {"updated_fields": list(request.data.keys())},
        )

        return api_response(
            data    = UserSerializer(user).data,
            message = "Profile updated successfully.",
        )


class AdminUserDetailView(APIView):
    """
    GET   /auth/users/<pk>/     — admin: view any user profile
    PATCH /auth/users/<pk>/     — admin: update any user profile
    DELETE /auth/users/<pk>/    — admin: deactivate user account
    """
    permission_classes = [IsAuthenticated, IsAdminUser]

    def _get_user(self, pk: int) -> User | None:
        try:
            return User.objects.select_related(
                "patient_profile", "doctor_profile"
            ).get(pk=pk)
        except User.DoesNotExist:
            return None

    def get(self, request, pk: int):
        user = self._get_user(pk)
        if not user:
            return api_response(
                message     = "User not found.",
                status_code = status.HTTP_404_NOT_FOUND,
            )
        return api_response(
            data    = UserSerializer(user).data,
            message = "User retrieved successfully.",
        )

    def patch(self, request, pk: int):
        user = self._get_user(pk)
        if not user:
            return api_response(
                message     = "User not found.",
                status_code = status.HTTP_404_NOT_FOUND,
            )
        serializer = ProfileUpdateSerializer(
            instance = user,
            data     = request.data,
            partial  = True,
        )
        if not serializer.is_valid():
            return api_response(
                message     = "Update failed.",
                errors      = serializer.errors,
                status_code = status.HTTP_400_BAD_REQUEST,
            )
        updated_user = serializer.save()

        AuditService.log(
            event_type  = AuditLog.EventType.PROFILE_UPDATE,
            user        = request.user,
            description = f"Admin updated profile of user #{pk}.",
            request     = request,
            metadata    = {"target_user_id": pk},
        )

        return api_response(
            data    = UserSerializer(updated_user).data,
            message = "User updated successfully.",
        )

    def delete(self, request, pk: int):
        """Soft-delete: deactivate the account instead of destroying the record."""
        user = self._get_user(pk)
        if not user:
            return api_response(
                message     = "User not found.",
                status_code = status.HTTP_404_NOT_FOUND,
            )
        if user == request.user:
            return api_response(
                message     = "Administrators cannot deactivate their own account via this endpoint.",
                status_code = status.HTTP_400_BAD_REQUEST,
            )

        user.is_active = False
        user.save(update_fields=["is_active"])

        AuditService.log(
            event_type  = AuditLog.EventType.ROLE_CHANGE,
            user        = request.user,
            description = f"Admin deactivated user account #{pk}.",
            request     = request,
            metadata    = {"target_user_id": pk, "action": "deactivate"},
        )

        return api_response(message=f"User account #{pk} has been deactivated.")


class AdminUserListView(APIView):
    """
    GET /auth/users/?role=patient&search=john&is_active=true

    Paginated list of all users. Admin only.
    """
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get(self, request):
        qs = User.objects.select_related(
            "patient_profile", "doctor_profile"
        ).order_by("-created_at")

        # Filter by role
        role = request.query_params.get("role")
        if role:
            qs = qs.filter(role=role)

        # Filter by active status
        is_active = request.query_params.get("is_active")
        if is_active is not None:
            qs = qs.filter(is_active=is_active.lower() == "true")

        # Search by name / username / phone
        search = request.query_params.get("search", "").strip()
        if search:
            from django.db.models import Q
            qs = qs.filter(
                Q(username__icontains=search)
                | Q(first_name__icontains=search)
                | Q(last_name__icontains=search)
                | Q(phone_number__icontains=search)
                | Q(email__icontains=search)
            )

        # Simple manual pagination (replace with DRF PageNumberPagination in settings)
        page_size = min(int(request.query_params.get("page_size", 20)), 100)
        page      = max(int(request.query_params.get("page", 1)), 1)
        offset    = (page - 1) * page_size
        total     = qs.count()
        users     = qs[offset : offset + page_size]

        return api_response(
            data={
                "count":    total,
                "page":     page,
                "pages":    -(-total // page_size),   # ceiling division
                "results":  UserSerializer(users, many=True).data,
            },
            message="Users retrieved successfully.",
        )


# ---------------------------------------------------------------------------
# Token Refresh  (overrides simplejwt default to match envelope)
# ---------------------------------------------------------------------------

class TokenRefreshEnvelopeView(TokenRefreshView):
    """
    POST /auth/token/refresh/

    Wraps simplejwt's default response in our standard envelope.
    """

    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        if response.status_code == status.HTTP_200_OK:
            return api_response(
                data    = response.data,
                message = "Token refreshed successfully.",
            )
        return api_response(
            message     = "Token refresh failed.",
            errors      = response.data,
            status_code = response.status_code,
        )
"""
accounts/serializers.py

All request/response serializers for the accounts module.
Each serializer has an explicit `fields` list (no `__all__`) so the API
surface is intentional and safe against field-level data leaks.
"""

from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.utils import timezone
from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken

from .models import (
    AuditLog,
    DoctorProfile,
    OTPVerification,
    PatientProfile,
    User,
    UserRole,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _get_tokens(user: User) -> dict:
    """Return a fresh JWT token pair for the given user."""
    refresh = RefreshToken.for_user(user)
    # Embed role in token payload for Flutter-side routing
    refresh["role"] = user.role
    refresh["full_name"] = user.get_full_name()
    return {
        "refresh": str(refresh),
        "access": str(refresh.access_token),
    }


# ---------------------------------------------------------------------------
# Profile sub-serializers  (nested, read-write)
# ---------------------------------------------------------------------------

class PatientProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = PatientProfile
        fields = [
            "blood_group",
            "allergies",
            "emergency_contact_name",
            "emergency_contact_phone",
            "medical_history",
        ]


class DoctorProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = DoctorProfile
        fields = [
            "specialization",
            "medical_license_number",
            "hospital_name",
            "consultation_fee",
            "years_of_experience",
            "is_accepting_patients",
            "bio",
            "avg_consultation_minutes",
        ]


# ---------------------------------------------------------------------------
# User read serializer  (safe public representation)
# ---------------------------------------------------------------------------

class UserSerializer(serializers.ModelSerializer):
    """
    Read-only representation returned after login / profile fetch.
    Role-specific profile is included only when it exists.
    """
    patient_profile = PatientProfileSerializer(read_only=True)
    doctor_profile  = DoctorProfileSerializer(read_only=True)
    full_name       = serializers.SerializerMethodField()

    class Meta:
        model  = User
        fields = [
            "id",
            "username",
            "email",
            "first_name",
            "last_name",
            "full_name",
            "role",
            "phone_number",
            "date_of_birth",
            "gender",
            "address",
            "profile_picture_url",
            "is_phone_verified",
            "is_email_verified",
            "whatsapp_number",
            "whatsapp_linked",
            "notif_push",
            "notif_sms",
            "notif_whatsapp",
            "patient_profile",
            "doctor_profile",
            "created_at",
        ]
        read_only_fields = fields  # this serializer is strictly read-only

    def get_full_name(self, obj: User) -> str:
        return obj.get_full_name() or obj.username


# ---------------------------------------------------------------------------
# Registration
# ---------------------------------------------------------------------------

class RegisterSerializer(serializers.Serializer):
    """
    Handles new user sign-up for all roles.
    Doctor-specific fields are optional at registration and can be
    completed later via the profile update endpoint.
    """

    # --- Core identity ---
    username        = serializers.CharField(max_length=150)
    email           = serializers.EmailField()
    phone_number    = serializers.CharField(max_length=20)
    password        = serializers.CharField(
        write_only=True,
        style={"input_type": "password"},
    )
    password_confirm = serializers.CharField(
        write_only=True,
        style={"input_type": "password"},
    )
    first_name      = serializers.CharField(max_length=150)
    last_name       = serializers.CharField(max_length=150)
    role            = serializers.ChoiceField(choices=UserRole.choices)
    gender          = serializers.CharField(max_length=15, required=False, default="unspecified")
    date_of_birth   = serializers.DateField(required=False, allow_null=True)
    address         = serializers.CharField(required=False, default="")

    # --- Doctor-only (ignored for patients) ---
    specialization          = serializers.CharField(required=False, default="")
    medical_license_number  = serializers.CharField(required=False, default="")
    hospital_name           = serializers.CharField(required=False, default="")
    consultation_fee        = serializers.DecimalField(
        max_digits=10, decimal_places=2, required=False, default=0
    )

    # --- Patient-only (ignored for doctors) ---
    blood_group             = serializers.CharField(required=False, default="")
    emergency_contact_name  = serializers.CharField(required=False, default="")
    emergency_contact_phone = serializers.CharField(required=False, default="")

    def validate_username(self, value: str) -> str:
        if User.objects.filter(username__iexact=value).exists():
            raise serializers.ValidationError("This username is already taken.")
        return value

    def validate_email(self, value: str) -> str:
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("An account with this email already exists.")
        return value

    def validate_phone_number(self, value: str) -> str:
        if User.objects.filter(phone_number=value).exists():
            raise serializers.ValidationError("An account with this phone number already exists.")
        return value

    def validate_password(self, value: str) -> str:
        validate_password(value)  # runs Django's built-in password validators
        return value

    def validate(self, attrs: dict) -> dict:
        if attrs["password"] != attrs.pop("password_confirm"):
            raise serializers.ValidationError({"password_confirm": "Passwords do not match."})

        # Prevent patients from self-assigning admin role
        if attrs["role"] == UserRole.ADMIN:
            request = self.context.get("request")
            if not (request and request.user.is_authenticated and request.user.is_admin_user):
                raise serializers.ValidationError(
                    {"role": "Admin accounts must be created by an existing administrator."}
                )
        return attrs

    def create(self, validated_data: dict) -> User:
        # --- Extract profile-specific fields before User creation ---
        doctor_fields = {
            "specialization":           validated_data.pop("specialization", ""),
            "medical_license_number":   validated_data.pop("medical_license_number", ""),
            "hospital_name":            validated_data.pop("hospital_name", ""),
            "consultation_fee":         validated_data.pop("consultation_fee", 0),
        }
        patient_fields = {
            "blood_group":              validated_data.pop("blood_group", ""),
            "emergency_contact_name":   validated_data.pop("emergency_contact_name", ""),
            "emergency_contact_phone":  validated_data.pop("emergency_contact_phone", ""),
        }

        password = validated_data.pop("password")
        user = User(**validated_data)
        user.set_password(password)
        # New accounts are inactive until OTP verification
        user.is_active = True          # active but phone not verified
        user.is_phone_verified = False
        user.save()

        # Create role-specific profile
        if user.role == UserRole.DOCTOR:
            DoctorProfile.objects.create(user=user, **doctor_fields)
        elif user.role == UserRole.PATIENT:
            PatientProfile.objects.create(user=user, **patient_fields)

        return user


# ---------------------------------------------------------------------------
# OTP
# ---------------------------------------------------------------------------

class SendOTPSerializer(serializers.Serializer):
    """Request a new OTP for a given phone number."""
    phone_number = serializers.CharField(max_length=20)
    purpose      = serializers.ChoiceField(
        choices=OTPVerification.Purpose.choices,
        default=OTPVerification.Purpose.PHONE_REGISTRATION,
    )

    def validate_phone_number(self, value: str) -> str:
        if not User.objects.filter(phone_number=value).exists():
            raise serializers.ValidationError("No account found with this phone number.")
        return value


class VerifyOTPSerializer(serializers.Serializer):
    """Submit an OTP code to verify phone ownership."""
    phone_number = serializers.CharField(max_length=20)
    code         = serializers.CharField(min_length=6, max_length=6)
    purpose      = serializers.ChoiceField(
        choices=OTPVerification.Purpose.choices,
        default=OTPVerification.Purpose.PHONE_REGISTRATION,
    )

    def validate(self, attrs: dict) -> dict:
        try:
            user = User.objects.get(phone_number=attrs["phone_number"])
        except User.DoesNotExist:
            raise serializers.ValidationError({"phone_number": "No account found."})

        otp = (
            OTPVerification.objects
            .filter(
                user=user,
                code=attrs["code"],
                purpose=attrs["purpose"],
                is_used=False,
            )
            .order_by("-created_at")
            .first()
        )

        if otp is None:
            raise serializers.ValidationError({"code": "Invalid OTP code."})
        if not otp.is_valid:
            raise serializers.ValidationError({"code": "OTP has expired. Please request a new one."})

        attrs["_user"] = user
        attrs["_otp"]  = otp
        return attrs


# ---------------------------------------------------------------------------
# Login
# ---------------------------------------------------------------------------

class LoginSerializer(serializers.Serializer):
    """
    Accepts login via username OR phone_number plus password.
    Returns JWT token pair + user representation on success.
    """
    login    = serializers.CharField(
        help_text="Username, email, or phone number"
    )
    password = serializers.CharField(
        write_only=True,
        style={"input_type": "password"},
    )

    def validate(self, attrs: dict) -> dict:
        login    = attrs["login"].strip()
        password = attrs["password"]

        # Resolve the user by username, email, or phone
        user = self._resolve_user(login)

        if user is None:
            raise serializers.ValidationError(
                {"login": "No account found with these credentials."}
            )

        # Check lockout BEFORE attempting authentication
        if user.is_locked_out:
            unlock_at = user.lockout_until.strftime("%H:%M")
            raise serializers.ValidationError(
                {
                    "non_field_errors": (
                        f"Account locked after too many failed attempts. "
                        f"Try again after {unlock_at}."
                    )
                }
            )

        # Authenticate
        authenticated_user = authenticate(
            request=self.context.get("request"),
            username=user.username,
            password=password,
        )

        if authenticated_user is None:
            user.record_failed_login()
            remaining = max(0, 3 - user.failed_login_attempts)
            msg = "Incorrect password."
            if remaining == 0:
                msg = (
                    f"Account locked for {15} minutes due to too many "
                    "failed login attempts."
                )
            elif remaining <= 2:
                msg = f"Incorrect password. {remaining} attempt(s) remaining before lockout."
            raise serializers.ValidationError({"password": msg})

        if not authenticated_user.is_active:
            raise serializers.ValidationError(
                {"non_field_errors": "This account has been deactivated."}
            )

        # Success — reset counter, generate tokens
        authenticated_user.reset_login_attempts()

        attrs["user"]   = authenticated_user
        attrs["tokens"] = _get_tokens(authenticated_user)
        return attrs

    @staticmethod
    def _resolve_user(login: str):
        """Find User by username, email, or phone number."""
        for field in ("username", "email", "phone_number"):
            try:
                return User.objects.get(**{field: login})
            except User.DoesNotExist:
                continue
        return None


# ---------------------------------------------------------------------------
# Password Reset
# ---------------------------------------------------------------------------

class PasswordResetRequestSerializer(serializers.Serializer):
    """Request a password-reset OTP via phone or email."""
    phone_number = serializers.CharField(max_length=20, required=False)
    email        = serializers.EmailField(required=False)

    def validate(self, attrs: dict) -> dict:
        phone = attrs.get("phone_number")
        email = attrs.get("email")
        if not phone and not email:
            raise serializers.ValidationError(
                "Provide either phone_number or email."
            )
        user = None
        if phone:
            user = User.objects.filter(phone_number=phone).first()
        if not user and email:
            user = User.objects.filter(email__iexact=email).first()
        if not user:
            raise serializers.ValidationError(
                "No account found with the provided details."
            )
        attrs["_user"] = user
        return attrs


class PasswordResetConfirmSerializer(serializers.Serializer):
    """Consume OTP + set new password."""
    phone_number     = serializers.CharField(max_length=20)
    code             = serializers.CharField(min_length=6, max_length=6)
    new_password     = serializers.CharField(
        write_only=True, style={"input_type": "password"}
    )
    confirm_password = serializers.CharField(
        write_only=True, style={"input_type": "password"}
    )

    def validate_new_password(self, value: str) -> str:
        validate_password(value)
        return value

    def validate(self, attrs: dict) -> dict:
        if attrs["new_password"] != attrs["confirm_password"]:
            raise serializers.ValidationError(
                {"confirm_password": "Passwords do not match."}
            )

        otp_data = VerifyOTPSerializer(
            data={
                "phone_number": attrs["phone_number"],
                "code": attrs["code"],
                "purpose": OTPVerification.Purpose.PASSWORD_RESET,
            }
        )
        otp_data.is_valid(raise_exception=True)
        attrs["_user"] = otp_data.validated_data["_user"]
        attrs["_otp"]  = otp_data.validated_data["_otp"]
        return attrs


# ---------------------------------------------------------------------------
# Profile Update
# ---------------------------------------------------------------------------

class ProfileUpdateSerializer(serializers.ModelSerializer):
    """
    Partial update of the User record + nested role profile.
    Only fields that are sent get updated (PATCH semantics).
    """
    patient_profile = PatientProfileSerializer(required=False)
    doctor_profile  = DoctorProfileSerializer(required=False)

    class Meta:
        model  = User
        fields = [
            "first_name",
            "last_name",
            "email",
            "phone_number",
            "date_of_birth",
            "gender",
            "address",
            "profile_picture_url",
            "whatsapp_number",
            "whatsapp_linked",
            "notif_push",
            "notif_sms",
            "notif_whatsapp",
            "patient_profile",
            "doctor_profile",
        ]

    def validate(self, attrs: dict) -> dict:
        # Ensure at least one notification channel remains active
        user = self.instance
        push      = attrs.get("notif_push",     user.notif_push)
        sms       = attrs.get("notif_sms",      user.notif_sms)
        whatsapp  = attrs.get("notif_whatsapp", user.notif_whatsapp)
        if not any([push, sms, whatsapp]):
            raise serializers.ValidationError(
                "At least one notification channel must remain enabled."
            )
        return attrs

    def update(self, instance: User, validated_data: dict) -> User:
        # Handle nested profiles
        patient_data = validated_data.pop("patient_profile", None)
        doctor_data  = validated_data.pop("doctor_profile", None)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        if patient_data and instance.is_patient:
            profile, _ = PatientProfile.objects.get_or_create(user=instance)
            for attr, value in patient_data.items():
                setattr(profile, attr, value)
            profile.save()

        if doctor_data and instance.is_doctor:
            profile, _ = DoctorProfile.objects.get_or_create(user=instance)
            for attr, value in doctor_data.items():
                setattr(profile, attr, value)
            profile.save()

        return instance


# ---------------------------------------------------------------------------
# Token refresh (thin wrapper — mainly for Swagger documentation)
# ---------------------------------------------------------------------------

class TokenRefreshResponseSerializer(serializers.Serializer):
    access = serializers.CharField(read_only=True)


# ---------------------------------------------------------------------------
# Audit Log read serializer
# ---------------------------------------------------------------------------

class AuditLogSerializer(serializers.ModelSerializer):
    user_display = serializers.StringRelatedField(source="user", read_only=True)

    class Meta:
        model  = AuditLog
        fields = [
            "id",
            "user_display",
            "event_type",
            "description",
            "ip_address",
            "metadata",
            "created_at",
        ]
        read_only_fields = fields
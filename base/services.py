"""
accounts/services.py

Business logic layer — keeps views thin and logic testable.
All external I/O (OTP dispatch, notifications) is isolated here so
real SMS/WhatsApp providers can be swapped in without touching views.
"""

import logging

from django.utils import timezone

from .models import AuditLog, OTPVerification, User

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# OTP Service
# ---------------------------------------------------------------------------

class OTPService:
    """
    Generates and dispatches OTPs.
    Currently uses a mock transport; replace `_send_sms` with your
    Arkesel / Hubtel client in production.
    """

    @staticmethod
    def send_otp(user: User, purpose: str = OTPVerification.Purpose.PHONE_REGISTRATION) -> OTPVerification:
        otp = OTPVerification.generate_for(user, purpose)
        OTPService._dispatch(user, otp.code, purpose)
        return otp

    @staticmethod
    def _dispatch(user: User, code: str, purpose: str) -> None:
        """
        MOCK implementation — logs to console.
        Replace with real SMS gateway (Arkesel / Hubtel) in production.

        Production swap-in:
            import arkesel
            arkesel.send_sms(to=user.phone_number, message=f"Your MedQueue OTP: {code}")
        """
        phone = user.phone_number or "(no phone)"
        logger.info(
            "[OTP MOCK] Sending %s OTP to %s: %s  (expires in 5 min)",
            purpose,
            phone,
            code,
        )
        # In development, also print to stdout for easy retrieval
        print(f"\n{'='*50}")
        print(f"  OTP CODE  ->  {code}")
        print(f"  Phone     ->  {phone}")
        print(f"  Purpose   ->  {purpose}")
        print(f"{'='*50}\n")

    @staticmethod
    def verify(phone_number: str, code: str, purpose: str) -> tuple[bool, str, User | None]:
        """
        Returns (success: bool, message: str, user: User | None)
        Preferred over direct serializer validation when called from
        non-HTTP contexts (e.g. management commands, tests).
        """
        try:
            user = User.objects.get(phone_number=phone_number)
        except User.DoesNotExist:
            return False, "No account with this phone number.", None

        otp = (
            OTPVerification.objects
            .filter(user=user, code=code, purpose=purpose, is_used=False)
            .order_by("-created_at")
            .first()
        )
        if otp is None:
            return False, "Invalid OTP code.", None
        if not otp.is_valid:
            return False, "OTP has expired.", None

        otp.consume()
        return True, "OTP verified successfully.", user


# ---------------------------------------------------------------------------
# Audit Service
# ---------------------------------------------------------------------------

class AuditService:
    """
    Thin wrapper around AuditLog.objects.create.
    Centralises IP / user-agent extraction from requests.
    """

    @staticmethod
    def log(
        event_type: str,
        user: User | None = None,
        description: str = "",
        request=None,
        metadata: dict | None = None,
    ) -> AuditLog:
        ip         = None
        user_agent = ""

        if request is not None:
            ip         = AuditService._get_client_ip(request)
            user_agent = request.META.get("HTTP_USER_AGENT", "")[:256]

        return AuditLog.objects.create(
            user        = user,
            event_type  = event_type,
            description = description,
            ip_address  = ip,
            user_agent  = user_agent,
            metadata    = metadata or {},
        )

    @staticmethod
    def _get_client_ip(request) -> str | None:
        """
        Handles X-Forwarded-For header set by Nginx / load balancers.
        Takes the first (leftmost) IP which is the original client.
        """
        x_forwarded = request.META.get("HTTP_X_FORWARDED_FOR")
        if x_forwarded:
            return x_forwarded.split(",")[0].strip()
        return request.META.get("REMOTE_ADDR")


# ---------------------------------------------------------------------------
# Account Lockout Notification
# ---------------------------------------------------------------------------

def notify_lockout(user: User) -> None:
    """
    Inform the user their account has been locked.
    Mock implementation — wire up to FCM / SMS in production.
    """
    logger.warning(
        "[LOCKOUT] Account locked for user %s until %s",
        user.username,
        user.lockout_until,
    )
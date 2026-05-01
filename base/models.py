"""
accounts/models.py

Custom User model for MedQueue GH.
Extends AbstractUser to preserve Django's built-in auth machinery
(permissions, admin integration, password hashing) while adding:
  - Role-based access (Patient / Doctor / Admin)
  - Phone number + OTP verification
  - Account lockout after 3 failed login attempts
  - Extended profiles per role (PatientProfile, DoctorProfile)
"""

import random
import string
from datetime import timedelta

from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone
from django.utils.translation import gettext_lazy as _


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

class UserRole(models.TextChoices):
    PATIENT = "patient", _("Patient")
    DOCTOR  = "doctor",  _("Doctor")
    ADMIN   = "admin",   _("Admin")


class Gender(models.TextChoices):
    MALE        = "male",        _("Male")
    FEMALE      = "female",      _("Female")
    OTHER       = "other",       _("Other")
    UNSPECIFIED = "unspecified", _("Prefer not to say")


MAX_FAILED_ATTEMPTS = 3
LOCKOUT_DURATION_MINUTES = 15
OTP_EXPIRY_MINUTES = 5          # SRS specifies 30 s for registration OTP;
                                 # we use 5 min for usability on slow networks


# ---------------------------------------------------------------------------
# User
# ---------------------------------------------------------------------------

class User(AbstractUser):
    """
    Central auth model.  Username is kept for Django admin compatibility
    but phone_number is the primary login credential alongside email.
    """

    # --- Identity ---
    role          = models.CharField(
        max_length=10,
        choices=UserRole.choices,
        default=UserRole.PATIENT,
        db_index=True,
    )
    phone_number  = models.CharField(
        max_length=20,
        unique=True,
        null=True,
        blank=True,
        help_text=_("E.164 format recommended, e.g. +233201234567"),
    )
    date_of_birth = models.DateField(null=True, blank=True)
    gender        = models.CharField(
        max_length=15,
        choices=Gender.choices,
        default=Gender.UNSPECIFIED,
    )
    address       = models.TextField(blank=True, default="")
    profile_picture_url = models.URLField(
        blank=True,
        default="",
        help_text=_("Firebase Storage URL"),
    )

    # --- Verification ---
    is_phone_verified = models.BooleanField(default=False)
    is_email_verified = models.BooleanField(default=False)

    # WhatsApp opt-in
    whatsapp_number = models.CharField(max_length=20, blank=True, default="")
    whatsapp_linked  = models.BooleanField(default=False)

    # --- Account Lockout ---
    failed_login_attempts = models.PositiveSmallIntegerField(default=0)
    lockout_until         = models.DateTimeField(null=True, blank=True)

    # Notification preferences (bitmask stored as individual booleans for
    # clarity and queryability)
    notif_push      = models.BooleanField(default=True)
    notif_sms       = models.BooleanField(default=True)
    notif_whatsapp  = models.BooleanField(default=False)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD  = "username"
    REQUIRED_FIELDS = ["email"]

    class Meta:
        verbose_name        = _("User")
        verbose_name_plural = _("Users")
        ordering            = ["-created_at"]

    # ------------------------------------------------------------------
    # Lockout helpers
    # ------------------------------------------------------------------

    @property
    def is_locked_out(self) -> bool:
        """Returns True if the account is currently locked."""
        if self.lockout_until and timezone.now() < self.lockout_until:
            return True
        return False

    def record_failed_login(self) -> None:
        """Increment failure counter; lock account after MAX_FAILED_ATTEMPTS."""
        self.failed_login_attempts += 1
        if self.failed_login_attempts >= MAX_FAILED_ATTEMPTS:
            self.lockout_until = timezone.now() + timedelta(
                minutes=LOCKOUT_DURATION_MINUTES
            )
        self.save(update_fields=["failed_login_attempts", "lockout_until"])

    def reset_login_attempts(self) -> None:
        """Clear failure counter on successful authentication."""
        if self.failed_login_attempts != 0 or self.lockout_until is not None:
            self.failed_login_attempts = 0
            self.lockout_until = None
            self.save(update_fields=["failed_login_attempts", "lockout_until"])

    # ------------------------------------------------------------------
    # Role helpers
    # ------------------------------------------------------------------

    @property
    def is_patient(self) -> bool:
        return self.role == UserRole.PATIENT

    @property
    def is_doctor(self) -> bool:
        return self.role == UserRole.DOCTOR

    @property
    def is_admin_user(self) -> bool:
        return self.role == UserRole.ADMIN

    def __str__(self) -> str:
        return f"{self.get_full_name() or self.username} [{self.role}]"


# ---------------------------------------------------------------------------
# OTP
# ---------------------------------------------------------------------------

class OTPVerification(models.Model):
    """
    Short-lived OTP record.  One active OTP per user per purpose.
    The `purpose` field allows reuse for registration, password reset, etc.
    """

    class Purpose(models.TextChoices):
        PHONE_REGISTRATION = "phone_reg",    _("Phone Registration")
        PASSWORD_RESET     = "password_reset", _("Password Reset")
        LOGIN_2FA          = "login_2fa",    _("Login 2FA")

    user       = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="otp_records",
    )
    code       = models.CharField(max_length=6)
    purpose    = models.CharField(
        max_length=20,
        choices=Purpose.choices,
        default=Purpose.PHONE_REGISTRATION,
    )
    is_used    = models.BooleanField(default=False)
    expires_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name        = _("OTP Verification")
        verbose_name_plural = _("OTP Verifications")
        ordering            = ["-created_at"]
        indexes             = [
            models.Index(fields=["user", "purpose", "is_used"]),
        ]

    # ------------------------------------------------------------------
    # Factory / helpers
    # ------------------------------------------------------------------

    @classmethod
    def generate_for(
        cls,
        user: User,
        purpose: str = Purpose.PHONE_REGISTRATION,
    ) -> "OTPVerification":
        """
        Invalidate any existing active OTPs for this user+purpose,
        then create a fresh one.
        """
        cls.objects.filter(
            user=user,
            purpose=purpose,
            is_used=False,
        ).update(is_used=True)           # soft-invalidate old codes

        code = "".join(random.choices(string.digits, k=6))
        return cls.objects.create(
            user=user,
            code=code,
            purpose=purpose,
            expires_at=timezone.now() + timedelta(minutes=OTP_EXPIRY_MINUTES),
        )

    @property
    def is_valid(self) -> bool:
        return not self.is_used and timezone.now() <= self.expires_at

    def consume(self) -> bool:
        """Mark as used. Returns False if already used or expired."""
        if not self.is_valid:
            return False
        self.is_used = True
        self.save(update_fields=["is_used"])
        return True

    def __str__(self) -> str:
        return f"OTP({self.purpose}) for {self.user.username} — {'valid' if self.is_valid else 'expired/used'}"


# ---------------------------------------------------------------------------
# Role-specific profiles  (1-to-1 with User)
# ---------------------------------------------------------------------------

class PatientProfile(models.Model):
    """Extended data for patients only."""

    user              = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="patient_profile",
        limit_choices_to={"role": UserRole.PATIENT},
    )
    blood_group       = models.CharField(max_length=5, blank=True, default="")
    allergies         = models.TextField(
        blank=True,
        default="",
        help_text=_("Comma-separated list of known allergies"),
    )
    emergency_contact_name  = models.CharField(max_length=100, blank=True, default="")
    emergency_contact_phone = models.CharField(max_length=20,  blank=True, default="")
    medical_history         = models.TextField(blank=True, default="")

    class Meta:
        verbose_name = _("Patient Profile")

    def __str__(self) -> str:
        return f"PatientProfile — {self.user}"


class DoctorProfile(models.Model):
    """Extended data for doctors only."""

    user                  = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="doctor_profile",
        limit_choices_to={"role": UserRole.DOCTOR},
    )
    specialization        = models.CharField(max_length=100, blank=True, default="")
    medical_license_number= models.CharField(max_length=50,  blank=True, default="")
    hospital_name         = models.CharField(max_length=150, blank=True, default="")
    consultation_fee      = models.DecimalField(
        max_digits=10, decimal_places=2, default=0.00,
        help_text=_("Fee in GHS"),
    )
    years_of_experience   = models.PositiveSmallIntegerField(default=0)
    is_accepting_patients = models.BooleanField(default=True)
    bio                   = models.TextField(blank=True, default="")

    # Average consultation duration used by the queue wait-time algorithm
    avg_consultation_minutes = models.PositiveSmallIntegerField(
        default=15,
        help_text=_("Used to compute estimated wait times"),
    )

    class Meta:
        verbose_name = _("Doctor Profile")

    def __str__(self) -> str:
        return f"DoctorProfile — {self.user} ({self.specialization})"


# ---------------------------------------------------------------------------
# Audit Log  (used by multiple modules; defined here as a core model)
# ---------------------------------------------------------------------------

class AuditLog(models.Model):
    """Immutable event log for security and compliance (FR-7.7)."""

    class EventType(models.TextChoices):
        LOGIN           = "login",           _("Login")
        LOGOUT          = "logout",          _("Logout")
        FAILED_LOGIN    = "failed_login",    _("Failed Login")
        LOCKOUT         = "lockout",         _("Account Lockout")
        REGISTER        = "register",        _("Registration")
        PASSWORD_RESET  = "password_reset",  _("Password Reset")
        ROLE_CHANGE     = "role_change",     _("Role Change")
        PROFILE_UPDATE  = "profile_update",  _("Profile Update")
        BOOKING         = "booking",         _("Appointment Booked")
        CANCELLATION    = "cancellation",    _("Appointment Cancelled")
        EMERGENCY       = "emergency",       _("Emergency SOS")

    user       = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="audit_logs",
    )
    event_type = models.CharField(max_length=30, choices=EventType.choices, db_index=True)
    description= models.TextField(blank=True, default="")
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.CharField(max_length=256, blank=True, default="")
    metadata   = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        verbose_name        = _("Audit Log")
        verbose_name_plural = _("Audit Logs")
        ordering            = ["-created_at"]
        # Audit logs are never updated, only inserted
        default_permissions = ("view",)

    def __str__(self) -> str:
        return f"[{self.event_type}] {self.user} at {self.created_at:%Y-%m-%d %H:%M:%S}"
"""
accounts/admin.py
"""

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _

from .models import AuditLog, DoctorProfile, OTPVerification, PatientProfile, User


class PatientProfileInline(admin.StackedInline):
    model     = PatientProfile
    extra     = 0
    can_delete= False


class DoctorProfileInline(admin.StackedInline):
    model     = DoctorProfile
    extra     = 0
    can_delete= False


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display  = ("username", "email", "role", "phone_number",
                     "is_phone_verified", "is_active", "failed_login_attempts")
    list_filter   = ("role", "is_active", "is_phone_verified", "gender")
    search_fields = ("username", "email", "phone_number", "first_name", "last_name")
    ordering      = ("-created_at",)
    inlines       = [PatientProfileInline, DoctorProfileInline]

    fieldsets = BaseUserAdmin.fieldsets + (
        (_("MedQueue GH"), {
            "fields": (
                "role", "phone_number", "date_of_birth", "gender", "address",
                "profile_picture_url", "is_phone_verified", "is_email_verified",
                "whatsapp_number", "whatsapp_linked",
                "failed_login_attempts", "lockout_until",
                "notif_push", "notif_sms", "notif_whatsapp",
            )
        }),
    )


@admin.register(OTPVerification)
class OTPVerificationAdmin(admin.ModelAdmin):
    list_display  = ("user", "purpose", "code", "is_used", "expires_at", "created_at")
    list_filter   = ("purpose", "is_used")
    search_fields = ("user__username", "user__phone_number")
    readonly_fields = ("created_at",)


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display  = ("event_type", "user", "ip_address", "created_at")
    list_filter   = ("event_type",)
    search_fields = ("user__username", "ip_address", "description")
    readonly_fields = ("user", "event_type", "description", "ip_address",
                       "user_agent", "metadata", "created_at")

    def has_add_permission(self, request):
        return False      # audit logs are system-generated only

    def has_change_permission(self, request, obj=None):
        return False
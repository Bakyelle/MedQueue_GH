"""
accounts/urls.py

All URL patterns for the accounts / authentication module.
Include in the project root urls.py as:
    path("api/v1/auth/", include("apps.accounts.urls")),
"""

from django.urls import path

from .views import (
    AdminUserDetailView,
    AdminUserListView,
    LoginView,
    LogoutView,
    PasswordResetConfirmView,
    PasswordResetRequestView,
    ProfileView,
    RegisterView,
    SendOTPView,
    TokenRefreshEnvelopeView,
    VerifyOTPView,
)

app_name = "accounts"

urlpatterns = [
    # ------------------------------------------------------------------ #
    # Registration                                                         #
    # ------------------------------------------------------------------ #
    path(
        "register/",
        RegisterView.as_view(),
        name="register",
    ),

    # ------------------------------------------------------------------ #
    # OTP                                                                  #
    # ------------------------------------------------------------------ #
    path(
        "otp/send/",
        SendOTPView.as_view(),
        name="otp-send",
    ),
    path(
        "otp/verify/",
        VerifyOTPView.as_view(),
        name="otp-verify",
    ),

    # ------------------------------------------------------------------ #
    # Login / Logout                                                       #
    # ------------------------------------------------------------------ #
    path(
        "login/",
        LoginView.as_view(),
        name="login",
    ),
    path(
        "logout/",
        LogoutView.as_view(),
        name="logout",
    ),

    # ------------------------------------------------------------------ #
    # JWT Token Management                                                 #
    # ------------------------------------------------------------------ #
    path(
        "token/refresh/",
        TokenRefreshEnvelopeView.as_view(),
        name="token-refresh",
    ),

    # ------------------------------------------------------------------ #
    # Password Reset                                                       #
    # ------------------------------------------------------------------ #
    path(
        "password/reset/request/",
        PasswordResetRequestView.as_view(),
        name="password-reset-request",
    ),
    path(
        "password/reset/confirm/",
        PasswordResetConfirmView.as_view(),
        name="password-reset-confirm",
    ),

    # ------------------------------------------------------------------ #
    # Own Profile (any authenticated user)                                 #
    # ------------------------------------------------------------------ #
    path(
        "profile/",
        ProfileView.as_view(),
        name="profile",
    ),

    # ------------------------------------------------------------------ #
    # Admin: User Management                                               #
    # ------------------------------------------------------------------ #
    path(
        "users/",
        AdminUserListView.as_view(),
        name="admin-user-list",
    ),
    path(
        "users/<int:pk>/",
        AdminUserDetailView.as_view(),
        name="admin-user-detail",
    ),
]
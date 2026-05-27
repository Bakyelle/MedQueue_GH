"""
config/settings/base.py  (auth-relevant sections)

Copy these blocks into your Django settings file.
Full settings file for MedQueue GH — auth + JWT configuration.
"""

from datetime import timedelta
from pathlib import Path
import os

BASE_DIR = Path(__file__).resolve().parent.parent.parent

SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY", "change-me-in-production")

DEBUG = os.environ.get("DEBUG", "True") == "True"

ALLOWED_HOSTS = os.environ.get("ALLOWED_HOSTS", "localhost 127.0.0.1").split()

# -----------------------------------------------------------------------
# Application definition
# -----------------------------------------------------------------------

DJANGO_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
]

THIRD_PARTY_APPS = [
    "rest_framework",
    "rest_framework_simplejwt",
    "rest_framework_simplejwt.token_blacklist",  # required for logout blacklisting
    "corsheaders",
    "django_filters",
]

LOCAL_APPS = [
    "base",
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

# -----------------------------------------------------------------------
# Custom User Model  — MUST be set before first migration
# -----------------------------------------------------------------------
AUTH_USER_MODEL = "base.User"

# -----------------------------------------------------------------------
# Database
# -----------------------------------------------------------------------

if os.environ.get("DB_ENGINE", "sqlite").lower() in ("postgres", "postgresql"):
    DATABASES = {
        "default": {
            "ENGINE":   "django.db.backends.postgresql",
            "NAME":     os.environ.get("DB_NAME",     "medqueue_db"),
            "USER":     os.environ.get("DB_USER",     "medqueue_user"),
            "PASSWORD": os.environ.get("DB_PASSWORD", ""),
            "HOST":     os.environ.get("DB_HOST",     "localhost"),
            "PORT":     os.environ.get("DB_PORT",     "5432"),
            "OPTIONS":  {
                "connect_timeout": 10,
            },
        }
    }
else:
    # Default to a local SQLite DB for easy development
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": str(BASE_DIR / "db.sqlite3"),
        }
    }

# -----------------------------------------------------------------------
# REST Framework
# -----------------------------------------------------------------------

REST_FRAMEWORK = {
    # Default authentication: JWT only (no session cookies for the API)
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ],
    # Default permission: must be authenticated
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated",
    ],
    # Throttling — prevents brute-force on OTP / login endpoints
    "DEFAULT_THROTTLE_CLASSES": [
        "rest_framework.throttling.AnonRateThrottle",
        "rest_framework.throttling.UserRateThrottle",
    ],
    "DEFAULT_THROTTLE_RATES": {
        "anon":         "100/day",
        "user":         "1000/day",
        "login":        "10/minute",    # LoginView
        "registration": "5/hour",       # RegisterView
        "otp":          "5/hour",       # SendOTPView
    },
    "DEFAULT_RENDERER_CLASSES": [
        "rest_framework.renderers.JSONRenderer",
    ],
    "DEFAULT_PARSER_CLASSES": [
        "rest_framework.parsers.JSONParser",
        "rest_framework.parsers.MultiPartParser",
    ],
    "DEFAULT_PAGINATION_CLASS":  "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
    "EXCEPTION_HANDLER": "base.exceptions.custom_exception_handler",
}

# -----------------------------------------------------------------------
# Simple JWT
# -----------------------------------------------------------------------

SIMPLE_JWT = {
    # Access token valid for 24 hours (SRS FR-1.3)
    "ACCESS_TOKEN_LIFETIME":        timedelta(hours=24),
    # Refresh token valid for 30 days
    "REFRESH_TOKEN_LIFETIME":       timedelta(days=30),
    "ROTATE_REFRESH_TOKENS":        True,    # issue new refresh on each use
    "BLACKLIST_AFTER_ROTATION":     True,    # old refresh token → blacklist
    "UPDATE_LAST_LOGIN":            True,    # update User.last_login on token issue
    "ALGORITHM":                    "HS256",
    "SIGNING_KEY":                  SECRET_KEY,
    "AUTH_HEADER_TYPES":            ("Bearer",),
    "AUTH_HEADER_NAME":             "HTTP_AUTHORIZATION",
    "USER_ID_FIELD":                "id",
    "USER_ID_CLAIM":                "user_id",
    # Custom claim injection (role, full_name) is done in serializers._get_tokens()
    "TOKEN_OBTAIN_PAIR_SERIALIZER": "rest_framework_simplejwt.serializers.TokenObtainPairSerializer",
    "TOKEN_REFRESH_SERIALIZER":     "rest_framework_simplejwt.serializers.TokenRefreshSerializer",
    "TOKEN_BLACKLIST_ENABLED":      True,
}

# -----------------------------------------------------------------------
# Password Validation
# -----------------------------------------------------------------------

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {
        "NAME":    "django.contrib.auth.password_validation.MinimumLengthValidator",
        "OPTIONS": {"min_length": 8},
    },
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

# -----------------------------------------------------------------------
# CORS  (Flutter app will be on a different origin)
# -----------------------------------------------------------------------

if DEBUG:
    CORS_ALLOW_ALL_ORIGINS = True      # Flutter web dev server uses random ports
else:
    CORS_ALLOWED_ORIGINS = os.environ.get(
        "CORS_ALLOWED_ORIGINS",
        "http://localhost:3000 http://127.0.0.1:3000",
    ).split()
CORS_ALLOW_CREDENTIALS = True

# -----------------------------------------------------------------------
# Middleware
# -----------------------------------------------------------------------

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "corsheaders.middleware.CorsMiddleware",        # must be before CommonMiddleware
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

# Minimal templates config required by Django admin
TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

# -----------------------------------------------------------------------
# Security
# -----------------------------------------------------------------------

SECURE_SSL_REDIRECT          = not DEBUG
SESSION_COOKIE_SECURE        = not DEBUG
CSRF_COOKIE_SECURE           = not DEBUG
SECURE_HSTS_SECONDS          = 31536000  # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD          = True
SECURE_CONTENT_TYPE_NOSNIFF  = True

# -----------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------

LOGGING = {
    "version":                  1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": "[{asctime}] {levelname} {name}: {message}",
            "style":  "{",
        },
    },
    "handlers": {
        "console": {
            "class":     "logging.StreamHandler",
            "formatter": "verbose",
        },
    },
    "loggers": {
        "base.accounts": {
            "handlers":  ["console"],
            "level":     "DEBUG" if DEBUG else "INFO",
            "propagate": False,
        },
        "django.security": {
            "handlers":  ["console"],
            "level":     "WARNING",
            "propagate": False,
        },
    },
}

# Root URL configuration and WSGI entrypoint for the project
ROOT_URLCONF = "medqueue_backend.urls"
WSGI_APPLICATION = "medqueue_backend.wsgi.application"

# Static files (development)
STATIC_URL = "/static/"

# Default primary key field type
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
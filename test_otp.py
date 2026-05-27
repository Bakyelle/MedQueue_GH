import os
import django
import traceback

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medqueue_backend.settings')
django.setup()

from base.models import User, OTPVerification
from base.services import OTPService

try:
    user = User.objects.get(username='drkwame2')
    print(f"User found: {user.username}, Phone: {user.phone_number}")
    otp = OTPService.send_otp(user, OTPVerification.Purpose.PHONE_REGISTRATION)
    print(f"OTP sent: {otp.code}")
except Exception:
    print(traceback.format_exc())

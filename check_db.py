import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medqueue_backend.settings')
django.setup()

from base.models import User, AuditLog, DoctorProfile
try:
    users = User.objects.all()
    print(f"Total Users: {users.count()}")
    for u in users:
        has_prof = hasattr(u, 'doctor_profile')
        print(f"User: {u.username}, Role: {u.role}, Has Doctor Profile: {has_prof}")
    
    logs = AuditLog.objects.all()
    print(f"Total Audit Logs: {logs.count()}")
    for l in logs:
        print(f"Log: {l.event_type}, User: {l.user.username if l.user else 'None'}, Desc: {l.description}")
except Exception as e:
    print(f"Error: {e}")

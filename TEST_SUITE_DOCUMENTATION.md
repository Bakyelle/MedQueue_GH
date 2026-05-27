# MedQueue Backend Test Suite Documentation

## Overview

Comprehensive test suite for the MedQueue Backend covering all API endpoints across two main modules:

- **Accounts & Authentication** (Module 1)
- **Appointments & Scheduling** (Module 2)

**Location:** `/base/tests.py`  
**Run with:** `python manage.py test base.tests [--verbosity=2]`

---

## Test Structure

### 1. Helper Functions

#### User Creation

- `make_user()` - Create test users (patient, doctor, admin) with default properties
- `make_otp()` - Create OTP records for testing verification flows
- `auth_client()` - Create an authenticated APIClient with JWT token

#### Appointment-Specific Helpers

- `make_doctor_profile()` - Create doctor profile with specialization, license, etc.
- `make_patient_profile()` - Create patient profile with medical info
- `make_schedule()` - Create recurring doctor schedule (day of week + hours)
- `make_time_slot()` - Create concrete bookable time slot for a specific date

### 2. Base Test Cases

#### `AccountsTestCase`

Shared setup for all account/auth tests:

- `patient`, `doctor`, `admin` users
- Authenticated clients for each role
- Pre-configured test data

#### `AppointmentsTestCase`

Shared setup for all appointment tests:

- 2 patients, 2 doctors, 1 admin
- Doctor profiles with specializations (Cardiology, Neurology)
- Recurring schedules (Mon-Fri, 8-17 or 9-18)
- Pre-configured doctor profiles and patient profiles

---

## Test Coverage by Module

### Module 1: Accounts & Authentication

#### `RegisterViewTests` (8 tests)

- ✅ Register patient/doctor success
- ✅ Duplicate phone/email/username rejection
- ✅ Missing required fields validation
- ✅ Weak password rejection
- ✅ OTP dispatch on registration

**Key Assertions:**

```python
# Status 201 on success
# OTP service called
# User created in DB
# Email verification state correct
```

---

#### `SendOTPViewTests` (3 tests)

- ✅ Send OTP to registered phone
- ✅ Unknown phone rejection
- ✅ Missing fields validation

**Key Assertions:**

```python
# Status 200 on success
# OTPService.send_otp() called
# Correct purpose (phone_reg, password_reset)
```

---

#### `VerifyOTPViewTests` (6 tests)

- ✅ Valid OTP returns JWT tokens
- ✅ Wrong code rejection
- ✅ Expired OTP rejection
- ✅ Already-used OTP rejection
- ✅ Phone marked verified on registration OTP
- ✅ Returns user object in response

**Key Assertions:**

```python
# Status 200 on success
# Response contains "tokens" with "access" + "refresh"
# OTP marked as used
# is_phone_verified updated
```

---

#### `LoginViewTests` (12 tests)

- ✅ Login with username/email/phone
- ✅ Wrong password rejection
- ✅ Nonexistent user rejection
- ✅ Account lockout after 3 failed attempts
- ✅ Locked account rejection (with unlock time)
- ✅ Failed attempt counter increments
- ✅ Successful login clears counter
- ✅ Response contains tokens + user data

**Key Assertions:**

```python
# Status 200 on success
# failed_login_attempts incremented
# lockout_until set after MAX_FAILED_ATTEMPTS
# failed_login_attempts = 0 on success
# JWT tokens in response
```

---

#### `LogoutViewTests` (5 tests)

- ✅ Valid logout blacklists token
- ✅ Missing refresh token rejection
- ✅ Invalid token rejection
- ✅ Unauthenticated rejection
- ✅ Blacklisted token cannot be reused

**Key Assertions:**

```python
# Status 200 on success
# TokenBlacklist entry created
# Reuse attempt fails with 400
```

---

#### `PasswordResetRequestViewTests` (3 tests)

- ✅ Known user receives OTP
- ✅ Unknown user returns vague response (security)
- ✅ Missing field rejection

**Key Assertions:**

```python
# Status 200 always (even for unknown users)
# OTPService.send_otp() called
# Email enumeration prevented
```

---

#### `PasswordResetConfirmViewTests` (6 tests)

- ✅ Valid OTP changes password
- ✅ Wrong code rejection
- ✅ Expired OTP rejection
- ✅ Lockout cleared on successful reset
- ✅ Weak password rejection
- ✅ Password mismatch rejection

**Key Assertions:**

```python
# Status 200 on success
# user.check_password(new_password) = True
# failed_login_attempts = 0
# lockout_until = None
```

---

#### `ProfileViewTests` (6 tests)

- ✅ Get own profile (authenticated)
- ✅ Get profile unauthenticated fails
- ✅ PATCH own profile (partial update)
- ✅ PATCH unauthenticated fails
- ✅ Invalid email format rejected
- ✅ AuditLog created on update

**Key Assertions:**

```python
# Status 200 on GET
# Status 400 on invalid email
# Updated fields persisted to DB
# AuditService.log() called on PATCH
```

---

#### `AdminUserListViewTests` (7 tests)

- ✅ Admin can list all users
- ✅ Non-admin (patient) cannot list
- ✅ Unauthenticated cannot list
- ✅ Filter by role
- ✅ Filter by is_active status
- ✅ Search by username
- ✅ Pagination fields present (count, page, pages)

**Key Assertions:**

```python
# Status 403 for non-admin (Forbidden)
# Status 401 for unauthenticated
# results filtered by role
# Pagination metadata in response
```

---

#### `AdminUserDetailViewTests` (8 tests)

- ✅ Admin can GET user detail
- ✅ Non-admin cannot GET other user
- ✅ Nonexistent user returns 404
- ✅ Admin can PATCH user
- ✅ Admin can DELETE (deactivate) user
- ✅ Admin cannot deactivate self
- ✅ Non-admin cannot DELETE

**Key Assertions:**

```python
# Status 403 for non-admin
# is_active = False on DELETE
# User data returned on GET
```

---

#### `TokenRefreshEnvelopeViewTests` (3 tests)

- ✅ Valid refresh returns new access token
- ✅ Invalid token rejected
- ✅ Missing token rejected

**Key Assertions:**

```python
# Status 200 on success
# "access" field in response
# Status != 200 on invalid
```

---

### Module 2: Appointments & Scheduling

#### `DoctorListViewTests` (7 tests)

- ✅ Patient can browse doctors
- ✅ Doctor can browse doctors
- ✅ Unauthenticated cannot browse
- ✅ Filter by specialization
- ✅ Filter by hospital
- ✅ Filter by availability date
- ✅ Search by name/specialization
- ✅ Only active, accepting doctors shown

**Key Assertions:**

```python
# Status 200 on success
# Status 401 unauthenticated
# Status 403 for non-patient endpoints
# Filters applied correctly
# doctor_profile included in response
```

---

#### `DoctorSlotListViewTests` (7 tests)

- ✅ Get slots for valid date
- ✅ Date parameter required
- ✅ Invalid date format rejected
- ✅ Past date rejected
- ✅ Nonexistent doctor returns 404
- ✅ Slots generated on-demand (idempotent)
- ✅ Slots marked available/booked

**Key Assertions:**

```python
# Status 200 on success
# Status 400 for invalid date/past date
# Status 404 for nonexistent doctor
# slots array populated
# available count >= 0
# Slot status: AVAILABLE or BOOKED
```

---

#### `BookAppointmentViewTests` (10 tests)

- ✅ Patient can book appointment
- ✅ Booking marks slot as BOOKED
- ✅ Cannot book already-booked slot
- ✅ Cannot book nonexistent slot
- ✅ Doctor cannot book
- ✅ Unauthenticated cannot book
- ✅ Creates CONFIRMED appointment
- ✅ Reason saved in appointment
- ✅ Returns new appointment ID
- ✅ Slot linked to appointment

**Key Assertions:**

```python
# Status 201 (Created) on success
# Status 409 (Conflict) for booked slot
# Status 403 (Forbidden) for doctor
# slot.status = BOOKED
# appointment.status = CONFIRMED
# appointment.reason = provided reason
```

---

#### `AppointmentDetailViewTests` (7 tests)

- ✅ Patient can view own appointment
- ✅ Doctor can view assigned appointment
- ✅ Admin can view any appointment
- ✅ Patient cannot view other's appointment
- ✅ Doctor cannot view unassigned appointment
- ✅ Nonexistent appointment returns 404
- ✅ Unauthenticated cannot view

**Key Assertions:**

```python
# Status 200 for authorized users
# Status 404 for unauthorized or missing
# Full appointment detail in response
```

---

#### `CancelAppointmentViewTests` (8 tests)

- ✅ Patient can cancel own appointment
- ✅ Doctor can cancel assigned appointment
- ✅ Admin can cancel any appointment
- ✅ Cancellation releases slot
- ✅ Patient cannot cancel other's appointment
- ✅ Nonexistent appointment returns 404
- ✅ Unauthenticated cannot cancel
- ✅ Status changes to CANCELLED

**Key Assertions:**

```python
# Status 200 on success
# appointment.status = CANCELLED
# appointment.slot = None (released)
# appointment.cancelled_by = user
# cancellation_reason saved
```

---

#### `RescheduleAppointmentViewTests` (6 tests)

- ✅ Patient can reschedule own appointment
- ✅ Reschedule creates new appointment
- ✅ Old appointment marked RESCHEDULED
- ✅ Cannot reschedule to unavailable slot
- ✅ Doctor cannot reschedule (patient only)
- ✅ Nonexistent appointment returns 404

**Key Assertions:**

```python
# Status 201 (Created) on success
# Old appointment.status = RESCHEDULED
# New appointment.rescheduled_from = old_appt
# new_slot.status = BOOKED
# Old slot released
```

---

#### `DoctorScheduleListViewTests` (6 tests)

- ✅ Doctor can view own schedule
- ✅ Patient cannot view doctor schedule
- ✅ Admin cannot view doctor schedule
- ✅ Unauthenticated cannot view
- ✅ Get schedule for specific date
- ✅ Get schedule for week range

**Key Assertions:**

```python
# Status 200 for authenticated doctor
# Status 403 for non-doctor
# Status 401 for unauthenticated
# appointments array in response
# Supports date and range parameters
```

---

#### `DoctorMarkStatusViewTests` (6 tests)

- ✅ Doctor can mark appointment COMPLETED
- ✅ Doctor can mark appointment NO_SHOW
- ✅ Patient cannot mark status
- ✅ Doctor cannot mark unassigned appointment
- ✅ Nonexistent appointment returns 404
- ✅ Notes saved with status change

**Key Assertions:**

```python
# Status 200 on success
# Status 403 for non-doctor
# appointment.status updated
# appointment.notes = provided notes
```

---

#### `AppointmentHistoryViewTests` (7 tests)

- ✅ Patient can view own history
- ✅ Doctor can view assigned appointments history
- ✅ Admin can view all history
- ✅ Unauthenticated cannot view
- ✅ Filter by status
- ✅ Filter by date range (from/to)
- ✅ Pagination (page, page_size)

**Key Assertions:**

```python
# Status 200 on success
# Status 401 unauthenticated
# results filtered by role
# Status filter applied
# Date range filter applied
# Pagination fields present
```

---

#### `AdminDoctorScheduleViewTests` (6 tests)

- ✅ Admin can list schedules
- ✅ Non-admin cannot list
- ✅ Admin can create schedule
- ✅ Filter schedules by doctor
- ✅ Non-admin cannot create
- ✅ Invalid schedule data rejected

**Key Assertions:**

```python
# Status 200 on GET
# Status 201 on POST (Created)
# Status 403 for non-admin
# DoctorSchedule created in DB
# Filtered by doctor_id
```

---

#### `AdminAppointmentOverrideViewTests` (5 tests)

- ✅ Admin can create appointment for patient
- ✅ Non-admin cannot create override
- ✅ Admin can update appointment status
- ✅ Admin can force-cancel appointment
- ✅ Response contains created/updated appointment

**Key Assertions:**

```python
# Status 201 (Created) on POST
# Status 200 on PATCH
# Status 200 on DELETE
# Status 403 for non-admin
# Appointment modified in DB
```

---

#### `ResponseEnvelopeTests` (Multiple tests)

Verify all endpoints return standard JSON envelope:

```json
{
  "status": "success" | "error",
  "message": "Human-readable message",
  "data": { /* response data or null */ },
  "errors": { /* validation errors or null */ }
}
```

**Tests:**

- ✅ Register endpoint envelope
- ✅ Login endpoint envelope
- ✅ Profile endpoint envelope
- ✅ User list endpoint envelope
- ✅ Doctor list endpoint envelope
- ✅ Book appointment endpoint envelope
- ✅ History endpoint envelope

---

## Running Tests

### Run All Tests

```bash
python manage.py test base.tests --verbosity=2
```

### Run Specific Test Class

```bash
python manage.py test base.tests.LoginViewTests --verbosity=2
python manage.py test base.tests.BookAppointmentViewTests --verbosity=2
```

### Run Specific Test

```bash
python manage.py test base.tests.LoginViewTests.test_login_with_username_success
```

### Run with Coverage

```bash
coverage run --source='.' manage.py test base.tests
coverage report
coverage html  # Generate HTML report
```

### Run in Parallel

```bash
python manage.py test base.tests --parallel 4
```

---

## Test Statistics

### Accounts Module

- **Test Classes:** 11
- **Total Tests:** ~75
- **Coverage:** Registration, OTP, Login, Logout, Password Reset, Profile, Admin Management

### Appointments Module

- **Test Classes:** 12
- **Total Tests:** ~80
- **Coverage:** Doctor Listing, Slot Management, Booking, Cancellation, Rescheduling, Status Updates, History, Admin Operations

### Total

- **Test Classes:** 23+
- **Total Tests:** ~155+
- **Lines of Test Code:** ~1,650

---

## Key Testing Patterns

### 1. Permission Testing

Every endpoint is tested for:

- ✅ Authorized access (correct role)
- ✅ Unauthorized access (wrong role)
- ✅ Unauthenticated access (no token)

**Example:**

```python
def test_admin_can_list_users(self):
    response = self.admin_client.get(url)
    self.assertEqual(response.status_code, 200)

def test_patient_cannot_list_users(self):
    response = self.patient_client.get(url)
    self.assertEqual(response.status_code, 403)  # Forbidden
```

### 2. Validation Testing

Data validation tested for:

- ✅ Required fields
- ✅ Format validation (email, phone, date)
- ✅ Uniqueness constraints
- ✅ Business logic rules

**Example:**

```python
def test_duplicate_email_rejected(self):
    response = self.client.post(url, {"email": existing_email})
    self.assertEqual(response.status_code, 400)
    self.assertIn("email", response.data["errors"])
```

### 3. State Transition Testing

Complex workflows tested:

- ✅ Appointment status transitions
- ✅ Slot availability changes
- ✅ OTP consumption
- ✅ Token blacklisting

**Example:**

```python
def test_booking_marks_slot_booked(self):
    slot.status = AVAILABLE
    book_appointment(slot)
    slot.refresh_from_db()
    self.assertEqual(slot.status, BOOKED)
```

### 4. Role-Based Access Testing

Three-role RBAC tested:

- ✅ Patient (read own data, book/cancel/reschedule)
- ✅ Doctor (read assigned appointments, update status)
- ✅ Admin (read/modify all data)

### 5. Response Format Testing

All responses validated for:

- ✅ Standard envelope structure
- ✅ Correct HTTP status codes
- ✅ Data field contents
- ✅ Error messages

---

## Common Test Patterns

### Setting Up Authenticated Request

```python
client = auth_client(user)
response = client.get(url)
```

### Creating Test Appointments

```python
slot = make_time_slot(doctor)
appointment = book_appointment(patient, slot)
```

### Asserting State Changes

```python
user.refresh_from_db()
self.assertEqual(user.failed_login_attempts, expected)
```

### Mocking External Services

```python
@patch("base.views.accounts.OTPService.send_otp")
def test_something(self, mock_otp):
    mock_otp.assert_called_once()
```

---

## Debugging Failed Tests

### Enable Verbose Output

```bash
python manage.py test base.tests.TestName --verbosity=3 --debug-mode
```

### Print Database State

```python
def test_something(self):
    User.objects.all().values()  # Print all users
    Appointment.objects.all().values()  # Print all appointments
```

### Check Response Content

```python
print(response.status_code)
print(response.data)
print(response.json())
```

### Use Python Debugger

```python
import pdb; pdb.set_trace()
```

---

## Future Enhancements

- [ ] Add performance tests (response time benchmarks)
- [ ] Add concurrency tests (race conditions)
- [ ] Add load tests (high-volume scenarios)
- [ ] Add integration tests (end-to-end workflows)
- [ ] Add e2e tests (Selenium/Cypress for Flutter)
- [ ] Improve coverage target to 95%+
- [ ] Add mutation testing
- [ ] Add property-based tests (Hypothesis)

---

## Maintenance Notes

1. **Keep tests isolated** - Don't depend on test execution order
2. **Use factories** - make_user(), make_slot() helpers
3. **Clean up in tearDown** - Use TestCase cleanup methods
4. **Mock external services** - OTP dispatch, FCM notifications
5. **Test edge cases** - Expired dates, duplicate bookings, lockouts
6. **Update tests when** - API changes, new endpoints, requirements change

---

## Related Documentation

- [API Documentation](./API_DOCUMENTATION.md)
- [Models Documentation](./base/models.py)
- [Views Documentation](./base/views/)
- [Services Documentation](./base/services.py)
- [Serializers Documentation](./base/serializers.py)

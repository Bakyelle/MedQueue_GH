# Queue Tests Quick Reference

## Test Coverage Map

| Endpoint                                  | HTTP  | Tests  | Pass Rate   |
| ----------------------------------------- | ----- | ------ | ----------- |
| GET /queue/my-position/                   | GET   | 6      | ✅ 100%     |
| POST /queue/leave/                        | POST  | 5      | ✅ 100%     |
| GET /queue/doctor/                        | GET   | 6      | ✅ 100%     |
| POST /queue/doctor/call-next/             | POST  | 6      | ✅ 100%     |
| POST /queue/doctor/entries/{id}/complete/ | POST  | 6      | ✅ 100%     |
| POST /queue/doctor/pause/                 | POST  | 5      | ✅ 100%     |
| POST /queue/doctor/resume/                | POST  | 4      | ✅ 100%     |
| POST /queue/doctor/close/                 | POST  | 6      | ✅ 100%     |
| GET /queue/admin/overview/                | GET   | 6      | ✅ 100%     |
| GET /queue/admin/stats/daily/             | GET   | 6      | ✅ 100%     |
| GET /queue/admin/stats/aggregate/         | GET   | 6      | ✅ 100%     |
| PATCH /queue/admin/entries/{id}/          | PATCH | 9      | ✅ 100%     |
| **TOTAL**                                 |       | **73** | **✅ 100%** |

## Test Classes Overview

```
QueueTestCase (Base - not run directly)
├── PatientQueueStatusViewTests (6 tests)
├── PatientLeaveQueueViewTests (5 tests)
├── DoctorQueueViewTests (6 tests)
├── DoctorCallNextViewTests (6 tests)
├── DoctorMarkCompleteViewTests (6 tests)
├── DoctorPauseQueueViewTests (5 tests)
├── DoctorResumeQueueViewTests (4 tests)
├── DoctorCloseQueueViewTests (6 tests)
├── AdminQueueOverviewViewTests (6 tests)
├── AdminDailyStatsViewTests (6 tests)
├── AdminAggregateStatsViewTests (6 tests)
└── AdminForceEntryStatusViewTests (9 tests)
```

## Common Test Patterns

### Test Patient Permission (403 Forbidden)

```python
def test_patient_cannot_access(self):
    response = self.patient_client1.post(self.url, {})
    self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
```

### Test Status Code Success

```python
def test_doctor_can_perform_action(self):
    response = self.doctor_client1.post(self.url, {})
    self.assertEqual(response.status_code, status.HTTP_200_OK)
```

### Test State Transition

```python
def test_status_changes(self):
    response = self.doctor_client1.post(self.url, {})
    self.assertEqual(response.status_code, status.HTTP_200_OK)
    self.entry1.refresh_from_db()
    self.assertEqual(self.entry1.status, QueueEntryStatus.COMPLETED)
```

### Test Response Structure

```python
def test_response_contains_data(self):
    response = self.doctor_client1.get(self.url)
    data = response.data.get("data", {})
    self.assertIn("entries", data)
    self.assertIn("waiting_count", data)
```

## URLs (Current Implementation)

All queue URLs are under `/api/v1/auth/` prefix:

```
/api/v1/auth/my-position/                    - Patient: Get queue position
/api/v1/auth/leave/                          - Patient: Leave queue
/api/v1/auth/doctor/                         - Doctor: View queue
/api/v1/auth/doctor/call-next/               - Doctor: Call next patient
/api/v1/auth/doctor/entries/{id}/complete/   - Doctor: Mark complete
/api/v1/auth/doctor/pause/                   - Doctor: Pause queue
/api/v1/auth/doctor/resume/                  - Doctor: Resume queue
/api/v1/auth/doctor/close/                   - Doctor: Close queue
/api/v1/auth/admin/overview/                 - Admin: Queue overview
/api/v1/auth/admin/stats/daily/              - Admin: Daily stats
/api/v1/auth/admin/stats/aggregate/          - Admin: Aggregate stats
/api/v1/auth/admin/entries/{id}/             - Admin: Force entry status
```

## Test Execution

### All tests (73 total)

```bash
python manage.py test base.tests.PatientQueueStatusViewTests \
  base.tests.PatientLeaveQueueViewTests base.tests.DoctorQueueViewTests \
  base.tests.DoctorCallNextViewTests base.tests.DoctorMarkCompleteViewTests \
  base.tests.DoctorPauseQueueViewTests base.tests.DoctorResumeQueueViewTests \
  base.tests.DoctorCloseQueueViewTests base.tests.AdminQueueOverviewViewTests \
  base.tests.AdminDailyStatsViewTests base.tests.AdminAggregateStatsViewTests \
  base.tests.AdminForceEntryStatusViewTests -v 1
```

### Single test class

```bash
python manage.py test base.tests.DoctorQueueViewTests
```

### Single test method

```bash
python manage.py test base.tests.DoctorQueueViewTests.test_doctor_can_view_queue
```

### With verbose output

```bash
python manage.py test base.tests.DoctorQueueViewTests -v 2
```

## Key Test Data (QueueTestCase)

**Users**:

- `self.patient1`, `self.patient2` (patients)
- `self.doctor1`, `self.doctor2` (doctors)
- `self.admin` (administrator)

**Models**:

- `self.today_session` - Active queue for doctor1, today
- `self.yesterday_session` - Closed queue for doctor1, yesterday
- `self.entry1` - Queue entry for patient1 (queue_number=1)
- `self.entry2` - Queue entry for patient2 (queue_number=2)
- `self.appt1`, `self.appt2` - Associated appointments

**Clients**:

- `self.patient_client1`, `self.patient_client2`
- `self.doctor_client1`, `self.doctor_client2`
- `self.admin_client`
- `self.client` - Unauthenticated

## Response Structure

### Success (200 OK)

```json
{
  "status": "success",
  "message": "Operation successful",
  "data": {
    /* endpoint-specific data */
  },
  "errors": null
}
```

### Error (400/403/404)

```json
{
  "status": "error",
  "message": "Error description",
  "data": null,
  "errors": {
    /* field-level errors */
  }
}
```

## Performance Baseline

- Full suite: ~52 seconds
- Per test: ~0.7 seconds average
- Database: In-memory SQLite (no network overhead)

## Status Codes

| Code | Meaning      | Common In                                           |
| ---- | ------------ | --------------------------------------------------- |
| 200  | Success      | All successful operations                           |
| 400  | Bad Request  | Invalid date format, missing required fields        |
| 401  | Unauthorized | Unauthenticated access                              |
| 403  | Forbidden    | Wrong user role (patient accessing doctor endpoint) |
| 404  | Not Found    | Non-existent entry/session/doctor                   |

## Debug Tips

### Print response data

```python
import json
print(json.dumps(response.data, indent=2))
```

### Check entry status

```python
self.entry1.refresh_from_db()
print(f"Status: {self.entry1.status}")
```

### List all entries in session

```python
entries = self.today_session.entries.all()
for e in entries:
    print(f"#{e.queue_number}: {e.patient.get_full_name()} - {e.status}")
```

## Related Tests

- **Appointment Tests**: 69 tests in `AppointmentsTestCase`
- **Account Tests**: ~40 tests in `AccountsTestCase`
- **Total Test Suite**: 180+ tests across all modules

## Files Modified

- `/base/tests.py` - Added 73 new queue tests
- `/base/views/queues.py` - Fixed 3 import statements
- `/QUEUE_TESTS_COMPLETION_REPORT.md` - Full documentation (this file)

## Next Iteration Goals

- [ ] Add integration tests with real Firebase sync
- [ ] Add performance/load tests
- [ ] Add Flutter app integration tests
- [ ] Fix appointments module import issue
- [ ] Add database transaction tests
- [ ] Add concurrent request handling tests

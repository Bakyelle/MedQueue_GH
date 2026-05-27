# Slot Generation Flow - Complete Architecture

## Overview

Slots are generated **on-demand** when a patient browses a doctor's availability. The system uses a lazy-loading pattern with idempotent creation to ensure slots are always available without bloating the database.

---

## High-Level Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    PATIENT BROWSES DOCTOR SLOTS                         │
│                  GET /appointments/doctors/{id}/slots/                  │
│                            ?date=YYYY-MM-DD                             │
└──────────────────────────────┬──────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    DoctorSlotListView.get()                             │
│  ✓ Parse doctor_id from URL                                            │
│  ✓ Validate date parameter (required, valid format, not in past)       │
└──────────────────────────────┬──────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              SlotService.generate_slots_for_date(doctor, date)          │
│                         [IDEMPOTENT]                                    │
│                                                                         │
│  1. Look up DoctorSchedule for:                                        │
│     ✓ doctor_id                                                         │
│     ✓ day_of_week (calculated from date)                               │
│     ✓ is_active = True                                                  │
│                                                                         │
│  2. If no schedule → return 0 (doctor doesn't work that day)            │
│                                                                         │
│  3. Check daily cap:                                                    │
│     ✓ Count existing BOOKED slots for that doctor+date                  │
│     ✓ If >= max_patients_per_day → return 0 (full)                     │
│                                                                         │
│  4. Generate time slots:                                                │
│     FOR start_time IN [schedule.start_time → schedule.end_time]:       │
│       ✓ Calculate slot_end = start_time + slot_duration_minutes        │
│       ✓ If slot_end <= schedule.end_time:                              │
│         • TimeSlot.objects.get_or_create(                              │
│           doctor, date, start_time                                      │
│           defaults: {end_time, status=AVAILABLE}                       │
│         )                                                               │
│       ✓ Increment created_count                                         │
│       ✓ Move to next: start_time = slot_end                            │
│                                                                         │
│  5. Return count of newly created slots                                 │
└──────────────────────────────┬──────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│        Query TimeSlot database for that doctor + date                   │
│        Order by start_time (ascending)                                  │
│        Return serialized slots with counts:                             │
│        ✓ total slots                                                     │
│        ✓ available slots (status = AVAILABLE)                           │
│        ✓ booked slots (status = BOOKED)                                 │
└──────────────────────────────┬──────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│              API Response (HTTP 200)                                    │
│                                                                         │
│  {                                                                      │
│    "status": "success",                                                │
│    "message": "Slots retrieved successfully.",                         │
│    "data": {                                                            │
│      "doctor_id": 5,                                                    │
│      "date": "2026-06-10",                                             │
│      "total": 32,                                                       │
│      "available": 28,                                                   │
│      "slots": [                                                         │
│        {                                                                │
│          "id": 451,                                                     │
│          "start_time": "08:00:00",                                     │
│          "end_time": "08:15:00",                                       │
│          "status": "available"                                         │
│        },                                                               │
│        {                                                                │
│          "id": 452,                                                     │
│          "start_time": "08:15:00",                                     │
│          "end_time": "08:30:00",                                       │
│          "status": "available"                                         │
│        },                                                               │
│        ...                                                              │
│      ]                                                                  │
│    },                                                                   │
│    "errors": null                                                       │
│  }                                                                      │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Data Models Involved

### 1. **DoctorSchedule** (Weekly Configuration)

```
┌──────────────────────────────────────────────────────┐
│              DoctorSchedule (Admin-Created)           │
├──────────────────────────────────────────────────────┤
│ doctor_id              : ForeignKey (User.role=doc)   │
│ day_of_week            : 0=Mon, 1=Tue, ..., 6=Sun     │
│ start_time             : TimeField (e.g., 08:00)      │
│ end_time               : TimeField (e.g., 17:00)      │
│ slot_duration_minutes  : int (default=15, 20, 30)     │
│ max_patients_per_day   : int (default=20, cap)        │
│ is_active              : bool (default=True)          │
│ created_at/updated_at  : timestamps                   │
├──────────────────────────────────────────────────────┤
│ Unique Together: (doctor, day_of_week)                │
│ → One schedule per doctor per weekday                 │
└──────────────────────────────────────────────────────┘

Example:
  Dr. Ahmed (ID=5) | Monday | 08:00-17:00 | 15-min slots | max 20/day
  Dr. Ahmed (ID=5) | Tuesday| 09:00-18:00 | 15-min slots | max 20/day
  Dr. Ahmed (ID=5) | Wed-Fri| OFF (no schedule)
```

### 2. **TimeSlot** (Daily Instances)

```
┌──────────────────────────────────────────────────────┐
│           TimeSlot (Generated Daily)                  │
├──────────────────────────────────────────────────────┤
│ doctor_id              : ForeignKey (User.role=doc)   │
│ date                   : DateField (specific day)     │
│ start_time             : TimeField (e.g., 08:00)      │
│ end_time               : TimeField (e.g., 08:15)      │
│ status                 : choice {AVAILABLE, BOOKED}   │
│ created_at             : timestamp                    │
├──────────────────────────────────────────────────────┤
│ Unique Together: (doctor, date, start_time)          │
│ Indexes: (doctor, date, status)                      │
└──────────────────────────────────────────────────────┘

Example (Auto-Generated on 2026-06-10 for Dr. Ahmed):
  Dr. Ahmed (ID=5) | 2026-06-10 | 08:00 | 08:15 | AVAILABLE
  Dr. Ahmed (ID=5) | 2026-06-10 | 08:15 | 08:30 | AVAILABLE
  Dr. Ahmed (ID=5) | 2026-06-10 | 08:30 | 08:45 | AVAILABLE
  Dr. Ahmed (ID=5) | 2026-06-10 | 08:45 | 09:00 | BOOKED (appointment exists)
  ... (total 32 slots for 08:00-17:00 with 15-min intervals)
```

### 3. **Appointment** (Booking Record)

```
Appointment Links to TimeSlot:
  When booking: slot.status changes from AVAILABLE → BOOKED
  When cancelling: slot.status changes back to AVAILABLE
```

---

## Slot Generation Algorithm (Step-by-Step)

### Input

- `doctor`: User object (verified doctor)
- `date`: datetime.date object (e.g., 2026-06-10)

### Process

```python
def generate_slots_for_date(doctor, date):
    # STEP 1: Determine day of week
    day_of_week = date.weekday()  # 0=Monday, 1=Tuesday, ..., 6=Sunday
    # Example: 2026-06-10 is a Wednesday → day_of_week = 2

    # STEP 2: Look up schedule for that doctor on that day
    schedule = DoctorSchedule.objects.get(
        doctor=doctor,
        day_of_week=day_of_week,
        is_active=True
    )
    # If not found: return 0 (doctor doesn't work that day)

    # STEP 3: Check daily patient cap
    existing_booked = TimeSlot.objects.filter(
        doctor=doctor,
        date=date,
        status=BOOKED
    ).count()
    if existing_booked >= schedule.max_patients_per_day:
        return 0  # Daily cap reached, no more slots

    # STEP 4: Generate slots by walking through time
    created_count = 0
    slot_start = schedule.start_time           # e.g., 08:00
    duration = timedelta(minutes=schedule.slot_duration_minutes)  # e.g., 15 min

    while True:
        # Calculate slot end time
        slot_end_dt = datetime.combine(date, slot_start) + duration
        slot_end = slot_end_dt.time()

        # Check if this slot would exceed clinic hours
        if slot_end > schedule.end_time:
            break  # Stop generating

        # Create or get the slot (idempotent)
        slot, created = TimeSlot.objects.get_or_create(
            doctor=doctor,
            date=date,
            start_time=slot_start,
            defaults={
                "end_time": slot_end,
                "status": SlotStatus.AVAILABLE
            }
        )

        if created:
            created_count += 1

        # Move to next slot
        slot_start = slot_end
        if slot_start >= schedule.end_time:
            break  # No more room

    return created_count  # Total newly created slots
```

### Example Execution

```
Input: Dr. Ahmed (ID=5), Date: 2026-06-10 (Wednesday)

1. day_of_week = 2 (Wednesday)

2. Look up DoctorSchedule:
   ✓ Found: Wed | 08:00-17:00 | 15-min slots | max 20/day

3. Check daily cap:
   ✓ Existing BOOKED slots: 3
   ✓ Cap: 20 → OK to proceed

4. Generate slots:
   Slot 1:  08:00 → 08:15 ✓ Created
   Slot 2:  08:15 → 08:30 ✓ Created
   Slot 3:  08:30 → 08:45 ✓ Created
   ...
   Slot 32: 16:45 → 17:00 ✓ Created
   Slot 33: 17:00 → 17:15 ✗ Exceeds end_time (17:00), STOP

5. Return: 32 slots created
```

---

## Idempotency Guarantee

The system uses `get_or_create()` to ensure slots are never duplicated:

```
First call on 2026-06-10:
  ✓ All 32 slots created (created_count=32)

Second call on 2026-06-10 (same patient viewing again):
  ✓ All slots already exist
  ✓ No new slots created (created_count=0)
  ✓ Returns existing slots with current status (AVAILABLE/BOOKED)

Third call after 1 booking:
  ✓ Slots still exist
  ✓ One slot now shows status=BOOKED
  ✓ Remaining 31 show status=AVAILABLE
```

---

## State Transitions: Slot Lifecycle

```
┌──────────────────────────────────────────────────────────────────┐
│                      SLOT LIFECYCLE                              │
└──────────────────────────────────────────────────────────────────┘

                    [AVAILABLE]
                   /     |      \
                  /      |       \
            BOOK /     ADMIN      \ PAST
              /          |         \
             ▼           ▼          ▼
          [BOOKED]    [BLOCKED]   [EXPIRED]
            │ │                      │
            │ │ CANCEL               │ (Age > X days)
            │ │                      │
            │ └────────┬─────────────┘
            │          ▼
            └─────► [AVAILABLE] (again)


AVAILABLE  → Slot is bookable by patient
BOOKED     → Appointment exists for this slot
BLOCKED    → Admin manually reserved for clinic use
EXPIRED    → Past date (no transitions, just historical)
```

---

## View Integration

### `DoctorSlotListView` (File: `/base/views/appointments.py`)

```python
class DoctorSlotListView(APIView):
    """
    GET /appointments/doctors/<doctor_id>/slots/?date=YYYY-MM-DD
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, doctor_id: int):
        # 1. Resolve doctor
        doctor = User.objects.get(pk=doctor_id, role="doctor", is_active=True)

        # 2. Parse and validate date
        date_str = request.query_params.get("date")
        requested_date = datetime.date.fromisoformat(date_str)

        # Validation:
        # ✓ date param is required
        # ✓ date must be valid ISO format
        # ✓ date must not be in past

        # 3. Generate slots on-demand (idempotent)
        SlotService.generate_slots_for_date(doctor, requested_date)

        # 4. Query and return slots
        slots = TimeSlot.objects.filter(
            doctor=doctor,
            date=requested_date,
        ).order_by("start_time")

        return api_response(
            data={
                "doctor_id": doctor_id,
                "date": date_str,
                "slots": TimeSlotSerializer(slots, many=True).data,
                "total": slots.count(),
                "available": slots.filter(status=SlotStatus.AVAILABLE).count(),
            },
            message="Slots retrieved successfully.",
        )
```

---

## Service Layer

### `SlotService` (File: `/base/services.py`)

```python
class SlotService:

    @staticmethod
    def get_available_slots(doctor, date):
        """
        Get only AVAILABLE slots for a given doctor+date.
        Generates if needed.
        """
        SlotService.generate_slots_for_date(doctor, date)
        return TimeSlot.objects.filter(
            doctor=doctor,
            date=date,
            status=SlotStatus.AVAILABLE,
        ).order_by("start_time")

    @staticmethod
    def generate_slots_for_date(doctor, date):
        """
        Core slot generation logic (see algorithm above).
        """
        # ... (implementation)

    @staticmethod
    def block_slot(slot):
        """Admin blocks a specific slot."""
        slot.status = SlotStatus.BLOCKED
        slot.save()

    @staticmethod
    def release_slot(slot):
        """Release slot back to AVAILABLE (on cancellation)."""
        slot.status = SlotStatus.AVAILABLE
        slot.save()
```

---

## Configuration: How to Adjust Slot Generation

### Scenario 1: Change Slot Duration

**Current**: 15-minute slots  
**Desired**: 30-minute slots

```
Admin Dashboard → Edit DoctorSchedule
  Dr. Ahmed | Wednesday | slot_duration_minutes: 15 → 30

Next time slots are requested for Dr. Ahmed on Wednesday:
  ✓ Old slots (15-min) remain in DB
  ✓ New slots (30-min) are generated
  ✓ Query returns both old and new (duplicates!)

CAVEAT: Manual cleanup of old slots needed if changing duration.
```

### Scenario 2: Change Daily Patient Cap

**Current**: 20 patients/day  
**Desired**: 25 patients/day

```
Admin Dashboard → Edit DoctorSchedule
  Dr. Ahmed | Wednesday | max_patients_per_day: 20 → 25

Next slot generation:
  ✓ Count existing BOOKED slots
  ✓ If < 25, allow new slots to be generated
  ✓ If ≥ 25, stop (cap reached)
```

### Scenario 3: Pre-Generate Next 30 Days

**Celery Beat Task** (not yet implemented):

```python
from celery import shared_task

@shared_task
def pre_generate_slots_task():
    """
    Run nightly (e.g., 23:00) to pre-generate next 30 days of slots.
    Reduces wait time when patients browse.
    """
    for days_ahead in range(1, 31):
        target_date = datetime.date.today() + timedelta(days=days_ahead)
        for doctor in User.objects.filter(role="doctor", is_active=True):
            SlotService.generate_slots_for_date(doctor, target_date)
```

---

## Error Scenarios & Handling

```
❌ Scenario 1: Doctor not found
   → HTTP 404
   → "Doctor not found."

❌ Scenario 2: No date parameter
   → HTTP 400
   → "Query parameter 'date' is required (YYYY-MM-DD)."

❌ Scenario 3: Invalid date format
   → HTTP 400
   → "Invalid date format. Use YYYY-MM-DD."

❌ Scenario 4: Date is in the past
   → HTTP 400
   → "Cannot view slots for past dates."

✓ Scenario 5: No schedule for that day
   → HTTP 200
   → "slots": [] (empty list, total=0, available=0)

✓ Scenario 6: Daily cap already reached
   → HTTP 200
   → Existing slots returned (no new ones generated)

✓ Scenario 7: Slots already exist
   → HTTP 200
   → Existing slots returned (idempotent)
```

---

## Database Queries Involved

### Query 1: Get DoctorSchedule

```sql
SELECT * FROM base_doctorschedule
WHERE doctor_id = 5
  AND day_of_week = 2        -- Wednesday
  AND is_active = true;
```

### Query 2: Count Booked Slots

```sql
SELECT COUNT(*) FROM base_timeslot
WHERE doctor_id = 5
  AND date = '2026-06-10'
  AND status = 'booked';
```

### Query 3: Get or Create TimeSlot (batch)

```sql
-- For each slot time:
SELECT * FROM base_timeslot
WHERE doctor_id = 5
  AND date = '2026-06-10'
  AND start_time = '08:00:00'
-- If not exists, INSERT new record
```

### Query 4: Fetch All Slots for View

```sql
SELECT * FROM base_timeslot
WHERE doctor_id = 5
  AND date = '2026-06-10'
ORDER BY start_time ASC;
```

---

## Performance Considerations

| Factor               | Impact                                 | Optimization                     |
| -------------------- | -------------------------------------- | -------------------------------- |
| **Slot Count**       | 32 slots/doctor/day × multiple queries | Index on (doctor, date, status)  |
| **Daily Generation** | Runs only on first view (lazy)         | Pre-generate nightly with Celery |
| **Database Hit**     | Multiple reads per slot                | Batch get_or_create if possible  |
| **Serialization**    | TimeSlotSerializer × 32 slots          | Efficient Django serializer      |
| **API Response**     | JSON payload for 32 slots              | Typical ~5KB, acceptable         |

---

## Summary

| Component                                 | Role           | Details                                               |
| ----------------------------------------- | -------------- | ----------------------------------------------------- |
| **DoctorSlotListView**                    | HTTP Endpoint  | Validates request, triggers generation, returns slots |
| **SlotService.generate_slots_for_date()** | Business Logic | Core algorithm for slot generation                    |
| **DoctorSchedule**                        | Configuration  | Weekly template for slot parameters                   |
| **TimeSlot**                              | Data Model     | Actual bookable slots (daily instances)               |
| **get_or_create()**                       | Idempotency    | Ensures no duplicate slots                            |

**Key Principle**: Slots are **lazy-generated on-demand** using a **repeating schedule pattern**, with **idempotent creation** to prevent duplicates.

# MedQueue GH

A cross-platform mobile application designed to modernize healthcare access at local hospitals in Ghana, starting with a pilot deployment at the **University of Energy and Natural Resources (UENR) Health Services**.

> Mobile-based medical appointment scheduling with virtual queuing, an AI health assistant, and emergency response support.

---

## Table of Contents

- [About](#about)
- [Key Features](#key-features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Backend Setup (Django)](#backend-setup-django)
  - [Mobile App Setup (Flutter)](#mobile-app-setup-flutter)
- [Configuration](#configuration)
- [API](#api)
- [Contributing](#contributing)
- [License](#license)

---

## About

Many hospitals still rely on manual and phone-based appointment scheduling, which contributes to long wait times, missed appointments, and limited visibility into patient flow.

**MedQueue GH** helps by:

- enabling patients to book, reschedule, or cancel appointments digitally
- providing a live **virtual queue** with real-time position updates
- sending automated reminders (push/SMS/WhatsApp, depending on configuration)
- offering first-aid guidance via an AI assistant (non-diagnostic)
- supporting emergency SOS with location capture and notification

---

## Key Features

- **Authentication**: Role-based access (Patient, Doctor, Admin)
- **Appointments**: Browse doctors, view availability, book/reschedule/cancel
- **Virtual Queue**: Live queue position, estimated wait time, readiness alerts
- **AI Assistant**: First-aid guidance and basic symptom information *(non-diagnostic)*
- **Emergency SOS**: One-tap SOS with GPS capture and hospital alert
- **Notifications**: Push notifications (FCM) plus optional SMS/WhatsApp reminders
- **Admin Tools**: User management, schedules, queue monitoring, emergency logs

---

## Tech Stack

### Mobile (Frontend)

- **Flutter (Dart)**
- Material Design
- Maps/GPS support (e.g., Google Maps)

### Backend

- **Django**
- **Django REST Framework**
- *(Optional)* **Django Channels** for real-time updates

### Data

- SQLite for development
- PostgreSQL recommended for production

### Integrations (optional / configurable)

- Firebase Authentication + FCM
- Firebase Storage / Realtime Database
- Google Maps API
- WhatsApp Business API
- SMS provider (e.g., Arkesel)
- LLM provider (OpenAI / Hugging Face)

---

## Project Structure

> This section may need adjustment to match the current repo layout.

Common layout:

- `medqueue_backend/` — Django backend (API, models, admin)
- `mobile/` or `medqueue_mobile/` — Flutter app
- `requirements.txt` — Python dependencies

---

## Getting Started

### Prerequisites

- Flutter SDK (3.x)
- Dart SDK
- Python 3.10+
- pip
- Git
- Android Studio and/or Xcode (for emulators)

### Backend Setup (Django)

```bash
# from the repo root
cd medqueue_backend

# create and activate a virtual environment
python -m venv venv
# macOS/Linux
source venv/bin/activate
# Windows (PowerShell)
# .\venv\Scripts\Activate.ps1

pip install -r requirements.txt

python manage.py migrate
python manage.py runserver
```

### Mobile App Setup (Flutter)

```bash
# from the repo root
# cd <flutter-project-directory>
flutter pub get
flutter run
```

---

## Configuration

Environment variables and secrets (API keys, Firebase config, SMS/WhatsApp credentials) **should not be committed**.

Create a local `.env` (or use your preferred secret management approach) and configure the backend/mobile app accordingly.

If you want, tell me what env vars your project actually uses (or point me to the settings file), and I can document them precisely.

---

## API

If the backend exposes REST endpoints via Django REST Framework, document them here (or link to an API spec).

Suggested minimum:

- Authentication
- Doctors & schedules
- Appointments
- Queue updates
- Emergency SOS events

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-change`
3. Commit changes: `git commit -m "Describe your change"`
4. Push to your fork: `git push origin feature/my-change`
5. Open a Pull Request

---

## License

Add your license here (e.g., MIT, Apache-2.0) or link to the `LICENSE` file.

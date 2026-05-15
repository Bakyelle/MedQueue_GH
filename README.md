# 🏥 MedQueue GH

&gt; A mobile-based medical appointment scheduling system with virtual queuing, AI chatbot, and emergency response — built for hospitals in Ghana.

---

## 📋 Table of Contents

- [About the Project](#about-the-project)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Screenshots](#screenshots)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Environment Variables](#environment-variables)
- [API Endpoints](#api-endpoints)
- [Database Schema](#database-schema)
- [Team](#team)
- [Supervisor](#supervisor)
- [License](#license)

---

## 🩺 About the Project

**MedQueue GH** is a cross-platform mobile application designed to modernize healthcare access at local hospitals in Ghana, starting with a pilot deployment at the **University of Energy and Natural Resources (UENR) Health Services**.

The system replaces manual, phone-based appointment scheduling with a digital, real-time solution that lets patients book appointments, wait virtually in a live queue, get first-aid guidance from an AI chatbot, and request emergency assistance with one tap.

### Problem We Solve
- ❌ Long wait times at hospital reception desks
- ❌ Missed appointments due to lack of reminders
- ❌ No real-time visibility into queue position
- ❌ Delayed emergency response due to poor location sharing
- ❌ Inefficient doctor-patient communication

### Our Solution
- ✅ Book, reschedule, or cancel appointments from your phone
- ✅ Join a virtual queue and track your position in real time
- ✅ Receive automated reminders via push notification, SMS, and WhatsApp
- ✅ Get instant first-aid guidance from an AI health assistant
- ✅ Trigger emergency SOS with automatic GPS location sharing
- ✅ Chat directly with your doctor via WhatsApp

---

## ✨ Features

| Module | Description |
|--------|-------------|
| 🔐 **Authentication** | Phone OTP & email/password login with role-based access control (Patient, Doctor, Admin) |
| 📅 **Appointments** | Browse doctors by specialization, view available slots, book/reschedule/cancel appointments |
| 🚶 **Virtual Queue** | Real-time queue with live position updates, estimated wait time, and "get ready" alerts |
| 🤖 **AI Chatbot** | First-aid guidance and basic symptom information (non-diagnostic, with medical disclaimer) |
| 🚨 **Emergency SOS** | One-tap emergency button with 5-second countdown, GPS capture, and instant hospital notification |
| 💬 **WhatsApp Integration** | In-app WhatsApp chat initiation between patients and doctors |
| 🔔 **Notifications** | Push (FCM), SMS, and WhatsApp reminders (24h & 30min before appointment) |
| 📊 **Admin Dashboard** | User management, doctor schedule setup, live queue monitoring, emergency logs, and reports |

---

## 🛠 Tech Stack

### Frontend
- **Flutter** — Cross-platform mobile UI framework (Dart)
- **Material Design 3** — Modern, consistent UI/UX
- **google_maps_flutter** — GPS and map rendering

### Backend
- **Django** — Python web framework (REST API + ORM + Admin)
- **Django REST Framework** — API serialization and authentication
- **Django Channels** *(optional)* — Real-time WebSocket support for queue updates

### Database
- **Django ORM + SQLite** *(development)*
- **PostgreSQL** *(recommended for production)*

### External Services
| Service | Purpose |
|---------|---------|
| Firebase Authentication | Phone OTP & email/password auth |
| Firebase Cloud Messaging (FCM) | Push notifications |
| Firebase Storage | Profile picture uploads |
| Firebase Realtime Database | Live queue position sync |
| Google Maps API | GPS location & map rendering |
| Meta WhatsApp Business API | Doctor-patient messaging |
| OpenAI / Hugging Face API | AI chatbot responses |
| Arkesel SMS API | SMS reminders & OTP fallback (Ghana) |

---

## 📱 Screenshots

*Coming soon — screenshots will be added after the first UI sprint.*

---

## 🚀 Getting Started

### Prerequisites

Make sure you have the following installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.16+)
- [Dart](https://dart.dev/get-dart)
- [Python](https://www.python.org/downloads/) (v3.10+)
- [pip](https://pip.pypa.io/en/stable/installation/)
- [Git](https://git-scm.com/downloads)
- Android Studio / Xcode (for emulator or physical device)

### Installation

#### 1. Clone the repository

#### 2. Cd medqueue_backend

# install, create and activate a virtual environment

#### 3. pip install virtualenv

virtualenv venv

source venv/bin/activate

# install the requirement

pip install -r requirements.txt

# run project

python manage.py runserver



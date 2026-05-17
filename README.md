# MedQueue GH — Frontend (Flutter App)

This branch contains the **frontend mobile app** for **MedQueue GH**, a cross-platform system designed to modernize healthcare access at local hospitals in Ghana, with the first deployment at the **University of Energy and Natural Resources (UENR) Health Services**.
## Team

- BAKYELLE DAVID (Lead)
- AMOANIMAA Bernice (Ms)
- OSIKA Kofi Ricky
- OFOSUHENE Jeffery Nana
- ASABAH Prince

## Repository Branches

- **Frontend (this branch):** `master` — MedQueue GH Flutter mobile app
- **Backend:** `main` — Django REST API

> If you’re looking for the backend API code, switch to the `main` branch.

---

## What’s in this branch

- Flutter mobile application source code (cross-platform)
- Project configuration for Android, iOS, and web

---

## Getting Started (Frontend)

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.16+ recommended)
- Dart
- Git
- Android Studio and/or Xcode (for emulators or real devices)

### Setup

```bash
# clone
 git clone https://github.com/Bakyelle/MedQueue_GH.git
 cd MedQueue_GH

# (important) switch to frontend branch
 git checkout master

# get dependencies
 flutter pub get

# run app (Android/iOS/Web)
 flutter run
```

---

## Connecting to the Backend API

This mobile app requires a **deployed backend API URL** for production use.

- **Backend API repo/branch:** `main` (Django/DRF)
- **API Base URL:** (set this in your Flutter `.env` or config file, e.g., `https://your-deployed-api-host/api/`)

Update your app’s environment or configuration file to point to the deployed backend’s public URL before distributing the app.

---

## Project Structure (Frontend)

Main directories:

- `lib/` — Dart source code
- `android/`, `ios/`, `linux/`, `macos/`, `web/`, `windows/` — Platform project files
- `pubspec.yaml` — Flutter dependencies and assets

For other docs, see [`LAUNCH_SUMMARY.md`](LAUNCH_SUMMARY.md), [`PROJECT_CHECKLIST.md`](PROJECT_CHECKLIST.md), or the backend branch for general system design.

---

## Contributing

1. Create a feature branch off the correct branch (frontend changes from `master`)
2. Commit your changes
3. Open a PR

---

## License

Add a license (and/or a `LICENSE` file) for the project.

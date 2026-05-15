# MedQueue GH - Healthcare Appointment & Queue Management System

A modern, fully-functional Flutter frontend prototype for a healthcare appointment and queue management system designed for Ghanaian hospitals and clinics.

## 🎯 Features

### For Patients
- ✅ User registration and login
- ✅ Browse available doctors with ratings and specializations
- ✅ Book appointments digitally
- ✅ View appointment history
- ✅ Real-time queue tracking with position updates
- ✅ AI health chatbot for symptom information
- ✅ Emergency SOS button with location sharing
- ✅ Push notifications and reminders
- ✅ Personal profile management

### For Doctors
- ✅ View daily schedule and appointments
- ✅ Manage consultation queue
- ✅ Mark patient consultations as completed
- ✅ Availability settings
- ✅ Performance ratings and statistics

### For Administrators
- ✅ System dashboard with key metrics
- ✅ Emergency request management
- ✅ User management overview
- ✅ Live queue monitoring
- ✅ System statistics and reports

## 📁 Project Structure

```
lib/
├── main.dart                              # App entry point
├── models/                                # Data models
│   ├── user_model.dart                   # User, Patient, Doctor, Admin models
│   ├── appointment_model.dart            # Appointment model
│   ├── queue_model.dart                  # Queue entry model
│   ├── emergency_model.dart              # Emergency request model
│   ├── notification_model.dart           # Notification model
│   └── chatbot_model.dart                # Chat message model
├── services/                              # Mock services (ready for backend integration)
│   ├── auth_service.dart                 # Authentication logic
│   ├── appointment_service.dart          # Appointment management
│   ├── queue_service.dart                # Queue management
│   ├── emergency_service.dart            # Emergency handling
│   ├── chatbot_service.dart              # AI chatbot logic
│   └── notification_service.dart         # Notification management
├── screens/                               # UI screens
│   ├── auth/                             # Authentication screens
│   │   ├── splash_screen.dart
│   │   ├── onboarding_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── role_selection_screen.dart
│   │   └── forgot_password_screen.dart
│   ├── patient/                          # Patient screens
│   │   ├── patient_home_screen.dart
│   │   ├── book_appointment_screen.dart
│   │   ├── queue_tracker_screen.dart
│   │   ├── chatbot_screen.dart
│   │   ├── emergency_sos_screen.dart
│   │   └── notifications_screen.dart
│   ├── doctor/                           # Doctor screens
│   │   └── doctor_home_screen.dart
│   └── admin/                            # Admin screens
│       └── admin_home_screen.dart
├── widgets/                              # Reusable components
│   ├── custom_button.dart                # Button variants
│   ├── custom_textfield.dart             # Input fields
│   ├── custom_cards.dart                 # Card components
│   └── custom_components.dart            # App bars, dialogs, etc.
├── routes/                               # Navigation configuration
│   └── app_routes.dart
└── utils/                                # Utilities
    ├── app_colors.dart                   # Color palette and theme
    ├── app_constants.dart                # App constants
    └── app_dummy_data.dart               # Mock data for testing
```

## 🎨 Design System

### Color Palette
- **Primary Blue**: `#0066CC` - Main brand color
- **Primary Green**: `#00A86B` - Healthcare trust
- **Emergency Red**: `#E74C3C` - Emergency actions
- **Success Green**: `#27AE60` - Successful operations
- **Warning Orange**: `#F39C12` - Warnings and pending
- **Info Blue**: `#3498DB` - Informational
- **Backgrounds**: Light gray (`#F8F9FA`) and white

### Components
- Clean, modern card-based design
- Rounded corners (8px border radius)
- Smooth animations and transitions
- Responsive layout for all screen sizes
- Medical-themed iconography

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.10.3+
- Dart SDK
- Android Studio / Xcode (for emulator)

### Installation

1. **Navigate to project directory**
   ```bash
   cd c:\Users\Felix\Documents\MedQueue_Frontend
   ```

2. **Get dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Running on Specific Device
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device_id>
```

## 🧪 Testing with Mock Data

The app uses mock services that simulate network delays and server responses. All data is hardcoded for demonstration:

- **Login credentials**: Any email/password combination works
- **Mock patients**: john.osei@example.com
- **Mock doctors**: kwasi@example.com or messages containing "doctor"
- **Mock admins**: admin@example.com or messages containing "admin"

### Available Mock Actions
- Book appointments
- Join virtual queue
- Request emergencies
- Chat with AI health assistant
- View notifications
- Manage profile

## 📦 Dependencies

```yaml
provider: ^6.0.0           # State management
intl: ^0.19.0             # Internationalization
flutter_spinkit: ^5.2.0   # Loading animations
uuid: ^4.0.0              # Unique IDs
google_fonts: ^6.1.0      # Custom fonts
```

## 🔄 State Management

The app uses **Provider** for state management:

- `AuthService` - Manages user authentication and roles
- `AppointmentService` - Handles appointment operations
- `QueueService` - Manages virtual queue
- `EmergencyService` - Emergency request handling
- `ChatbotService` - AI chatbot conversations
- `NotificationService` - Push notifications

All services extend `ChangeNotifier` for reactive updates.

## 🔌 Backend Integration

The current implementation uses mock services. To integrate with a real backend:

1. **Update Services**: Modify `services/*.dart` to make HTTP requests instead of using `Future.delayed()`
2. **API Configuration**: Create an `APIClient` class for HTTP communication
3. **Error Handling**: Implement proper error handling and retry logic
4. **Authentication**: Replace mock auth with JWT token handling
5. **Real-time Updates**: Consider using WebSockets for queue updates

Example service modification:
```dart
// Mock (current)
await Future.delayed(const Duration(seconds: 2));

// Backend (future)
final response = await http.post(
  Uri.parse('$apiUrl/appointments'),
  body: json.encode(appointmentData),
);
```

## 🎯 Navigation Flow

### Authentication Flow
Splash → Onboarding → Role Selection → Login/Register

### Patient Flow
Patient Home → Book Appointment → Queue Tracker → Notifications

### Doctor Flow
Doctor Home → Daily Schedule → Queue Management

### Admin Flow
Admin Home → Emergency Management → User Management

## 🛠️ Customization

### Changing Colors
Edit `lib/utils/app_colors.dart`:
```dart
static const Color primaryBlue = Color(0xFF0066CC);
```

### Modifying Constants
Edit `lib/utils/app_constants.dart`:
```dart
static const int appointmentBookingDaysAhead = 30;
```

### Adding New Screens
1. Create file in appropriate `screens/` folder
2. Add route to `app_routes.dart`
3. Import in `main.dart` if needed

## 📱 Device Support

- ✅ Android 5.0+
- ✅ iOS 11.0+
- ✅ Web (with minor adjustments)

## 🐛 Known Limitations

1. **No persistent storage** - Data is lost on app restart
2. **Mock data only** - All operations use simulated responses
3. **No real-time updates** - Queue positions don't auto-refresh
4. **No image handling** - Avatar is placeholder only
5. **No location services** - GPS is mocked

## 📈 Future Enhancements

- [ ] Real backend API integration
- [ ] Firebase authentication
- [ ] Persistent local storage (SQLite)
- [ ] Real-time updates (WebSocket)
- [ ] Payment integration
- [ ] Video consultation
- [ ] Offline support
- [ ] Multi-language support
- [ ] Accessibility improvements
- [ ] Dark mode theme

## 📝 Code Style

- Follows Dart style guide
- Proper separation of concerns
- Reusable widget components
- Comprehensive error handling
- Clear variable and function naming

## 📄 License

This project is part of an academic university project for UENR Health Centre.

## 👥 Team

Designed and developed as a comprehensive Flutter frontend prototype for MedQueue GH.

## 📞 Support

For issues, improvements, or questions, please refer to the project documentation or contact the development team.

---

**MedQueue GH** - Making healthcare accessible and efficient for Ghana 🏥

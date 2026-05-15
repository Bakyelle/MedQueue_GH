import 'package:flutter/material.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/patient/patient_home_screen.dart';
import '../screens/patient/book_appointment_screen.dart';
import '../screens/patient/queue_tracker_screen.dart';
import '../screens/patient/chatbot_screen.dart';
import '../screens/patient/emergency_sos_screen.dart';
import '../screens/patient/notifications_screen.dart';
import '../screens/doctor/doctor_home_screen.dart';
import '../screens/admin/admin_home_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String roleSelection = '/role-selection';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  
  // Patient Routes
  static const String patientHome = '/patient-home';
  static const String bookAppointment = '/book-appointment';
  static const String queueTracker = '/queue-tracker';
  static const String patientChatbot = '/patient-chatbot';
  static const String emergencySos = '/emergency-sos';
  static const String patientNotifications = '/patient-notifications';
  
  // Doctor Routes
  static const String doctorHome = '/doctor-home';
  
  // Admin Routes
  static const String adminHome = '/admin-home';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      onboarding: (context) => const OnboardingScreen(),
      roleSelection: (context) => const RoleSelectionScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      patientHome: (context) => const PatientHomeScreen(),
      bookAppointment: (context) => const BookAppointmentScreen(),
      queueTracker: (context) => const QueueTrackerScreen(),
      patientChatbot: (context) => const ChatbotScreen(),
      emergencySos: (context) => const EmergencySosScreen(),
      patientNotifications: (context) => const NotificationsScreen(),
      doctorHome: (context) => const DoctorHomeScreen(),
      adminHome: (context) => const AdminHomeScreen(),
    };
  }
}

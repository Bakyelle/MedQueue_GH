import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../utils/app_dummy_data.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Mock login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));

      // Mock validation
      if (email.isEmpty || password.isEmpty) {
        _errorMessage = 'Email and password are required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!email.contains('@')) {
        _errorMessage = 'Invalid email format';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Mock user creation based on email
      if (email.contains('doctor')) {
        _currentUser = Doctor(
          id: '1',
          email: email,
          password: password,
          fullName: 'Dr. Kwasi Mensah',
          phone: '+233551234567',
          specialization: 'General Practice',
          createdAt: DateTime.now(),
          rating: 4.8,
          yearsOfExperience: 8,
        );
      } else if (email.contains('admin')) {
        _currentUser = Admin(
          id: '2',
          email: email,
          password: password,
          fullName: 'Admin User',
          phone: '+233551234567',
          department: 'Hospital Management',
          createdAt: DateTime.now(),
        );
      } else {
        _currentUser = Patient(
          id: '0',
          email: email,
          password: password,
          fullName: 'John Osei',
          phone: '+233551234567',
          createdAt: DateTime.now(),
          dateOfBirth: '1995-06-15',
          bloodType: 'O+',
          emergencyContact: 'Mary Osei',
          emergencyPhone: '+233551234568',
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Mock register
  Future<bool> register(String email, String password, String fullName, String phone, String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));

      // Mock validation
      if (email.isEmpty || password.isEmpty || fullName.isEmpty || phone.isEmpty) {
        _errorMessage = 'All fields are required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.length < 6) {
        _errorMessage = 'Password must be at least 6 characters';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Mock user creation
      if (role == 'doctor') {
        _currentUser = Doctor(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          specialization: 'General Practice',
          createdAt: DateTime.now(),
        );
      } else if (role == 'admin') {
        _currentUser = Admin(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          department: 'Management',
          createdAt: DateTime.now(),
        );
      } else {
        _currentUser = Patient(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          createdAt: DateTime.now(),
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Registration failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Mock logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _currentUser = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // Mock forgot password
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (email.isEmpty || !email.contains('@')) {
        _errorMessage = 'Please enter a valid email';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to process request: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

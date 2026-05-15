import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/emergency_model.dart';

class EmergencyService extends ChangeNotifier {
  final List<EmergencyRequest> _emergencies = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<EmergencyRequest> get emergencies => _emergencies;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Request emergency help
  Future<bool> requestEmergency({
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String description,
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (description.isEmpty) {
        _errorMessage = 'Please describe the emergency';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final emergencyRequest = EmergencyRequest(
        id: const Uuid().v4(),
        patientId: patientId,
        patientName: patientName,
        patientPhone: patientPhone,
        latitude: latitude,
        longitude: longitude,
        description: description,
        status: EmergencyStatus.pending,
        createdAt: DateTime.now(),
      );

      _emergencies.add(emergencyRequest);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to request emergency help: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get emergency requests for admin
  Future<List<EmergencyRequest>> getEmergencies() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      _isLoading = false;
      notifyListeners();
      return _emergencies;
    } catch (e) {
      _errorMessage = 'Failed to fetch emergencies: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Get active emergencies only
  List<EmergencyRequest> get activeEmergencies =>
      _emergencies.where((e) => e.isActive).toList();

  // Acknowledge emergency (for admin)
  Future<bool> acknowledgeEmergency(String emergencyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      final index = _emergencies.indexWhere((e) => e.id == emergencyId);
      if (index != -1) {
        final emergency = _emergencies[index];
        _emergencies[index] = EmergencyRequest(
          id: emergency.id,
          patientId: emergency.patientId,
          patientName: emergency.patientName,
          patientPhone: emergency.patientPhone,
          latitude: emergency.latitude,
          longitude: emergency.longitude,
          description: emergency.description,
          status: EmergencyStatus.acknowledged,
          createdAt: emergency.createdAt,
          acknowledgedAt: DateTime.now(),
          assignedStaffName: 'Emergency Response Team',
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to acknowledge emergency: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update emergency status
  Future<bool> updateEmergencyStatus(String emergencyId, EmergencyStatus status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      final index = _emergencies.indexWhere((e) => e.id == emergencyId);
      if (index != -1) {
        final emergency = _emergencies[index];
        _emergencies[index] = EmergencyRequest(
          id: emergency.id,
          patientId: emergency.patientId,
          patientName: emergency.patientName,
          patientPhone: emergency.patientPhone,
          latitude: emergency.latitude,
          longitude: emergency.longitude,
          description: emergency.description,
          status: status,
          createdAt: emergency.createdAt,
          acknowledgedAt: emergency.acknowledgedAt,
          assignedAmbulanceId: emergency.assignedAmbulanceId,
          assignedStaffName: emergency.assignedStaffName,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update emergency status: ${e.toString()}';
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

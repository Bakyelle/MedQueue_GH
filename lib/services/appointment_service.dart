import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/appointment_model.dart';
import '../utils/app_dummy_data.dart';

class AppointmentService extends ChangeNotifier {
  final List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _errorMessage;

  AppointmentService() {
    _initializeDummyData();
  }

  void _initializeDummyData() {
    for (var apt in AppDummyData.appointmentsList) {
      _appointments.add(
        Appointment(
          id: apt['id'],
          patientId: '0',
          patientName: apt['patientName'],
          doctorId: apt['doctorId'] ?? '1',
          doctorName: apt['doctorName'],
          specialization: apt['specialization'],
          appointmentDate: DateTime.parse(apt['date']),
          appointmentTime: apt['time'],
          reason: apt['reason'],
          status: AppointmentStatus.values.byName(apt['status']),
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Appointment> get upcomingAppointments =>
      _appointments.where((a) => a.isUpcoming && a.status != AppointmentStatus.cancelled).toList();

  List<Appointment> get pastAppointments =>
      _appointments.where((a) => a.isPast || a.status == AppointmentStatus.completed).toList();

  // Get doctors list
  Future<List<Map<String, dynamic>>> getDoctors() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));
      _isLoading = false;
      notifyListeners();
      return AppDummyData.doctorsList;
    } catch (e) {
      _errorMessage = 'Failed to fetch doctors: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Book appointment
  Future<bool> bookAppointment({
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required String specialization,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));

      final newAppointment = Appointment(
        id: const Uuid().v4(),
        patientId: patientId,
        patientName: patientName,
        doctorId: doctorId,
        doctorName: doctorName,
        specialization: specialization,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
        reason: reason,
        status: AppointmentStatus.scheduled,
        createdAt: DateTime.now(),
      );

      _appointments.add(newAppointment);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to book appointment: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cancel appointment
  Future<bool> cancelAppointment(String appointmentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        final updatedAppointment = _appointments[index];
        _appointments[index] = Appointment(
          id: updatedAppointment.id,
          patientId: updatedAppointment.patientId,
          patientName: updatedAppointment.patientName,
          doctorId: updatedAppointment.doctorId,
          doctorName: updatedAppointment.doctorName,
          specialization: updatedAppointment.specialization,
          appointmentDate: updatedAppointment.appointmentDate,
          appointmentTime: updatedAppointment.appointmentTime,
          reason: updatedAppointment.reason,
          status: AppointmentStatus.cancelled,
          createdAt: updatedAppointment.createdAt,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to cancel appointment: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reschedule appointment
  Future<bool> rescheduleAppointment(
    String appointmentId,
    DateTime newDate,
    String newTime,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));

      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        final updatedAppointment = _appointments[index];
        _appointments[index] = Appointment(
          id: updatedAppointment.id,
          patientId: updatedAppointment.patientId,
          patientName: updatedAppointment.patientName,
          doctorId: updatedAppointment.doctorId,
          doctorName: updatedAppointment.doctorName,
          specialization: updatedAppointment.specialization,
          appointmentDate: newDate,
          appointmentTime: newTime,
          reason: updatedAppointment.reason,
          status: AppointmentStatus.scheduled,
          createdAt: updatedAppointment.createdAt,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to reschedule appointment: ${e.toString()}';
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

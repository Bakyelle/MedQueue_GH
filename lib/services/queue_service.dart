import 'package:flutter/foundation.dart';
import '../models/queue_model.dart';
import '../utils/app_dummy_data.dart';

class QueueService extends ChangeNotifier {
  final List<QueueEntry> _queueEntries = [];
  bool _isLoading = false;
  String? _errorMessage;

  QueueService() {
    _initializeDummyData();
  }

  void _initializeDummyData() {
    int counter = 1;
    for (var entry in AppDummyData.queueEntries) {
      _queueEntries.add(
        QueueEntry(
          id: entry['id'],
          appointmentId: 'apt_${entry['id']}',
          patientId: 'pat_${entry['id']}',
          patientName: entry['patientName'],
          doctorId: '1',
          doctorName: entry['doctorName'],
          queueNumber: entry['queueNumber'],
          estimatedWaitTime: entry['estimatedWait'],
          status: QueueStatus.values.byName(entry['status']),
          joinedAt: DateTime.now().subtract(Duration(minutes: counter * 15)),
        ),
      );
      counter++;
    }
  }

  List<QueueEntry> get queueEntries => _queueEntries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get patient's queue position
  Future<QueueEntry?> getPatientQueuePosition(String patientId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      final entry = _queueEntries.firstWhere(
        (q) => q.patientId == patientId && q.status != QueueStatus.completed,
        orElse: () => QueueEntry(
          id: '',
          appointmentId: '',
          patientId: '',
          patientName: '',
          doctorId: '',
          doctorName: '',
          queueNumber: 0,
          estimatedWaitTime: 0,
          status: QueueStatus.cancelled,
          joinedAt: DateTime.now(),
        ),
      );

      _isLoading = false;
      notifyListeners();
      return entry.id.isNotEmpty ? entry : null;
    } catch (e) {
      _errorMessage = 'Failed to fetch queue position: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Join virtual queue
  Future<bool> joinVirtualQueue(
    String patientId,
    String patientName,
    String appointmentId,
    String doctorId,
    String doctorName,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));

      final queueNumber = _queueEntries.isEmpty
          ? 1
          : _queueEntries.map((q) => q.queueNumber).reduce((a, b) => a > b ? a : b) + 1;

      final newEntry = QueueEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        appointmentId: appointmentId,
        patientId: patientId,
        patientName: patientName,
        doctorId: doctorId,
        doctorName: doctorName,
        queueNumber: queueNumber,
        estimatedWaitTime: queueNumber * 15,
        status: QueueStatus.waiting,
        joinedAt: DateTime.now(),
      );

      _queueEntries.add(newEntry);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to join queue: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get all queue entries for a doctor
  Future<List<QueueEntry>> getQueueForDoctor(String doctorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      final doctorQueue = _queueEntries
          .where((q) => q.doctorId == doctorId && q.status != QueueStatus.completed)
          .toList();

      _isLoading = false;
      notifyListeners();
      return doctorQueue;
    } catch (e) {
      _errorMessage = 'Failed to fetch queue: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Mark patient as completed
  Future<bool> completePatient(String queueEntryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      final index = _queueEntries.indexWhere((q) => q.id == queueEntryId);
      if (index != -1) {
        final entry = _queueEntries[index];
        _queueEntries[index] = QueueEntry(
          id: entry.id,
          appointmentId: entry.appointmentId,
          patientId: entry.patientId,
          patientName: entry.patientName,
          doctorId: entry.doctorId,
          doctorName: entry.doctorName,
          queueNumber: entry.queueNumber,
          estimatedWaitTime: entry.estimatedWaitTime,
          status: QueueStatus.completed,
          joinedAt: entry.joinedAt,
          completedAt: DateTime.now(),
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to complete patient: ${e.toString()}';
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

enum QueueStatus { waiting, inProgress, completed, cancelled }

class QueueEntry {
  final String id;
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final int queueNumber;
  final int estimatedWaitTime; // in minutes
  final QueueStatus status;
  final DateTime joinedAt;
  final DateTime? completedAt;

  QueueEntry({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.queueNumber,
    required this.estimatedWaitTime,
    required this.status,
    required this.joinedAt,
    this.completedAt,
  });

  int get positionInQueue => queueNumber;
  
  int getRemainingWaitTime() {
    final elapsed = DateTime.now().difference(joinedAt).inMinutes;
    return (estimatedWaitTime - elapsed).clamp(0, estimatedWaitTime);
  }
}

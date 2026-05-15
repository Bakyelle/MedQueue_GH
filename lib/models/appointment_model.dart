enum AppointmentStatus { scheduled, completed, cancelled, noShow, inProgress }

class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String specialization;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String reason;
  final AppointmentStatus status;
  final String? notes;
  final DateTime createdAt;

  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.specialization,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.reason,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  bool get isPast => appointmentDate.isBefore(DateTime.now());
  bool get isToday => appointmentDate.day == DateTime.now().day &&
      appointmentDate.month == DateTime.now().month &&
      appointmentDate.year == DateTime.now().year;
  bool get isUpcoming => appointmentDate.isAfter(DateTime.now());
}

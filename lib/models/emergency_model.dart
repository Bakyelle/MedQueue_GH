enum EmergencyStatus { pending, acknowledged, onWay, resolved }

class EmergencyRequest {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final double? latitude;
  final double? longitude;
  final String description;
  final EmergencyStatus status;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final String? assignedAmbulanceId;
  final String? assignedStaffName;

  EmergencyRequest({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    this.latitude,
    this.longitude,
    required this.description,
    required this.status,
    required this.createdAt,
    this.acknowledgedAt,
    this.assignedAmbulanceId,
    this.assignedStaffName,
  });

  bool get isActive => status == EmergencyStatus.pending || 
                       status == EmergencyStatus.acknowledged ||
                       status == EmergencyStatus.onWay;
}

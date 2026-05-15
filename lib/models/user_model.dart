// User base model
enum UserRole { patient, doctor, admin }

class User {
  final String id;
  final String email;
  final String password;
  final String fullName;
  final String phone;
  final UserRole role;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.createdAt,
  });

  // For JSON serialization when backend is ready
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'phone': phone,
    'role': role.toString(),
    'createdAt': createdAt.toIso8601String(),
  };
}

// Patient specific model
class Patient extends User {
  final String? dateOfBirth;
  final String? bloodType;
  final String? emergencyContact;
  final String? emergencyPhone;
  final List<String> medicalHistory;

  Patient({
    required String id,
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required DateTime createdAt,
    this.dateOfBirth,
    this.bloodType,
    this.emergencyContact,
    this.emergencyPhone,
    this.medicalHistory = const [],
  }) : super(
    id: id,
    email: email,
    password: password,
    fullName: fullName,
    phone: phone,
    role: UserRole.patient,
    createdAt: createdAt,
  );
}

// Doctor specific model
class Doctor extends User {
  final String specialization;
  final String? medicalLicense;
  final double? rating;
  final int? yearsOfExperience;
  final String? bio;
  final List<String> availableDays;
  final String? startTime;
  final String? endTime;
  final bool isAvailable;

  Doctor({
    required String id,
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required this.specialization,
    required DateTime createdAt,
    this.medicalLicense,
    this.rating = 4.5,
    this.yearsOfExperience = 5,
    this.bio,
    this.availableDays = const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
    this.startTime = '09:00 AM',
    this.endTime = '05:00 PM',
    this.isAvailable = true,
  }) : super(
    id: id,
    email: email,
    password: password,
    fullName: fullName,
    phone: phone,
    role: UserRole.doctor,
    createdAt: createdAt,
  );
}

// Admin specific model
class Admin extends User {
  final String department;
  final String? permissions;

  Admin({
    required String id,
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required this.department,
    required DateTime createdAt,
    this.permissions,
  }) : super(
    id: id,
    email: email,
    password: password,
    fullName: fullName,
    phone: phone,
    role: UserRole.admin,
    createdAt: createdAt,
  );
}

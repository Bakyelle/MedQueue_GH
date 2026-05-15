import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_cards.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_components.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({Key? key}) : super(key: key);

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('MedQueue GH'),
        centerTitle: true,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.of(context).pushNamed('/patient-notifications');
                },
              ),
              Consumer<NotificationService>(
                builder: (context, notificationService, _) {
                  final unreadCount = notificationService.unreadCount;
                  if (unreadCount > 0) {
                    return Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.emergencyRed,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
      ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHome();
      case 1:
        return _buildAppointments();
      case 2:
        return _buildChat();
      case 3:
        return _buildProfile();
      default:
        return _buildHome();
    }
  }

  Widget _buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Consumer<AuthService>(
            builder: (context, authService, _) {
              final user = authService.currentUser as Patient?;
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.primaryBlue.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user?.fullName ?? "Patient"}!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'How can we help you today?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _QuickActionCard(
                icon: Icons.calendar_today,
                label: 'Book Appointment',
                color: AppColors.primaryBlue,
                onTap: () {
                  Navigator.of(context).pushNamed('/book-appointment');
                },
              ),
              const SizedBox(width: 12),
              _QuickActionCard(
                icon: Icons.line_weight,
                label: 'Queue Status',
                color: AppColors.primaryGreen,
                onTap: () {
                  Navigator.of(context).pushNamed('/queue-tracker');
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _QuickActionCard(
                icon: Icons.local_hospital_outlined,
                label: 'AI Chatbot',
                color: AppColors.warningOrange,
                onTap: () {
                  Navigator.of(context).pushNamed('/patient-chatbot');
                },
              ),
              const SizedBox(width: 12),
              _QuickActionCard(
                icon: Icons.emergency,
                label: 'Emergency SOS',
                color: AppColors.emergencyRed,
                onTap: () {
                  Navigator.of(context).pushNamed('/emergency-sos');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Upcoming Appointments
          const Text(
            'Upcoming Appointments',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Consumer<AppointmentService>(
            builder: (context, appointmentService, _) {
              final upcomingAppointments = appointmentService.upcomingAppointments.take(3).toList();
              if (upcomingAppointments.isEmpty) {
                return EmptyState(
                  icon: Icons.calendar_today,
                  title: 'No Upcoming Appointments',
                  message: 'Book an appointment to get started',
                  action: CustomButton(
                    label: 'Book Now',
                    onPressed: () {
                      Navigator.of(context).pushNamed('/book-appointment');
                    },
                    width: 150,
                  ),
                );
              }
              return Column(
                children: upcomingAppointments.map((apt) {
                  return AppointmentCard(
                    appointmentId: apt.id,
                    doctorName: apt.doctorName,
                    specialization: apt.specialization,
                    date: '${apt.appointmentDate.day}/${apt.appointmentDate.month}/${apt.appointmentDate.year}',
                    time: apt.appointmentTime,
                    reason: apt.reason,
                    status: apt.status.name,
                    onTap: () {},
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppointments() {
    return Consumer<AppointmentService>(
      builder: (context, appointmentService, _) {
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: const TabBar(
                  labelColor: AppColors.primaryBlue,
                  unselectedLabelColor: AppColors.textGray,
                  indicatorColor: AppColors.primaryBlue,
                  tabs: [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Upcoming
                    appointmentService.upcomingAppointments.isEmpty
                        ? EmptyState(
                            icon: Icons.calendar_today,
                            title: 'No Upcoming Appointments',
                            message: 'Book an appointment to get started',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: appointmentService.upcomingAppointments.length,
                            itemBuilder: (context, index) {
                              final apt = appointmentService.upcomingAppointments[index];
                              return AppointmentCard(
                                appointmentId: apt.id,
                                doctorName: apt.doctorName,
                                specialization: apt.specialization,
                                date:
                                    '${apt.appointmentDate.day}/${apt.appointmentDate.month}/${apt.appointmentDate.year}',
                                time: apt.appointmentTime,
                                reason: apt.reason,
                                status: apt.status.name,
                                onReschedule: () {
                                  _showRescheduleDialog(context, apt.id);
                                },
                                onCancel: () {
                                  _showCancelDialog(context, apt.id, appointmentService);
                                },
                                onTap: () {},
                              );
                            },
                          ),
                    // History
                    appointmentService.pastAppointments.isEmpty
                        ? EmptyState(
                            icon: Icons.history,
                            title: 'No Appointment History',
                            message: 'Your completed appointments will appear here',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: appointmentService.pastAppointments.length,
                            itemBuilder: (context, index) {
                              final apt = appointmentService.pastAppointments[index];
                              return AppointmentCard(
                                appointmentId: apt.id,
                                doctorName: apt.doctorName,
                                specialization: apt.specialization,
                                date:
                                    '${apt.appointmentDate.day}/${apt.appointmentDate.month}/${apt.appointmentDate.year}',
                                time: apt.appointmentTime,
                                reason: apt.reason,
                                status: apt.status.name,
                                onTap: () {},
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 80, color: AppColors.textLight),
          const SizedBox(height: 16),
          const Text(
            'AI Health Assistant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get instant health guidance',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 32),
          CustomButton(
            label: 'Start Chat',
            onPressed: () {
              Navigator.of(context).pushNamed('/patient-chatbot');
            },
            width: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final user = authService.currentUser as Patient?;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.fullName ?? 'Patient',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 32),
              // Profile Info
              _ProfileInfoTile(
                label: 'Phone',
                value: user?.phone ?? 'N/A',
              ),
              _ProfileInfoTile(
                label: 'Date of Birth',
                value: user?.dateOfBirth ?? 'N/A',
              ),
              _ProfileInfoTile(
                label: 'Blood Type',
                value: user?.bloodType ?? 'N/A',
              ),
              _ProfileInfoTile(
                label: 'Emergency Contact',
                value: '${user?.emergencyContact} (${user?.emergencyPhone})',
              ),
              const SizedBox(height: 32),
              CustomButton(
                label: 'Edit Profile',
                onPressed: () {},
              ),
              const SizedBox(height: 12),
              OutlineCustomButton(
                label: 'Logout',
                textColor: AppColors.emergencyRed,
                borderColor: AppColors.emergencyRed,
                onPressed: () {
                  _showLogoutDialog(context, authService);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context, String appointmentId, AppointmentService appointmentService) {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Cancel Appointment',
        message: 'Are you sure you want to cancel this appointment?',
        confirmButtonText: 'Cancel Appointment',
        cancelButtonText: 'Keep It',
        confirmButtonColor: AppColors.emergencyRed,
        onConfirm: () async {
          await appointmentService.cancelAppointment(appointmentId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Appointment cancelled')),
            );
          }
        },
      ),
    );
  }

  void _showRescheduleDialog(BuildContext context, String appointmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Appointment'),
        content: const Text('This feature will be available soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Logout',
        message: 'Are you sure you want to logout?',
        confirmButtonText: 'Logout',
        cancelButtonText: 'Cancel',
        confirmButtonColor: AppColors.emergencyRed,
        onConfirm: () async {
          await authService.logout();
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/splash');
          }
        },
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileInfoTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

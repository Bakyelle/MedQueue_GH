import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/queue_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_cards.dart';
import '../../widgets/custom_components.dart';
import '../../models/user_model.dart';

class QueueTrackerScreen extends StatefulWidget {
  const QueueTrackerScreen({Key? key}) : super(key: key);

  @override
  State<QueueTrackerScreen> createState() => _QueueTrackerScreenState();
}

class _QueueTrackerScreenState extends State<QueueTrackerScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final user = authService.currentUser as Patient?;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Queue Status'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<QueueService>(
        builder: (context, queueService, _) {
          return FutureBuilder(
            future: queueService.getPatientQueuePosition(user?.id ?? ''),
            builder: (context, snapshot) {
              if (queueService.isLoading) {
                return const CustomLoadingIndicator(message: 'Loading queue info...');
              }

              final queueEntry = snapshot.data;
              if (queueEntry == null) {
                return EmptyState(
                  icon: Icons.line_weight,
                  title: 'No Queue Entry',
                  message: 'You are not currently in a queue. Book an appointment to join.',
                  action: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/book-appointment');
                    },
                    child: const Text('Book Appointment'),
                  ),
                );
              }

              final remainingWait = queueEntry.getRemainingWaitTime();
              final positionsAhead = (queueEntry.queueNumber - 1).clamp(0, queueEntry.queueNumber);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Queue Number Badge
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '#${queueEntry.queueNumber}',
                          style: const TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(queueEntry.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getStatusColor(queueEntry.status).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        queueEntry.status.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _getStatusColor(queueEntry.status),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Info Cards
                    _InfoCard(
                      label: 'Doctor',
                      value: queueEntry.doctorName,
                      icon: Icons.local_hospital,
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      label: 'Estimated Wait Time',
                      value: '$remainingWait minutes',
                      icon: Icons.schedule,
                      color: AppColors.warningOrange,
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      label: 'Positions Ahead',
                      value: positionsAhead.toString(),
                      icon: Icons.people,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(height: 32),
                    // Queue List
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Current Queue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<QueueService>(
                      builder: (context, qService, _) {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: qService.queueEntries.length,
                          itemBuilder: (context, index) {
                            final entry = qService.queueEntries[index];
                            return QueueCard(
                              queueNumber: entry.queueNumber,
                              patientName: entry.patientName,
                              doctorName: entry.doctorName,
                              estimatedWait: entry.estimatedWaitTime,
                              status: entry.status.name,
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    final statusStr = status.toString().toLowerCase();
    if (statusStr.contains('waiting')) return AppColors.warningOrange;
    if (statusStr.contains('inprogress')) return AppColors.infoBlue;
    if (statusStr.contains('completed')) return AppColors.successGreen;
    return AppColors.textGray;
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppColors.primaryBlue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cardColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: cardColor, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cardColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

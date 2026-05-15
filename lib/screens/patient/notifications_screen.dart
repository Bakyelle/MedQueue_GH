import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_cards.dart';
import '../../widgets/custom_components.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      context.read<NotificationService>().markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, _) {
          return notificationService.notifications.isEmpty
              ? EmptyState(
                  icon: Icons.notifications_off,
                  title: 'No Notifications',
                  message: 'You are all caught up!',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notificationService.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notificationService.notifications[index];
                    return NotificationCard(
                      title: notification.title,
                      message: notification.message,
                      type: notification.type.name,
                      isRead: notification.isRead,
                      onTap: () {
                        notificationService.markAsRead(notification.id);
                      },
                      onDismiss: () {
                        notificationService.deleteNotification(notification.id);
                      },
                    );
                  },
                );
        },
      ),
    );
  }
}

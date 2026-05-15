import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../utils/app_dummy_data.dart';

class NotificationService extends ChangeNotifier {
  final List<Notification> _notifications = [];
  bool _isLoading = false;

  NotificationService() {
    _initializeDummyData();
  }

  void _initializeDummyData() {
    int counter = 0;
    for (var notif in AppDummyData.notificationsList) {
      _notifications.add(
        Notification(
          id: notif['id'],
          userId: '0',
          title: notif['title'],
          message: notif['message'],
          type: NotificationType.values.byName(notif['type']),
          isRead: notif['read'],
          createdAt: DateTime.now().subtract(Duration(hours: counter)),
        ),
      );
      counter++;
    }
  }

  List<Notification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Get unread notifications
  List<Notification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final notification = _notifications[index];
      _notifications[index] = Notification(
        id: notification.id,
        userId: notification.userId,
        title: notification.title,
        message: notification.message,
        type: notification.type,
        isRead: true,
        createdAt: notification.createdAt,
        actionUrl: notification.actionUrl,
        metadata: notification.metadata,
      );
      notifyListeners();
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        final notification = _notifications[i];
        _notifications[i] = Notification(
          id: notification.id,
          userId: notification.userId,
          title: notification.title,
          message: notification.message,
          type: notification.type,
          isRead: true,
          createdAt: notification.createdAt,
          actionUrl: notification.actionUrl,
          metadata: notification.metadata,
        );
      }
    }
    notifyListeners();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  // Add new notification (for internal use)
  void addNotification(Notification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }
}

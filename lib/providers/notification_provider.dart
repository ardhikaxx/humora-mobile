import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../data/models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get allNotifications => _notifications;
  bool get isLoading => _isLoading;

  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  int get unreadCount => unreadNotifications.length;

  NotificationProvider() {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.getNotifications();
      if (res.data != null && res.data['data'] != null && res.data['data']['notifications'] is List) {
        _notifications = (res.data['data']['notifications'] as List)
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {} finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();

      final notifIdInt = int.tryParse(id);
      if (notifIdInt != null) {
        try {
          await _api.markNotificationAsRead(notifIdInt);
        } catch (_) {}
      }
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    try {
      await _api.markAllNotificationsAsRead();
    } catch (_) {}
  }
}

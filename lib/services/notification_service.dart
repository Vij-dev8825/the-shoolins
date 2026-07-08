import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';

class NotificationService extends ChangeNotifier {
  static const _key = 'app_notifications';

  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored != null) {
      final decoded = jsonDecode(stored) as List;
      _notifications = decoded
          .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      _notifications = [
        AppNotification(
          id: 'welcome',
          type: NotificationType.welcome,
          title: 'Welcome to The Shoolins',
          message: 'Discover considered essentials in quiet colours. Happy shopping!',
          createdAt: DateTime.now(),
        ),
      ];
      await _persist();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> add({
    required NotificationType type,
    required String title,
    required String message,
  }) async {
    _notifications.insert(
      0,
      AppNotification(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: type,
        title: title,
        message: message,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    await _persist();
  }

  Future<void> markAllAsRead() async {
    if (_notifications.every((n) => n.read)) return;
    _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_notifications.map((n) => n.toJson()).toList()));
  }
}

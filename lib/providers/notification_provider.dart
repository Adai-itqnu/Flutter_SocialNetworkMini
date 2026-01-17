import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import '../services/firestore_service.dart';
import '../utils/app_logger.dart';

/// Provider quản lý thông báo
class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestoreService = FirestoreService();

  List<NotificationModel> _notifications = [];           // Danh sách thông báo
  final Map<String, UserModel> _notificationUsers = {};  // Cache thông tin user
  int _unreadCount = 0;                                  // Số thông báo chưa đọc
  final bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;                           // Tránh init trùng
  String? _currentUserId;

  StreamSubscription<List<NotificationModel>>? _notificationSubscription;
  StreamSubscription<int>? _unreadCountSubscription;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  Map<String, UserModel> get notificationUsers => _notificationUsers;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Khởi tạo stream thông báo
  void initializeNotificationStream(String userId) {
    // Tránh init trùng cho cùng user
    if (_isInitialized && _currentUserId == userId) {
      AppLogger.info('[NotificationProvider] Already initialized for user: $userId');
      return;
    }

    AppLogger.info('[NotificationProvider] Initializing for user: $userId');
    
    // Hủy subscriptions cũ
    _notificationSubscription?.cancel();
    _unreadCountSubscription?.cancel();

    _currentUserId = userId;
    _isInitialized = true;

    // Lắng nghe thông báo
    _notificationSubscription = _notificationService
        .getNotificationsStream(userId)
        .listen(
          (List<NotificationModel> loadedNotifications) async {
            AppLogger.info(
              '[NotificationProvider] Received ${loadedNotifications.length} notifications',
            );
            _notifications = loadedNotifications;
            notifyListeners();

            // Tải thông tin user
            await _loadNotificationUsers();
          },
          onError: (error) {
            AppLogger.error('[NotificationProvider] Error', error: error);
            _error = error.toString();
            notifyListeners();
          },
        );

    // Lắng nghe số chưa đọc
    _unreadCountSubscription = _notificationService
        .getUnreadCountStream(userId)
        .listen(
          (count) {
            AppLogger.info('[NotificationProvider] Unread count: $count');
            _unreadCount = count;
            notifyListeners();
          },
          onError: (error) {
            AppLogger.error('[NotificationProvider] Unread count error', error: error);
          },
        );
  }

  // Tải thông tin user của tất cả người gửi notification
  Future<void> _loadNotificationUsers() async {
    final missingUserIds = _notifications
        .map((n) => n.fromUserId)
        .where((uid) => !_notificationUsers.containsKey(uid))
        .toSet();

    if (missingUserIds.isEmpty) return;

    try {
      final results = await Future.wait(
        missingUserIds.map((uid) => _firestoreService.getUser(uid)),
      );

      for (int i = 0; i < missingUserIds.length; i++) {
        final user = results[i];
        final uid = missingUserIds.elementAt(i);
        if (user != null) {
          _notificationUsers[uid] = user;
        }
      }

      notifyListeners();
    } catch (e) {
      AppLogger.error('Lỗi tải thông tin người dùng', error: e);
    }
  }

  // Lấy thông tin user từ notification
  UserModel? getNotificationUser(String userId) {
    return _notificationUsers[userId];
  }

  // Đánh dấu 1 thông báo đã đọc
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      // Optimistic update
      final index = _notifications.indexWhere(
        (n) => n.notificationId == notificationId,
      );
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Đánh dấu tất cả đã đọc
  Future<void> markAllAsRead(String userId) async {
    try {
      await _notificationService.markAllAsRead(userId);

      // Update local state
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Xóa 1 thông báo
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);

      // Remove from local state
      _notifications.removeWhere((n) => n.notificationId == notificationId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Xóa tất cả thông báo
  Future<void> deleteAllNotifications(String userId) async {
    try {
      await _notificationService.deleteAllNotifications(userId);

      // Clear local state
      _notifications.clear();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Xóa dữ liệu (khi logout)
  void clear() {
    _notificationSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    _notifications.clear();
    _notificationUsers.clear();
    _unreadCount = 0;
    _error = null;
    _isInitialized = false;
    _currentUserId = null;
    notifyListeners();
  }

  // Xóa lỗi
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    super.dispose();
  }
}

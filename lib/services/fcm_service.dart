import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';
import 'active_chat_service.dart';

/// Service Firebase Cloud Messaging cho push notifications (Android)
/// Bao gồm: khởi tạo FCM, xử lý tin nhắn, lưu token
class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static bool _initialized = false;

  // Khởi tạo FCM - gọi trong main.dart sau Firebase.initializeApp()
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Yêu cầu quyền
      final settings = await _messaging.requestPermission(alert: true, badge: true, sound: true, provisional: false);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.info('[FCM] Permission granted');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        AppLogger.info('[FCM] Provisional permission granted');
      } else {
        AppLogger.warn('[FCM] Permission denied');
        return;
      }

      // Khởi tạo local notifications
      await _initializeLocalNotifications();

      // Lấy FCM token
      try {
        final token = await _messaging.getToken();
        AppLogger.info('[FCM] Token: $token');
      } catch (e) {
        AppLogger.error('[FCM] Error getting token', error: e);
      }

      // Lắng nghe token refresh
      _messaging.onTokenRefresh.listen((newToken) => AppLogger.info('[FCM] Token refreshed: $newToken'));

      // Xử lý foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Xử lý notification tap khi app ở background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Kiểm tra app được mở từ notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) _handleNotificationTap(initialMessage);

      AppLogger.info('[FCM] Initialization complete');
    } catch (e) {
      AppLogger.error('[FCM] Initialization error (app will continue)', error: e);
    }
  }

  // Khởi tạo local notifications
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(initSettings, onDidReceiveNotificationResponse: (response) {
      AppLogger.info('[FCM] Local notification tapped: ${response.payload}');
    });

    // Tạo Android notification channel
    const androidChannel = AndroidNotificationChannel('high_importance_channel', 'High Importance Notifications', description: 'This channel is used for important notifications.', importance: Importance.max);
    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(androidChannel);
  }

  // Xử lý foreground messages - hiện local notification
  // Bỏ qua notification nếu user đang xem chat đó
  static void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info('[FCM] Foreground message received: ${message.messageId}');

    final notification = message.notification;
    if (notification == null) return;

    // Kiểm tra có đang xem chat này không
    final chatId = message.data['chatId'];
    if (chatId != null && ActiveChatService.isChatActive(chatId)) {
      AppLogger.info('[FCM] Skipping notification - user is viewing this chat');
      return;
    }

    _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'Thông báo mới',
      notification.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails('high_importance_channel', 'High Importance Notifications', channelDescription: 'This channel is used for important notifications.', importance: Importance.max, priority: Priority.high, icon: '@mipmap/ic_launcher'),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
      payload: message.data['chatId'],
    );
  }

  // Xử lý notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    AppLogger.info('[FCM] Notification tapped: ${message.data}');
  }

  // Lưu FCM token cho user
  static Future<void> saveTokenForUser(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({'fcmToken': token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()});
        AppLogger.info('[FCM] Token saved for user: $userId');
      }
    } catch (e) {
      AppLogger.error('[FCM] Error saving token', error: e);
    }
  }

  // Xóa FCM token khi user đăng xuất
  static Future<void> removeTokenForUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({'fcmToken': FieldValue.delete(), 'fcmTokenUpdatedAt': FieldValue.delete()});
      AppLogger.info('[FCM] Token removed for user: $userId');
    } catch (e) {
      AppLogger.error('[FCM] Error removing token', error: e);
    }
  }

  // Lấy FCM token hiện tại
  static Future<String?> getToken() async => await _messaging.getToken();
}

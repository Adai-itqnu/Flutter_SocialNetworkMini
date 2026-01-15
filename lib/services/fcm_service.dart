import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';
import 'active_chat_service.dart';

/// Firebase Cloud Messaging Service for push notifications (Android only)
class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static bool _initialized = false;

  /// Initialize FCM - call this in main.dart after Firebase.initializeApp()
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.info('[FCM] Permission granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        AppLogger.info('[FCM] Provisional permission granted');
      } else {
        AppLogger.warn('[FCM] Permission denied');
        return;
      }

      // Initialize local notifications for foreground messages
      await _initializeLocalNotifications();

      // Get FCM token
      try {
        final token = await _messaging.getToken();
        AppLogger.info('[FCM] Token: $token');
      } catch (e) {
        AppLogger.error('[FCM] Error getting token', error: e);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        AppLogger.info('[FCM] Token refreshed: $newToken');
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      AppLogger.info('[FCM] Initialization complete');
    } catch (e) {
      AppLogger.error(
        '[FCM] Initialization error (app will continue)',
        error: e,
      );
    }
  }

  /// Initialize local notifications for showing notifications when app is in foreground
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        AppLogger.info('[FCM] Local notification tapped: ${response.payload}');
      },
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Handle foreground messages - show local notification
  /// Skip notification if user is currently viewing the chat
  static void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info('[FCM] Foreground message received: ${message.messageId}');

    final notification = message.notification;
    if (notification == null) return;

    // Check if user is currently viewing this chat - don't show notification
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
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['chatId'],
    );
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    AppLogger.info('[FCM] Notification tapped: ${message.data}');
    // TODO: Navigate to appropriate screen based on message data
  }

  /// Save FCM token to Firestore for a user
  static Future<void> saveTokenForUser(String userId) async {
    try {
      final token = await _messaging.getToken();

      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        AppLogger.info('[FCM] Token saved for user: $userId');
      }
    } catch (e) {
      AppLogger.error('[FCM] Error saving token', error: e);
    }
  }

  /// Remove FCM token when user logs out
  static Future<void> removeTokenForUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });
      AppLogger.info('[FCM] Token removed for user: $userId');
    } catch (e) {
      AppLogger.error('[FCM] Error removing token', error: e);
    }
  }

  /// Get current FCM token
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}

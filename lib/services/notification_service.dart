import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../utils/app_logger.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _notificationsRef =>
      _firestore.collection('notifications');

  // ==================== CREATE NOTIFICATIONS ====================

  /// Create a new notification
  Future<String> createNotification({
    required String fromUserId,
    required String toUserId,
    required NotificationType type,
    String? postId,
    String? commentText,
  }) async {
    // Không tạo notification cho chính mình
    if (fromUserId == toUserId) {
      return '';
    }

    try {
      final notificationRef = _notificationsRef.doc();

      final notification = NotificationModel(
        notificationId: notificationRef.id,
        fromUserId: fromUserId,
        toUserId: toUserId,
        type: type,
        postId: postId,
        commentText: commentText,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await notificationRef.set(notification.toJson());
      return notificationRef.id;
    } catch (e) {
      throw Exception('Lỗi khi tạo thông báo: $e');
    }
  }

  /// Create like notification
  Future<void> createLikeNotification({
    required String fromUserId,
    required String postOwnerId,
    required String postId,
  }) async {
    await createNotification(
      fromUserId: fromUserId,
      toUserId: postOwnerId,
      type: NotificationType.like,
      postId: postId,
    );
  }

  /// Create comment notification
  Future<void> createCommentNotification({
    required String fromUserId,
    required String postOwnerId,
    required String postId,
    required String commentText,
  }) async {
    await createNotification(
      fromUserId: fromUserId,
      toUserId: postOwnerId,
      type: NotificationType.comment,
      postId: postId,
      commentText: commentText,
    );
  }

  /// Create follow notification
  Future<void> createFollowNotification({
    required String fromUserId,
    required String toUserId,
  }) async {
    await createNotification(
      fromUserId: fromUserId,
      toUserId: toUserId,
      type: NotificationType.follow,
    );
  }

  /// Create share notification
  Future<void> createShareNotification({
    required String fromUserId,
    required String postOwnerId,
    required String postId,
  }) async {
    await createNotification(
      fromUserId: fromUserId,
      toUserId: postOwnerId,
      type: NotificationType.share,
      postId: postId,
    );
  }

  /// Create new post notification for all followers
  Future<void> createNewPostNotificationForFollowers({
    required String postAuthorId,
    required String postId,
  }) async {
    try {
      // Lấy tất cả followers của post author
      final followersSnapshot = await _firestore
          .collection('followers')
          .where('followingId', isEqualTo: postAuthorId)
          .get();

      // Tạo notification cho từng follower
      final batch = _firestore.batch();

      for (final doc in followersSnapshot.docs) {
        final followerId = doc.data()['followerId'] as String;
        final notificationRef = _notificationsRef.doc();

        final notification = NotificationModel(
          notificationId: notificationRef.id,
          fromUserId: postAuthorId,
          toUserId: followerId,
          type: NotificationType.newPost,
          postId: postId,
          createdAt: DateTime.now(),
        );

        batch.set(notificationRef, notification.toJson());
      }

      await batch.commit();
    } catch (e) {
      AppLogger.error('Lỗi khi tạo thông báo bài viết mới', error: e);
    }
  }

  // ==================== READ NOTIFICATIONS ====================

  /// Get notifications stream for a user (real-time)
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _notificationsRef
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
          // Sort client-side to avoid requiring composite indexes
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          // Limit to 50 most recent
          return notifications.take(50).toList();
        });
  }

  /// Get unread notification count stream
  Stream<int> getUnreadCountStream(String userId) {
    return _notificationsRef
        .where('toUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get unread count (one-time)
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _notificationsRef
          .where('toUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // ==================== UPDATE NOTIFICATIONS ====================

  /// Mark single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).update({'isRead': true});
    } catch (e) {
      throw Exception('Lỗi khi đánh dấu đã đọc: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _notificationsRef
          .where('toUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Lỗi khi đánh dấu tất cả đã đọc: $e');
    }
  }

  // ==================== DELETE NOTIFICATIONS ====================

  /// Delete a single notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).delete();
    } catch (e) {
      throw Exception('Lỗi khi xóa thông báo: $e');
    }
  }

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final snapshot = await _notificationsRef
          .where('toUserId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Lỗi khi xóa tất cả thông báo: $e');
    }
  }

  /// Remove duplicate notification (e.g., when user unlikes then likes again)
  Future<void> removeDuplicateNotification({
    required String fromUserId,
    required String toUserId,
    required NotificationType type,
    String? postId,
  }) async {
    try {
      Query query = _notificationsRef
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId)
          .where('type', isEqualTo: NotificationModel.typeToString(type));

      if (postId != null) {
        query = query.where('postId', isEqualTo: postId);
      }

      final snapshot = await query.get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      AppLogger.error('Lỗi khi xóa notification trùng', error: e);
    }
  }
}

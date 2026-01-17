import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../utils/app_logger.dart';

/// Service xử lý thông báo
/// Bao gồm: tạo, đọc, đánh dấu đã đọc, xóa thông báo
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _notificationsRef => _firestore.collection('notifications');

  // Tạo thông báo

  // Tạo thông báo mới
  Future<String> createNotification({required String fromUserId, required String toUserId, required NotificationType type, String? postId, String? commentText}) async {
    if (fromUserId == toUserId) return ''; // Không tạo notification cho chính mình

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

  // Tạo thông báo like
  Future<void> createLikeNotification({required String fromUserId, required String postOwnerId, required String postId}) async {
    await createNotification(fromUserId: fromUserId, toUserId: postOwnerId, type: NotificationType.like, postId: postId);
  }

  // Tạo thông báo comment
  Future<void> createCommentNotification({required String fromUserId, required String postOwnerId, required String postId, required String commentText}) async {
    await createNotification(fromUserId: fromUserId, toUserId: postOwnerId, type: NotificationType.comment, postId: postId, commentText: commentText);
  }

  // Tạo thông báo follow
  Future<void> createFollowNotification({required String fromUserId, required String toUserId}) async {
    await createNotification(fromUserId: fromUserId, toUserId: toUserId, type: NotificationType.follow);
  }

  // Tạo thông báo share
  Future<void> createShareNotification({required String fromUserId, required String postOwnerId, required String postId}) async {
    await createNotification(fromUserId: fromUserId, toUserId: postOwnerId, type: NotificationType.share, postId: postId);
  }

  // Tạo thông báo bài viết mới cho tất cả followers
  Future<void> createNewPostNotificationForFollowers({required String postAuthorId, required String postId}) async {
    try {
      final followersSnapshot = await _firestore.collection('followers').where('followingId', isEqualTo: postAuthorId).get();
      final batch = _firestore.batch();

      for (final doc in followersSnapshot.docs) {
        final followerId = doc.data()['followerId'] as String;
        final notificationRef = _notificationsRef.doc();
        final notification = NotificationModel(notificationId: notificationRef.id, fromUserId: postAuthorId, toUserId: followerId, type: NotificationType.newPost, postId: postId, createdAt: DateTime.now());
        batch.set(notificationRef, notification.toJson());
      }

      await batch.commit();
    } catch (e) {
      AppLogger.error('Lỗi khi tạo thông báo bài viết mới', error: e);
    }
  }

  // Đọc thông báo

  // Stream thông báo của user (realtime)
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _notificationsRef.where('toUserId', isEqualTo: userId).snapshots().map((snapshot) {
      final notifications = snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications.take(50).toList();
    });
  }

  // Stream số thông báo chưa đọc
  Stream<int> getUnreadCountStream(String userId) {
    return _notificationsRef.where('toUserId', isEqualTo: userId).where('isRead', isEqualTo: false).snapshots().map((snapshot) => snapshot.docs.length);
  }

  // Lấy số thông báo chưa đọc (1 lần)
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _notificationsRef.where('toUserId', isEqualTo: userId).where('isRead', isEqualTo: false).get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Cập nhật thông báo

  // Đánh dấu 1 thông báo đã đọc
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).update({'isRead': true});
    } catch (e) {
      throw Exception('Lỗi khi đánh dấu đã đọc: $e');
    }
  }

  // Đánh dấu tất cả đã đọc
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _notificationsRef.where('toUserId', isEqualTo: userId).where('isRead', isEqualTo: false).get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) batch.update(doc.reference, {'isRead': true});
      await batch.commit();
    } catch (e) {
      throw Exception('Lỗi khi đánh dấu tất cả đã đọc: $e');
    }
  }

  // Xóa thông báo

  // Xóa 1 thông báo
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).delete();
    } catch (e) {
      throw Exception('Lỗi khi xóa thông báo: $e');
    }
  }

  // Xóa tất cả thông báo của user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final snapshot = await _notificationsRef.where('toUserId', isEqualTo: userId).get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) batch.delete(doc.reference);
      await batch.commit();
    } catch (e) {
      throw Exception('Lỗi khi xóa tất cả thông báo: $e');
    }
  }

  // Xóa thông báo trùng (vd: unlike rồi like lại)
  Future<void> removeDuplicateNotification({required String fromUserId, required String toUserId, required NotificationType type, String? postId}) async {
    try {
      Query query = _notificationsRef.where('fromUserId', isEqualTo: fromUserId).where('toUserId', isEqualTo: toUserId).where('type', isEqualTo: NotificationModel.typeToString(type));
      if (postId != null) query = query.where('postId', isEqualTo: postId);

      final snapshot = await query.get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) batch.delete(doc.reference);
      await batch.commit();
    } catch (e) {
      AppLogger.error('Lỗi khi xóa notification trùng', error: e);
    }
  }
}

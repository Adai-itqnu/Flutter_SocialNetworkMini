import 'package:cloud_firestore/cloud_firestore.dart';

/// Service xử lý các operations liên quan đến Follow
class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Follow a user
  Future<void> followUser(String followerId, String followingId) async {
    try {
      final followRef = _firestore
          .collection('followers')
          .doc('${followerId}_$followingId');

      // Check if already following
      final followDoc = await followRef.get();
      if (followDoc.exists) {
        return; // Already following
      }

      // Create follow document
      await followRef.set({
        'followerId': followerId,
        'followingId': followingId,
        'createdAt': Timestamp.now(),
      });

      // Update follower's following count
      await _firestore.collection('users').doc(followerId).update({
        'followingCount': FieldValue.increment(1),
      });

      // Update following's followers count
      await _firestore.collection('users').doc(followingId).update({
        'followersCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Lỗi khi follow: $e');
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String followerId, String followingId) async {
    try {
      final followRef = _firestore
          .collection('followers')
          .doc('${followerId}_$followingId');

      final followDoc = await followRef.get();
      if (!followDoc.exists) {
        return; // Not following
      }

      await followRef.delete();

      await _firestore.collection('users').doc(followerId).update({
        'followingCount': FieldValue.increment(-1),
      });

      await _firestore.collection('users').doc(followingId).update({
        'followersCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Lỗi khi unfollow: $e');
    }
  }

  /// Check if user is following another user
  Future<bool> isFollowing(String followerId, String followingId) async {
    try {
      final followDoc = await _firestore
          .collection('followers')
          .doc('${followerId}_$followingId')
          .get();
      return followDoc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get list of followers for a user
  Future<List<String>> getFollowers(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('followers')
          .where('followingId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['followerId'] as String)
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách người theo dõi: $e');
    }
  }

  /// Get list of users that a user is following
  Future<List<String>> getFollowing(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('followers')
          .where('followerId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['followingId'] as String)
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách đang theo dõi: $e');
    }
  }
}

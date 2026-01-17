import 'package:cloud_firestore/cloud_firestore.dart';

/// Service xử lý Follow
/// Bao gồm: follow, unfollow, kiểm tra trạng thái follow
class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Follow user
  Future<void> followUser(String followerId, String followingId) async {
    try {
      final followRef = _firestore.collection('followers').doc('${followerId}_$followingId');
      final followDoc = await followRef.get();
      if (followDoc.exists) return;

      await followRef.set({'followerId': followerId, 'followingId': followingId, 'createdAt': Timestamp.now()});
      await _firestore.collection('users').doc(followerId).update({'followingCount': FieldValue.increment(1)});
      await _firestore.collection('users').doc(followingId).update({'followersCount': FieldValue.increment(1)});
    } catch (e) {
      throw Exception('Lỗi khi follow: $e');
    }
  }

  // Unfollow user
  Future<void> unfollowUser(String followerId, String followingId) async {
    try {
      final followRef = _firestore.collection('followers').doc('${followerId}_$followingId');
      final followDoc = await followRef.get();
      if (!followDoc.exists) return;

      await followRef.delete();
      await _firestore.collection('users').doc(followerId).update({'followingCount': FieldValue.increment(-1)});
      await _firestore.collection('users').doc(followingId).update({'followersCount': FieldValue.increment(-1)});
    } catch (e) {
      throw Exception('Lỗi khi unfollow: $e');
    }
  }

  // Kiểm tra đã follow chưa
  Future<bool> isFollowing(String followerId, String followingId) async {
    try {
      final doc = await _firestore.collection('followers').doc('${followerId}_$followingId').get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Lấy danh sách followers
  Future<List<String>> getFollowers(String userId) async {
    try {
      final snapshot = await _firestore.collection('followers').where('followingId', isEqualTo: userId).get();
      return snapshot.docs.map((doc) => doc.data()['followerId'] as String).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách người theo dõi: $e');
    }
  }

  // Lấy danh sách đang following
  Future<List<String>> getFollowing(String userId) async {
    try {
      final snapshot = await _firestore.collection('followers').where('followerId', isEqualTo: userId).get();
      return snapshot.docs.map((doc) => doc.data()['followingId'] as String).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách đang theo dõi: $e');
    }
  }
}

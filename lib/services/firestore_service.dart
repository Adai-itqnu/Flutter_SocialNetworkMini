import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USER OPERATIONS ====================

  // Get user by ID
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi khi lấy thông tin user: $e');
    }
  }

  // Update user profile
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật profile: $e');
    }
  }

  // ==================== POST OPERATIONS ====================

  // Create new post
  Future<String> createPost({
    required String userId,
    required String caption,
    required List<String> imageUrls,
  }) async {
    try {
      final now = DateTime.now();
      final postRef = _firestore.collection('posts').doc();

      PostModel newPost = PostModel(
        postId: postRef.id,
        userId: userId,
        caption: caption,
        imageUrls: imageUrls,
        createdAt: now,
        updatedAt: now,
      );

      await postRef.set(newPost.toJson());

      // Increment user's post count
      await _firestore.collection('users').doc(userId).update({
        'postsCount': FieldValue.increment(1),
      });

      return postRef.id;
    } catch (e) {
      throw Exception('Lỗi khi tạo bài viết: $e');
    }
  }

  // Get all posts (feed) - ordered by creation time
  Stream<List<PostModel>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    });
  }

  // Get user's posts
  Stream<List<PostModel>> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    });
  }

  // Delete post
  Future<void> deletePost(String postId, String userId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();

      // Decrement user's post count
      await _firestore.collection('users').doc(userId).update({
        'postsCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Lỗi khi xóa bài viết: $e');
    }
  }

  // ==================== LIKE OPERATIONS ====================

  // Like a post
  Future<void> likePost(String postId, String userId) async {
    try {
      final likeRef = _firestore.collection('likes').doc('${postId}_$userId');

      // Check if already liked
      final likeDoc = await likeRef.get();
      if (likeDoc.exists) {
        return; // Already liked
      }

      // Create like document
      await likeRef.set({
        'postId': postId,
        'userId': userId,
        'createdAt': Timestamp.now(),
      });

      // Increment post's like count
      await _firestore.collection('posts').doc(postId).update({
        'likesCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Lỗi khi thích bài viết: $e');
    }
  }

  // Unlike a post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      final likeRef = _firestore.collection('likes').doc('${postId}_$userId');

      // Check if liked
      final likeDoc = await likeRef.get();
      if (!likeDoc.exists) {
        return; // Not liked
      }

      // Delete like document
      await likeRef.delete();

      // Decrement post's like count
      await _firestore.collection('posts').doc(postId).update({
        'likesCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Lỗi khi bỏ thích bài viết: $e');
    }
  }

  // Check if user liked a post
  Future<bool> hasLikedPost(String postId, String userId) async {
    try {
      final likeDoc =
          await _firestore.collection('likes').doc('${postId}_$userId').get();
      return likeDoc.exists;
    } catch (e) {
      return false;
    }
  }

  // ==================== COMMENT OPERATIONS ====================

  // Add comment to post
  Future<String> addComment({
    required String postId,
    required String userId,
    required String text,
  }) async {
    try {
      final commentRef = _firestore.collection('comments').doc();

      CommentModel newComment = CommentModel(
        commentId: commentRef.id,
        postId: postId,
        userId: userId,
        text: text,
        createdAt: DateTime.now(),
      );

      await commentRef.set(newComment.toJson());

      // Increment post's comment count
      await _firestore.collection('posts').doc(postId).update({
        'commentsCount': FieldValue.increment(1),
      });

      return commentRef.id;
    } catch (e) {
      throw Exception('Lỗi khi thêm comment: $e');
    }
  }

  // Get comments for a post
  Stream<List<CommentModel>> getComments(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();
    });
  }

  // Delete comment
  Future<void> deleteComment(String commentId, String postId) async {
    try {
      await _firestore.collection('comments').doc(commentId).delete();

      // Decrement post's comment count
      await _firestore.collection('posts').doc(postId).update({
        'commentsCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Lỗi khi xóa comment: $e');
    }
  }

  // ==================== FOLLOW OPERATIONS ====================

  // Follow a user
  Future<void> followUser(String followerId, String followingId) async {
    try {
      final followRef =
          _firestore.collection('followers').doc('${followerId}_$followingId');

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

  // Unfollow a user
  Future<void> unfollowUser(String followerId, String followingId) async {
    try {
      final followRef =
          _firestore.collection('followers').doc('${followerId}_$followingId');

      // Check if following
      final followDoc = await followRef.get();
      if (!followDoc.exists) {
        return; // Not following
      }

      // Delete follow document
      await followRef.delete();

      // Update follower's following count
      await _firestore.collection('users').doc(followerId).update({
        'followingCount': FieldValue.increment(-1),
      });

      // Update following's followers count
      await _firestore.collection('users').doc(followingId).update({
        'followersCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Lỗi khi unfollow: $e');
    }
  }

  // Check if user is following another user
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
}

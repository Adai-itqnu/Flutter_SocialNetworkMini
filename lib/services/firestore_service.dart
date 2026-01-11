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
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
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

  // Get all users (for suggestions)
  Future<List<UserModel>> getAllUsers({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách users: $e');
    }
  }

  // ==================== POST OPERATIONS ====================

  // Create new post
  Future<String> createPost({
    required String userId,
    required String caption,
    required List<String> imageUrls,
    PostVisibility visibility = PostVisibility.public,
  }) async {
    try {
      final now = DateTime.now();
      final postRef = _firestore.collection('posts').doc();

      PostModel newPost = PostModel(
        postId: postRef.id,
        userId: userId,
        caption: caption,
        imageUrls: imageUrls,
        visibility: visibility,
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
          return snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();
        });
  }

  // Get user's posts
  Stream<List<PostModel>> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();
          // Sort client-side to avoid requiring composite indexes
          posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return posts;
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
      final postRef = _firestore.collection('posts').doc(postId);

      await postRef.update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Lỗi khi thích bài viết: $e');
    }
  }

  // Unlike a post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);

      await postRef.update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likesCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Lỗi khi bỏ thích bài viết: $e');
    }
  }

  // Check if user liked a post
  Future<bool> hasLikedPost(String postId, String userId) async {
    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) return false;

      final data = postDoc.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      return likedBy.contains(userId);
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
    String? parentCommentId, // For replies
  }) async {
    try {
      final commentRef = _firestore.collection('comments').doc();

      CommentModel newComment = CommentModel(
        commentId: commentRef.id,
        postId: postId,
        userId: userId,
        text: text,
        parentCommentId: parentCommentId,
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
        .snapshots()
        .map((snapshot) {
          final comments = snapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc))
              .toList();
          // Sort client-side to avoid requiring composite indexes
          comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return comments;
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

  // Unfollow a user
  Future<void> unfollowUser(String followerId, String followingId) async {
    try {
      final followRef = _firestore
          .collection('followers')
          .doc('${followerId}_$followingId');

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

  // Get list of followers for a user
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

  // Get list of users that a user is following
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

  // ==================== COMMENT LIKE OPERATIONS ====================

  // Like a comment
  Future<void> likeComment(String commentId, String userId) async {
    try {
      final commentRef = _firestore.collection('comments').doc(commentId);

      await commentRef.update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Lỗi khi thích comment: $e');
    }
  }

  // Unlike a comment
  Future<void> unlikeComment(String commentId, String userId) async {
    try {
      final commentRef = _firestore.collection('comments').doc(commentId);

      await commentRef.update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likesCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Lỗi khi bỏ thích comment: $e');
    }
  }

  // Check if user liked a comment
  Future<bool> hasLikedComment(String commentId, String userId) async {
    try {
      final commentDoc = await _firestore
          .collection('comments')
          .doc(commentId)
          .get();
      if (!commentDoc.exists) return false;

      final data = commentDoc.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      return likedBy.contains(userId);
    } catch (e) {
      return false;
    }
  }

  // Get replies for a comment
  Stream<List<CommentModel>> getReplies(String parentCommentId) {
    return _firestore
        .collection('comments')
        .where('parentCommentId', isEqualTo: parentCommentId)
        .snapshots()
        .map((snapshot) {
          final replies = snapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc))
              .toList();
          // Sort client-side to avoid requiring composite indexes
          replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return replies;
        });
  }

  // ==================== SHARE POST OPERATIONS ====================

  // Share a post
  Future<String> sharePost({
    required String userId,
    required String caption,
    required String sharedPostId,
    required String sharedUserId,
  }) async {
    try {
      final now = DateTime.now();
      final postRef = _firestore.collection('posts').doc();

      PostModel newPost = PostModel(
        postId: postRef.id,
        userId: userId,
        caption: caption,
        imageUrls: [], // Shared posts don't have their own images
        sharedPostId: sharedPostId,
        sharedUserId: sharedUserId,
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
      throw Exception('Lỗi khi chia sẻ bài viết: $e');
    }
  }

  // Get shared post details
  Future<PostModel?> getPost(String postId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('posts')
          .doc(postId)
          .get();
      if (doc.exists) {
        return PostModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi khi lấy bài viết: $e');
    }
  }

  // ==================== SAVED POSTS OPERATIONS ====================

  // Save a post
  Future<void> savePost(String userId, String postId) async {
    try {
      await _firestore
          .collection('saved_posts')
          .doc('${userId}_$postId')
          .set({
        'userId': userId,
        'postId': postId,
        'savedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Lỗi khi lưu bài viết: $e');
    }
  }

  // Unsave a post
  Future<void> unsavePost(String userId, String postId) async {
    try {
      await _firestore
          .collection('saved_posts')
          .doc('${userId}_$postId')
          .delete();
    } catch (e) {
      throw Exception('Lỗi khi bỏ lưu bài viết: $e');
    }
  }

  // Check if user saved a post
  Future<bool> hasSavedPost(String userId, String postId) async {
    try {
      final doc = await _firestore
          .collection('saved_posts')
          .doc('${userId}_$postId')
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Get all saved posts for a user
  Future<List<PostModel>> getSavedPosts(String userId) async {
    try {
      // Note: Removed orderBy to avoid requiring Firestore composite index
      final savedDocs = await _firestore
          .collection('saved_posts')
          .where('userId', isEqualTo: userId)
          .get();

      // Sort by savedAt descending in code
      final sortedDocs = savedDocs.docs.toList()
        ..sort((a, b) {
          final aTime = a.data()['savedAt'] as Timestamp?;
          final bTime = b.data()['savedAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime); // descending
        });

      final posts = <PostModel>[];
      for (final doc in sortedDocs) {
        final postId = doc.data()['postId'] as String;
        final post = await getPost(postId);
        if (post != null) {
          posts.add(post);
        }
      }
      return posts;
    } catch (e) {
      throw Exception('Lỗi khi lấy bài viết đã lưu: $e');
    }
  }

  // ==================== SEARCH OPERATIONS ====================

  // Search users by displayName or username
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _firestore.collection('users').get();
      
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) =>
              user.displayName.toLowerCase().contains(queryLower) ||
              user.username.toLowerCase().contains(queryLower))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tìm kiếm: $e');
    }
  }

  // Search posts by caption
  Future<List<PostModel>> searchPosts(String query) async {
    if (query.isEmpty) return [];
    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      return snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .where((post) => post.caption.toLowerCase().contains(queryLower))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tìm kiếm bài viết: $e');
    }
  }
}

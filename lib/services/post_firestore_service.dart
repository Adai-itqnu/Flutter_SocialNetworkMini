import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

/// Service xử lý các thao tác Firestore liên quan đến Post
class PostFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== POST OPERATIONS ====================

  /// Create new post
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

  /// Get all posts (feed) - ordered by creation time
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

  /// Get user's posts
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

  /// Get single post by ID
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

  /// Get single post stream
  Stream<PostModel?> getPostStream(String postId) {
    return _firestore.collection('posts').doc(postId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PostModel.fromFirestore(doc);
    });
  }

  /// Update post
  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('posts').doc(postId).update(data);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật bài viết: $e');
    }
  }

  /// Delete post
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

  /// Search posts by caption
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

  // ==================== LIKE OPERATIONS ====================

  /// Like a post
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

  /// Unlike a post
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

  /// Check if user liked a post
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

  // ==================== SHARE POST OPERATIONS ====================

  /// Share a post
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

  // ==================== SAVED POSTS OPERATIONS ====================

  /// Save a post
  Future<void> savePost(String userId, String postId) async {
    try {
      await _firestore.collection('saved_posts').doc('${userId}_$postId').set({
        'userId': userId,
        'postId': postId,
        'savedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Lỗi khi lưu bài viết: $e');
    }
  }

  /// Unsave a post
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

  /// Check if user saved a post
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

  /// Get all saved post IDs for a user (for batch loading)
  Future<Set<String>> getSavedPostIds(String userId) async {
    try {
      final savedDocs = await _firestore
          .collection('saved_posts')
          .where('userId', isEqualTo: userId)
          .get();
      
      return savedDocs.docs
          .map((doc) => doc.data()['postId'] as String)
          .toSet();
    } catch (e) {
      return {};
    }
  }

  /// Get all saved posts for a user
  Future<List<PostModel>> getSavedPosts(String userId) async {
    try {
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
}

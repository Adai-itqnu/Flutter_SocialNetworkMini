import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

/// Service xử lý các operations liên quan đến Post
class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
          posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return posts;
        });
  }

  /// Get single post by ID
  Future<PostModel?> getPost(String postId) async {
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      if (doc.exists) {
        return PostModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi khi lấy bài viết: $e');
    }
  }

  /// Delete post
  Future<void> deletePost(String postId, String userId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();

      await _firestore.collection('users').doc(userId).update({
        'postsCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Lỗi khi xóa bài viết: $e');
    }
  }

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
        imageUrls: [],
        sharedPostId: sharedPostId,
        sharedUserId: sharedUserId,
        createdAt: now,
        updatedAt: now,
      );

      await postRef.set(newPost.toJson());

      // Increment share count on original post
      await _firestore.collection('posts').doc(sharedPostId).update({
        'sharesCount': FieldValue.increment(1),
      });

      // Increment user's post count
      await _firestore.collection('users').doc(userId).update({
        'postsCount': FieldValue.increment(1),
      });

      return postRef.id;
    } catch (e) {
      throw Exception('Lỗi khi chia sẻ bài viết: $e');
    }
  }
}

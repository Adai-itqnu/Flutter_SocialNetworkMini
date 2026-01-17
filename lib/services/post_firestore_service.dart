import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

/// Service xử lý Firestore cho Post
/// Bao gồm: tạo, sửa, xóa, like, share, lưu bài viết
class PostFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Bài viết

  // Tạo bài viết mới
  Future<String> createPost({required String userId, required String caption, required List<String> imageUrls, PostVisibility visibility = PostVisibility.public}) async {
    try {
      final now = DateTime.now();
      final postRef = _firestore.collection('posts').doc();
      final newPost = PostModel(postId: postRef.id, userId: userId, caption: caption, imageUrls: imageUrls, visibility: visibility, createdAt: now, updatedAt: now);

      await postRef.set(newPost.toJson());
      await _firestore.collection('users').doc(userId).update({'postsCount': FieldValue.increment(1)});

      return postRef.id;
    } catch (e) {
      throw Exception('Lỗi khi tạo bài viết: $e');
    }
  }

  // Lấy tất cả bài viết (feed)
  Stream<List<PostModel>> getPosts() {
    return _firestore.collection('posts').orderBy('createdAt', descending: true).snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  // Lấy bài viết của 1 user
  Stream<List<PostModel>> getUserPosts(String userId) {
    return _firestore.collection('posts').where('userId', isEqualTo: userId).snapshots().map((snapshot) {
      final posts = snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort client-side
      return posts;
    });
  }

  // Lấy 1 bài viết theo ID
  Future<PostModel?> getPost(String postId) async {
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      return doc.exists ? PostModel.fromFirestore(doc) : null;
    } catch (e) {
      throw Exception('Lỗi khi lấy bài viết: $e');
    }
  }

  // Stream 1 bài viết
  Stream<PostModel?> getPostStream(String postId) {
    return _firestore.collection('posts').doc(postId).snapshots().map((doc) => doc.exists ? PostModel.fromFirestore(doc) : null);
  }

  // Cập nhật bài viết
  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('posts').doc(postId).update(data);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật bài viết: $e');
    }
  }

  // Xóa bài viết
  Future<void> deletePost(String postId, String userId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      await _firestore.collection('users').doc(userId).update({'postsCount': FieldValue.increment(-1)});
    } catch (e) {
      throw Exception('Lỗi khi xóa bài viết: $e');
    }
  }

  // Tìm kiếm bài viết theo caption
  Future<List<PostModel>> searchPosts(String query) async {
    if (query.isEmpty) return [];
    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _firestore.collection('posts').orderBy('createdAt', descending: true).limit(50).get();
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).where((post) => post.caption.toLowerCase().contains(queryLower)).toList();
    } catch (e) {
      throw Exception('Lỗi khi tìm kiếm bài viết: $e');
    }
  }

  // Like

  // Like bài viết
  Future<void> likePost(String postId, String userId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Lỗi khi thích bài viết: $e');
    }
  }

  // Unlike bài viết
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likesCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Lỗi khi bỏ thích bài viết: $e');
    }
  }

  // Kiểm tra đã like chưa
  Future<bool> hasLikedPost(String postId, String userId) async {
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      if (!doc.exists) return false;
      final likedBy = List<String>.from(doc.data()?['likedBy'] ?? []);
      return likedBy.contains(userId);
    } catch (e) {
      return false;
    }
  }

  // Share bài viết

  // Share 1 bài viết
  Future<String> sharePost({required String userId, required String caption, required String sharedPostId, required String sharedUserId}) async {
    try {
      final now = DateTime.now();
      final postRef = _firestore.collection('posts').doc();
      final newPost = PostModel(postId: postRef.id, userId: userId, caption: caption, imageUrls: [], sharedPostId: sharedPostId, sharedUserId: sharedUserId, createdAt: now, updatedAt: now);

      await postRef.set(newPost.toJson());
      await _firestore.collection('users').doc(userId).update({'postsCount': FieldValue.increment(1)});

      return postRef.id;
    } catch (e) {
      throw Exception('Lỗi khi chia sẻ bài viết: $e');
    }
  }

  // Lưu bài viết

  // Lưu bài viết
  Future<void> savePost(String userId, String postId) async {
    try {
      await _firestore.collection('saved_posts').doc('${userId}_$postId').set({'userId': userId, 'postId': postId, 'savedAt': Timestamp.now()});
    } catch (e) {
      throw Exception('Lỗi khi lưu bài viết: $e');
    }
  }

  // Bỏ lưu bài viết
  Future<void> unsavePost(String userId, String postId) async {
    try {
      await _firestore.collection('saved_posts').doc('${userId}_$postId').delete();
    } catch (e) {
      throw Exception('Lỗi khi bỏ lưu bài viết: $e');
    }
  }

  // Kiểm tra đã lưu chưa
  Future<bool> hasSavedPost(String userId, String postId) async {
    try {
      final doc = await _firestore.collection('saved_posts').doc('${userId}_$postId').get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Lấy tất cả ID bài đã lưu
  Future<Set<String>> getSavedPostIds(String userId) async {
    try {
      final savedDocs = await _firestore.collection('saved_posts').where('userId', isEqualTo: userId).get();
      return savedDocs.docs.map((doc) => doc.data()['postId'] as String).toSet();
    } catch (e) {
      return {};
    }
  }

  // Lấy tất cả bài đã lưu
  Future<List<PostModel>> getSavedPosts(String userId) async {
    try {
      final savedDocs = await _firestore.collection('saved_posts').where('userId', isEqualTo: userId).get();
      final sortedDocs = savedDocs.docs.toList()..sort((a, b) {
        final aTime = a.data()['savedAt'] as Timestamp?;
        final bTime = b.data()['savedAt'] as Timestamp?;
        return (bTime?.compareTo(aTime ?? Timestamp.now()) ?? 0);
      });

      final posts = <PostModel>[];
      for (final doc in sortedDocs) {
        final post = await getPost(doc.data()['postId'] as String);
        if (post != null) posts.add(post);
      }
      return posts;
    } catch (e) {
      throw Exception('Lỗi khi lấy bài viết đã lưu: $e');
    }
  }
}

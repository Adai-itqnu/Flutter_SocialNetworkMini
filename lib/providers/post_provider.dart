import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class PostProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<PostModel> _posts = [];
  Map<String, UserModel> _postAuthors = {}; // Cache user data for posts
  bool _isLoading = false;
  String? _error;

  // Getters
  List<PostModel> get posts => _posts;
  Map<String, UserModel> get postAuthors => _postAuthors;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize post stream
  void initializePostStream() {
    _firestoreService.getPosts().listen(
      (List<PostModel> loadedPosts) async {
        // Cập nhật danh sách bài viết ngay lập tức để người dùng thấy nội dung trước
        _posts = loadedPosts;
        notifyListeners();

        // Tìm các userId chưa có dữ liệu author trong cache
        final missingUserIds = _posts
            .map((p) => p.userId)
            .where((uid) => !_postAuthors.containsKey(uid))
            .toSet(); // Dùng Set để tránh lấy trùng

        if (missingUserIds.isEmpty) return;

        // Lấy thông tin các author còn thiếu song song (Future.wait) để tăng tốc độ
        try {
          final results = await Future.wait(
            missingUserIds.map((uid) => _firestoreService.getUser(uid)),
          );

          for (int i = 0; i < missingUserIds.length; i++) {
            final author = results[i];
            final uid = missingUserIds.elementAt(i);
            if (author != null) {
              _postAuthors[uid] = author;
            }
          }

          // Thông báo lại sau khi đã có đầy đủ info tác giả
          notifyListeners();
        } catch (e) {
          print('Lỗi tải dữ liệu người dùng: $e');
        }
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Create post
  Future<bool> createPost({
    required String userId,
    required String caption,
    required List<String> imageUrls,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.createPost(
        userId: userId,
        caption: caption,
        imageUrls: imageUrls,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete post
  Future<bool> deletePost(String postId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.deletePost(postId, userId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Like post
  Future<void> likePost(String postId, String userId) async {
    try {
      await _firestoreService.likePost(postId, userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Unlike post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _firestoreService.unlikePost(postId, userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Check if user liked post
  Future<bool> hasLikedPost(String postId, String userId) async {
    return await _firestoreService.hasLikedPost(postId, userId);
  }

  // Get author for a post
  UserModel? getPostAuthor(String userId) {
    return _postAuthors[userId];
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

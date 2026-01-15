import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../utils/app_logger.dart';

class PostProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  List<PostModel> _posts = [];
  final Map<String, UserModel> _postAuthors = {}; // Cache user data for posts
  Set<String> _savedPostIds = {}; // Cache saved post IDs
  bool _isLoading = false;
  String? _error;
  String? _lastDeletedPostId; // Track deleted post for other screens to update

  // Getters
  List<PostModel> get posts => _posts;
  Map<String, UserModel> get postAuthors => _postAuthors;
  Set<String> get savedPostIds => _savedPostIds;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastDeletedPostId => _lastDeletedPostId;

  /// Get filtered posts based on visibility and current user's follow list
  List<PostModel> getFilteredPosts(
    String? currentUserId,
    List<String> followingIds,
  ) {
    if (currentUserId == null) return _posts;

    return _posts.where((post) {
      // Show own posts
      if (post.userId == currentUserId) return true;

      // Show public posts
      if (post.visibility == PostVisibility.public) return true;

      // Show followers-only posts if following
      if (post.visibility == PostVisibility.followersOnly) {
        return followingIds.contains(post.userId);
      }

      return false;
    }).toList();
  }

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
          AppLogger.error('Lỗi tải dữ liệu người dùng', error: e);
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
    PostVisibility visibility = PostVisibility.public,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final postId = await _firestoreService.createPost(
        userId: userId,
        caption: caption,
        imageUrls: imageUrls,
        visibility: visibility,
      );

      // Create new post notification for all followers
      await _notificationService.createNewPostNotificationForFollowers(
        postAuthorId: userId,
        postId: postId,
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

  // Update post
  Future<bool> updatePost(String postId, Map<String, dynamic> data) async {
    try {
      await _firestoreService.updatePost(postId, data);

      // Optimistic update
      final index = _posts.indexWhere((p) => p.postId == postId);
      if (index != -1) {
        if (data.containsKey('caption')) {
          _posts[index] = _posts[index].copyWith(
            caption: data['caption'],
            updatedAt: DateTime.now(),
          );
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
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

      // Optimistic delete
      _posts.removeWhere((p) => p.postId == postId);

      _lastDeletedPostId = postId;
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
  Future<void> likePost(
    String postId,
    String userId, {
    String? postOwnerId,
  }) async {
    try {
      await _firestoreService.likePost(postId, userId);

      // Create like notification if we know the post owner
      if (postOwnerId != null && postOwnerId != userId) {
        await _notificationService.createLikeNotification(
          fromUserId: userId,
          postOwnerId: postOwnerId,
          postId: postId,
        );
      }
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

  // ==================== SAVED POSTS CACHE ====================

  /// Load saved post IDs for a user (call once on app start)
  Future<void> loadSavedPostIds(String userId) async {
    try {
      _savedPostIds = await _firestoreService.getSavedPostIds(userId);
      notifyListeners();
    } catch (e) {
      AppLogger.error('Lỗi tải saved posts', error: e);
    }
  }

  /// Check if post is saved (from cache - no network call)
  bool isSaved(String postId) {
    return _savedPostIds.contains(postId);
  }

  /// Toggle save state and update cache
  Future<bool> toggleSave(String userId, String postId) async {
    final wasSaved = _savedPostIds.contains(postId);
    
    // Optimistic update
    if (wasSaved) {
      _savedPostIds.remove(postId);
    } else {
      _savedPostIds.add(postId);
    }
    notifyListeners();

    try {
      if (wasSaved) {
        await _firestoreService.unsavePost(userId, postId);
      } else {
        await _firestoreService.savePost(userId, postId);
      }
      return true;
    } catch (e) {
      // Revert on error
      if (wasSaved) {
        _savedPostIds.add(postId);
      } else {
        _savedPostIds.remove(postId);
      }
      notifyListeners();
      _error = e.toString();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

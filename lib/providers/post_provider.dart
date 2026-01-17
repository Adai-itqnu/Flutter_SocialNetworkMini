import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../utils/app_logger.dart';

/// Provider quản lý bài viết
class PostProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  List<PostModel> _posts = [];                    // Danh sách bài viết
  final Map<String, UserModel> _postAuthors = {}; // Cache thông tin tác giả
  Set<String> _savedPostIds = {};                 // Cache ID bài đã lưu
  bool _isLoading = false;
  String? _error;
  String? _lastDeletedPostId;                     // ID bài vừa xóa

  // Getters
  List<PostModel> get posts => _posts;
  Map<String, UserModel> get postAuthors => _postAuthors;
  Set<String> get savedPostIds => _savedPostIds;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastDeletedPostId => _lastDeletedPostId;

  // Lọc bài viết theo visibility và danh sách following
  List<PostModel> getFilteredPosts(
    String? currentUserId,
    List<String> followingIds,
  ) {
    if (currentUserId == null) return _posts;

    return _posts.where((post) {
      // Hiện bài của mình
      if (post.userId == currentUserId) return true;

      // Hiện bài public
      if (post.visibility == PostVisibility.public) return true;

      // Hiện bài followers-only nếu đang follow
      if (post.visibility == PostVisibility.followersOnly) {
        return followingIds.contains(post.userId);
      }

      return false;
    }).toList();
  }

  // Khởi tạo stream bài viết
  void initializePostStream() {
    _firestoreService.getPosts().listen(
      (List<PostModel> loadedPosts) async {
        // Cập nhật danh sách ngay để user thấy nội dung
        _posts = loadedPosts;
        notifyListeners();

        // Tìm các userId chưa có trong cache
        final missingUserIds = _posts
            .map((p) => p.userId)
            .where((uid) => !_postAuthors.containsKey(uid))
            .toSet();

        if (missingUserIds.isEmpty) return;

        // Tải thông tin tác giả song song
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

  // Tạo bài viết mới
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

      // Tạo notification cho followers
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

  // Cập nhật bài viết
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

  // Xóa bài viết
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

  // Thích bài viết
  Future<void> likePost(
    String postId,
    String userId, {
    String? postOwnerId,
  }) async {
    try {
      await _firestoreService.likePost(postId, userId);

      // Tạo notification nếu biết chủ bài viết
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

  // Bỏ thích bài viết
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _firestoreService.unlikePost(postId, userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Kiểm tra đã thích chưa
  Future<bool> hasLikedPost(String postId, String userId) async {
    return await _firestoreService.hasLikedPost(postId, userId);
  }

  // Lấy thông tin tác giả
  UserModel? getPostAuthor(String userId) {
    return _postAuthors[userId];
  }

  // Tải danh sách ID bài đã lưu
  Future<void> loadSavedPostIds(String userId) async {
    try {
      _savedPostIds = await _firestoreService.getSavedPostIds(userId);
      notifyListeners();
    } catch (e) {
      AppLogger.error('Lỗi tải saved posts', error: e);
    }
  }

  // Kiểm tra bài đã lưu chưa (từ cache)
  bool isSaved(String postId) {
    return _savedPostIds.contains(postId);
  }

  // Toggle trạng thái lưu bài
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
      // Revert nếu lỗi
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

  // Xóa lỗi
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

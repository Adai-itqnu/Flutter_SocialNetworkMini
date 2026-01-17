import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import 'user_provider.dart';

/// Provider quản lý follow/unfollow giữa các người dùng
class FollowProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  // Reference tới UserProvider để refresh data sau follow/unfollow
  UserProvider? _userProvider;

  void setUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;
  }

  // State
  List<UserModel> _followers = [];              // Danh sách người theo dõi mình
  List<UserModel> _following = [];              // Danh sách mình đang theo dõi
  List<UserModel> _suggestedUsers = [];         // Gợi ý người dùng
  Map<String, bool> _followingStatus = {};      // Cache trạng thái follow: userId -> isFollowing
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  // Getters
  List<UserModel> get followers => _followers;
  List<UserModel> get following => _following;
  List<UserModel> get suggestedUsers => _suggestedUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get followersCount => _followers.length;
  int get followingCount => _following.length;

  // Kiểm tra có đang follow user không
  bool isFollowing(String targetUserId) {
    return _followingStatus[targetUserId] ?? false;
  }

  // Tải dữ liệu follow
  Future<void> loadFollowData(String userId, {bool forceReload = false}) async {
    // Bỏ qua nếu đã load và không force
    if (!forceReload && _currentUserId == userId && _followers.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _error = null;
    _currentUserId = userId;
    notifyListeners();

    try {
      // Lấy danh sách ID followers và following
      final followerIds = await _firestoreService.getFollowers(userId);
      final followingIds = await _firestoreService.getFollowing(userId);

      // Load thông tin followers (bỏ qua admin)
      final followers = <UserModel>[];
      for (final uid in followerIds) {
        final user = await _firestoreService.getUser(uid);
        if (user != null && user.role != 'admin') {
          followers.add(user);
        }
      }

      // Load thông tin following (bỏ qua admin)
      final following = <UserModel>[];
      for (final uid in followingIds) {
        final user = await _firestoreService.getUser(uid);
        if (user != null && user.role != 'admin') {
          following.add(user);
          _followingStatus[uid] = true;
        }
      }

      // Check xem đã follow lại followers chưa (cho nút "follow back")
      for (final follower in followers) {
        if (!_followingStatus.containsKey(follower.uid)) {
          final isFollowing = await _firestoreService.isFollowing(
            userId,
            follower.uid,
          );
          _followingStatus[follower.uid] = isFollowing;
        }
      }

      _followers = followers;
      _following = following;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Follow một user
  Future<bool> followUser(String currentUserId, String targetUserId) async {
    if (_followingStatus[targetUserId] == true) {
      return true; // Đã follow rồi
    }

    // Optimistic update
    _followingStatus[targetUserId] = true;
    notifyListeners();

    try {
      await _firestoreService.followUser(currentUserId, targetUserId);

      // Tạo notification follow
      await _notificationService.createFollowNotification(
        fromUserId: currentUserId,
        toUserId: targetUserId,
      );

      // Thêm vào danh sách following nếu có data
      final targetUser = await _firestoreService.getUser(targetUserId);
      if (targetUser != null && !_following.any((u) => u.uid == targetUserId)) {
        _following.add(targetUser);
        notifyListeners();
      }

      // Reload user data để cập nhật followingCount
      _userProvider?.loadUser(currentUserId);

      return true;
    } catch (e) {
      // Revert nếu lỗi
      _followingStatus[targetUserId] = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Unfollow một user
  Future<bool> unfollowUser(String currentUserId, String targetUserId) async {
    if (_followingStatus[targetUserId] == false) {
      return true; // Chưa follow
    }

    // Optimistic update
    _followingStatus[targetUserId] = false;
    notifyListeners();

    try {
      await _firestoreService.unfollowUser(currentUserId, targetUserId);

      // Xóa khỏi danh sách following
      _following.removeWhere((u) => u.uid == targetUserId);
      notifyListeners();

      // Reload user data để cập nhật followingCount
      _userProvider?.loadUser(currentUserId);

      return true;
    } catch (e) {
      // Revert nếu lỗi
      _followingStatus[targetUserId] = true;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Toggle trạng thái follow
  Future<bool> toggleFollow(String currentUserId, String targetUserId) async {
    if (isFollowing(targetUserId)) {
      return await unfollowUser(currentUserId, targetUserId);
    } else {
      return await followUser(currentUserId, targetUserId);
    }
  }

  // Kiểm tra trạng thái follow (từ Firestore)
  Future<bool> checkFollowStatus(
    String currentUserId,
    String targetUserId,
  ) async {
    if (_followingStatus.containsKey(targetUserId)) {
      return _followingStatus[targetUserId]!;
    }

    final isFollowing = await _firestoreService.isFollowing(
      currentUserId,
      targetUserId,
    );
    _followingStatus[targetUserId] = isFollowing;
    notifyListeners();
    return isFollowing;
  }

  // Xóa dữ liệu (khi logout)
  void clear() {
    _followers = [];
    _following = [];
    _suggestedUsers = [];
    _followingStatus = {};
    _currentUserId = null;
    _error = null;
    notifyListeners();
  }

  // Tải gợi ý người dùng (tất cả users trừ current user và admin)
  Future<void> loadSuggestedUsers(String currentUserId) async {
    try {
      final allUsers = await _firestoreService.getAllUsers(limit: 50);

      // Lọc bỏ current user và admin
      _suggestedUsers = allUsers
          .where((u) => u.uid != currentUserId && u.role != 'admin')
          .toList();

      // Kiểm tra trạng thái follow
      for (final user in _suggestedUsers) {
        if (!_followingStatus.containsKey(user.uid)) {
          final isFollowing = await _firestoreService.isFollowing(
            currentUserId,
            user.uid,
          );
          _followingStatus[user.uid] = isFollowing;
        }
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Refresh tất cả dữ liệu
  Future<void> refresh(String userId) async {
    await loadFollowData(userId, forceReload: true);
    await loadSuggestedUsers(userId);
  }
}

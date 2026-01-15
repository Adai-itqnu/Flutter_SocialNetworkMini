import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class FollowProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  // State
  List<UserModel> _followers = [];
  List<UserModel> _following = [];
  List<UserModel> _suggestedUsers = []; // NEW: All users for suggestions
  Map<String, bool> _followingStatus = {}; // userId -> isFollowing
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  // Getters
  List<UserModel> get followers => _followers;
  List<UserModel> get following => _following;
  List<UserModel> get suggestedUsers => _suggestedUsers; // NEW
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get followersCount => _followers.length;
  int get followingCount => _following.length;

  /// Check if current user is following target user
  bool isFollowing(String targetUserId) {
    return _followingStatus[targetUserId] ?? false;
  }

  /// Initialize follow data for a user
  Future<void> loadFollowData(String userId, {bool forceReload = false}) async {
    // Skip if already loaded and not forcing reload
    if (!forceReload && _currentUserId == userId && _followers.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _error = null;
    _currentUserId = userId;
    notifyListeners();

    try {
      // Get followers and following IDs
      final followerIds = await _firestoreService.getFollowers(userId);
      final followingIds = await _firestoreService.getFollowing(userId);

      // Load user data for followers (exclude admin)
      final followers = <UserModel>[];
      for (final uid in followerIds) {
        final user = await _firestoreService.getUser(uid);
        if (user != null && user.role != 'admin') {
          followers.add(user);
        }
      }

      // Load user data for following (exclude admin)
      final following = <UserModel>[];
      for (final uid in followingIds) {
        final user = await _firestoreService.getUser(uid);
        if (user != null && user.role != 'admin') {
          following.add(user);
          _followingStatus[uid] = true;
        }
      }

      // Check if current user follows each follower (for "follow back" status)
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

  /// Follow a user
  Future<bool> followUser(String currentUserId, String targetUserId) async {
    if (_followingStatus[targetUserId] == true) {
      return true; // Already following
    }

    // Optimistic update
    _followingStatus[targetUserId] = true;
    notifyListeners();

    try {
      await _firestoreService.followUser(currentUserId, targetUserId);

      // Create follow notification
      await _notificationService.createFollowNotification(
        fromUserId: currentUserId,
        toUserId: targetUserId,
      );

      // Add to following list if user data available
      final targetUser = await _firestoreService.getUser(targetUserId);
      if (targetUser != null && !_following.any((u) => u.uid == targetUserId)) {
        _following.add(targetUser);
        notifyListeners();
      }

      return true;
    } catch (e) {
      // Revert on error
      _followingStatus[targetUserId] = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(String currentUserId, String targetUserId) async {
    if (_followingStatus[targetUserId] == false) {
      return true; // Not following
    }

    // Optimistic update
    _followingStatus[targetUserId] = false;
    notifyListeners();

    try {
      await _firestoreService.unfollowUser(currentUserId, targetUserId);

      // Remove from following list
      _following.removeWhere((u) => u.uid == targetUserId);
      notifyListeners();

      return true;
    } catch (e) {
      // Revert on error
      _followingStatus[targetUserId] = true;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Toggle follow status
  Future<bool> toggleFollow(String currentUserId, String targetUserId) async {
    if (isFollowing(targetUserId)) {
      return await unfollowUser(currentUserId, targetUserId);
    } else {
      return await followUser(currentUserId, targetUserId);
    }
  }

  /// Check follow status for a specific user (from Firestore)
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

  /// Clear data (on logout)
  void clear() {
    _followers = [];
    _following = [];
    _suggestedUsers = [];
    _followingStatus = {};
    _currentUserId = null;
    _error = null;
    notifyListeners();
  }

  /// Load suggested users (all users except current user and admin)
  Future<void> loadSuggestedUsers(String currentUserId) async {
    try {
      final allUsers = await _firestoreService.getAllUsers(limit: 50);

      // Filter out current user and admin users
      _suggestedUsers = allUsers
          .where((u) => u.uid != currentUserId && u.role != 'admin')
          .toList();

      // Check follow status for suggested users
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

  /// Refresh data
  Future<void> refresh(String userId) async {
    await loadFollowData(userId, forceReload: true);
    await loadSuggestedUsers(userId);
  }
}

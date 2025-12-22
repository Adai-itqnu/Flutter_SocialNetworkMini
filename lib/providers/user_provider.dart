import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class UserProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load current user
  Future<void> loadUser(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _firestoreService.getUser(uid);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile(String uid, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.updateUser(uid, data);
      
      // Reload user data
      await loadUser(uid);
      
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

  // Follow user
  Future<void> followUser(String followerId, String followingId) async {
    try {
      await _firestoreService.followUser(followerId, followingId);
      // Reload current user to update following count
      if (_currentUser?.uid == followerId) {
        await loadUser(followerId);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Unfollow user
  Future<void> unfollowUser(String followerId, String followingId) async {
    try {
      await _firestoreService.unfollowUser(followerId, followingId);
      // Reload current user to update following count
      if (_currentUser?.uid == followerId) {
        await loadUser(followerId);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Check if following
  Future<bool> isFollowing(String followerId, String followingId) async {
    return await _firestoreService.isFollowing(followerId, followingId);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear user data (on logout)
  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}

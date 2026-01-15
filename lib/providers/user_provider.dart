import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/imgbb_service.dart';

class UserProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
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

  // Update user profile with optional avatar upload
  Future<bool> updateProfileWithAvatar({
    required String uid,
    required Map<String, dynamic> data,
    XFile? avatarFile,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Upload avatar if provided
      if (avatarFile != null) {
        final photoURL = await ImgBBService.uploadImage(avatarFile);
        data['photoURL'] = photoURL;
      }

      await _firestoreService.updateUser(uid, data);

      // Reload user data
      await loadUser(uid);

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
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

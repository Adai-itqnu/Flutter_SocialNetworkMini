import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/imgbb_service.dart';

/// Provider quản lý thông tin người dùng hiện tại
class UserProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _currentUser;  // User hiện tại
  bool _isLoading = false;  // Trạng thái loading
  bool _isSaving = false;   // Trạng thái đang lưu
  String? _error;           // Thông báo lỗi

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  // Tải thông tin user từ Firestore
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

  // Cập nhật thông tin profile
  Future<bool> updateProfile(String uid, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.updateUser(uid, data);
      await loadUser(uid); // Reload data

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

  // Cập nhật profile kèm upload avatar
  Future<bool> updateProfileWithAvatar({
    required String uid,
    required Map<String, dynamic> data,
    XFile? avatarFile,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      // Upload avatar nếu có
      if (avatarFile != null) {
        final photoURL = await ImgBBService.uploadImage(avatarFile);
        data['photoURL'] = photoURL;
      }

      await _firestoreService.updateUser(uid, data);
      await loadUser(uid); // Reload data

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

  // Xóa lỗi
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Xóa dữ liệu user (khi logout)
  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}

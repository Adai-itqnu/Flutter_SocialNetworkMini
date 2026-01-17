import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

/// Provider quản lý xác thực người dùng
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _firebaseUser;       // Firebase Auth user
  UserModel? _userModel;     // User data từ Firestore
  bool _isLoading = false;   // Trạng thái loading
  String? _error;            // Thông báo lỗi

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    // Lắng nghe thay đổi trạng thái đăng nhập
    _authService.authStateChanges.listen((User? user) {
      _firebaseUser = user;
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  // Tải dữ liệu user từ Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      _userModel = await _authService.getUserData(uid);

      // Nếu user đã đăng nhập nhưng chưa có profile trong Firestore -> tạo mới
      if (_userModel == null && _firebaseUser != null) {
        await _authService.createMissingUserProfile(_firebaseUser!);
        _userModel = await _authService.getUserData(uid);
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Đăng nhập bằng email/password
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithEmail(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseAuthError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Parse lỗi Firebase thành thông báo tiếng Việt
  String _parseAuthError(String error) {
    return 'Sai email hoặc mật khẩu vui lòng thử lại!';
  }

  // Đăng ký tài khoản mới
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signUpWithEmail(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
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

  // Đăng nhập bằng Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();

      if (userCredential == null) {
        return false; // User hủy đăng nhập
      }

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    _firebaseUser = null;
    notifyListeners();
  }

  // Đặt lại mật khẩu
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
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

  // Xóa lỗi
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

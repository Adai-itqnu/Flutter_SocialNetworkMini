import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    // Listen to auth state changes
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

  // Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      _userModel = await _authService.getUserData(uid);
      
      // If user logged in but no Firestore profile exists (e.g., deleted DB), create one
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

  // Sign in
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
      // Parse Firebase error to user-friendly message
      _error = _parseAuthError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Parse Firebase auth error to Vietnamese message
  String _parseAuthError(String error) {
    if (error.contains('wrong-password') || error.contains('invalid-credential')) {
      return 'Sai mật khẩu. Vui lòng thử lại.';
    } else if (error.contains('user-not-found')) {
      return 'Không tìm thấy tài khoản với email này.';
    } else if (error.contains('invalid-email')) {
      return 'Email không hợp lệ.';
    } else if (error.contains('user-disabled')) {
      return 'Tài khoản đã bị vô hiệu hóa.';
    } else if (error.contains('too-many-requests')) {
      return 'Quá nhiều lần thử. Vui lòng thử lại sau.';
    } else if (error.contains('network')) {
      return 'Lỗi kết nối mạng. Kiểm tra internet.';
    } else if (error.contains('email-already-in-use')) {
      return 'Email đã được sử dụng.';
    } else if (error.contains('weak-password')) {
      return 'Mật khẩu quá yếu. Cần ít nhất 6 ký tự.';
    }
    return 'Đăng nhập thất bại. Vui lòng thử lại.';
  }

  // Sign up
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

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userCredential = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      
      if (userCredential == null) {
        // User cancelled
        return false;
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    _firebaseUser = null;
    notifyListeners();
  }

  // Reset password
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

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

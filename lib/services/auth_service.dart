import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// AuthService - Xử lý xác thực người dùng (Mobile-only)
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google (Mobile only - uses signInWithProvider)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      final userCredential = await _auth.signInWithProvider(googleProvider);

      // Check if user exists in Firestore, if not create new document
      if (userCredential.user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          // Create new user document for first-time Google sign-in
          await _createUserDocument(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            username: _generateUsername(userCredential.user!.email ?? ''),
            displayName: userCredential.user!.displayName ?? 'User',
            photoURL: userCredential.user!.photoURL,
          );
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'sign_in_canceled') {
        return null; // User cancelled
      }
      throw Exception('Đăng nhập Google thất bại: ${e.message}');
    } catch (e) {
      throw Exception('Đăng nhập Google thất bại: $e');
    }
  }

  // Generate username from email
  String _generateUsername(String email) {
    final username = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return '${username}_${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      // Check if username is already taken
      final usernameExists = await _checkUsernameExists(username);
      if (usernameExists) {
        throw Exception(
          'Username đã được sử dụng. Vui lòng chọn username khác.',
        );
      }

      // Create user account
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      if (result.user != null) {
        await _createUserDocument(
          uid: result.user!.uid,
          email: email,
          username: username,
          displayName: displayName,
        );
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String username,
    required String displayName,
    String? photoURL,
  }) async {
    // Check if this is the first user (auto-admin)
    final usersSnapshot = await _firestore.collection('users').limit(1).get();
    final isFirstUser = usersSnapshot.docs.isEmpty;

    // You can also auto-admin specific emails
    // ⚠️ Password phải đạt validation: 8+ ký tự, 1 chữ HOA, 1 chữ thường, 1 số, 1 ký tự đặc biệt
    // Ví dụ: Admin123!
    final adminEmails = [
      'admin@gmail.com',
      // Thêm email khác nếu muốn
    ];
    final isAdminEmail = adminEmails.contains(email.toLowerCase());

    UserModel newUser = UserModel(
      uid: uid,
      email: email,
      username: username,
      displayName: displayName,
      photoURL: photoURL,
      createdAt: DateTime.now(),
      role: (isFirstUser || isAdminEmail) ? 'admin' : 'user', // Auto admin
    );

    await _firestore.collection('users').doc(uid).set(newUser.toJson());
  }

  // Check if username exists
  Future<bool> _checkUsernameExists(String username) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Không thể lấy thông tin người dùng: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Mật khẩu không đúng.';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      default:
        return 'Đã xảy ra lỗi: ${e.message}';
    }
  }
}

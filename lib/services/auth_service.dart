import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart' as g_signin;
import '../models/user_model.dart';

/// Service xác thực người dùng (Web + Mobile)
/// Bao gồm: đăng nhập, đăng ký, đăng xuất, reset mật khẩu
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // Stream theo dõi thay đổi auth
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng nhập bằng email và password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Đăng nhập bằng Google (Web: popup, Mobile: native)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      UserCredential userCredential;
      
      if (kIsWeb) {
        // Web: Dùng popup
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile: Dùng google_sign_in package
        final googleSignIn = g_signin.GoogleSignIn(scopes: ['email', 'profile']);
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) return null; // User hủy
        
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
        userCredential = await _auth.signInWithCredential(credential);
      }

      // Tạo user document nếu chưa có
      if (userCredential.user != null) {
        final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        if (!userDoc.exists) {
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
      if (e.code == 'popup-closed-by-user' || e.code == 'sign_in_canceled') return null;
      throw Exception('Đăng nhập Google thất bại: ${e.message}');
    } catch (e) {
      throw Exception('Đăng nhập Google thất bại: $e');
    }
  }

  // Tạo username từ email
  String _generateUsername(String email) {
    final username = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return '${username}_${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  // Đăng ký bằng email và password
  Future<UserCredential> signUpWithEmail({required String email, required String password, required String username, required String displayName}) async {
    try {
      // Kiểm tra username đã tồn tại chưa
      final usernameExists = await _checkUsernameExists(username);
      if (usernameExists) throw Exception('Username đã được sử dụng. Vui lòng chọn username khác.');

      // Tạo tài khoản
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      // Cập nhật display name và tạo user document
      if (result.user != null) {
        await result.user!.updateDisplayName(displayName);
        await _createUserDocument(uid: result.user!.uid, email: email, username: username, displayName: displayName);
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Tạo user document trong Firestore
  Future<void> _createUserDocument({required String uid, required String email, required String username, required String displayName, String? photoURL}) async {
    // Kiểm tra xem có phải user đầu tiên không (auto-admin)
    final usersSnapshot = await _firestore.collection('users').limit(1).get();
    final isFirstUser = usersSnapshot.docs.isEmpty;

    // Email được cấp quyền admin
    final adminEmails = ['admin@gmail.com'];
    final isAdminEmail = adminEmails.contains(email.toLowerCase());

    final newUser = UserModel(
      uid: uid,
      email: email,
      username: username,
      displayName: displayName,
      photoURL: photoURL,
      createdAt: DateTime.now(),
      role: (isFirstUser || isAdminEmail) ? 'admin' : 'user',
    );

    await _firestore.collection('users').doc(uid).set(newUser.toJson());
  }

  // Kiểm tra username đã tồn tại chưa
  Future<bool> _checkUsernameExists(String username) async {
    final query = await _firestore.collection('users').where('username', isEqualTo: username).limit(1).get();
    return query.docs.isNotEmpty;
  }

  // Lấy thông tin user từ Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) return UserModel.fromFirestore(doc);
      return null;
    } catch (e) {
      throw Exception('Không thể lấy thông tin người dùng: $e');
    }
  }

  // Tạo profile nếu chưa có (cho user đã đăng nhập nhưng DB bị xóa)
  Future<void> createMissingUserProfile(User firebaseUser) async {
    try {
      await _createUserDocument(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        username: _generateUsername(firebaseUser.email ?? firebaseUser.uid),
        displayName: firebaseUser.displayName ?? 'User',
        photoURL: firebaseUser.photoURL,
      );
    } catch (e) {
      throw Exception('Không thể tạo profile: $e');
    }
  }

  // Đăng xuất
  Future<void> signOut() async => await _auth.signOut();

  // Reset mật khẩu
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Xử lý lỗi Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password': return 'Mật khẩu không đúng.';
      case 'email-already-in-use': return 'Email này đã được đăng ký.';
      case 'invalid-email': return 'Email không hợp lệ.';
      case 'weak-password': return 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
      case 'too-many-requests': return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      default: return 'Đã xảy ra lỗi: ${e.message}';
    }
  }
}

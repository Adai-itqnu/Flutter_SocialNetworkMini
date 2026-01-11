import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service xử lý các operations liên quan đến User
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user by ID
  Future<UserModel?> getUser(String uid) async {
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
      throw Exception('Lỗi khi lấy thông tin user: $e');
    }
  }

  /// Update user profile
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật profile: $e');
    }
  }

  /// Create new user (for registration)
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toJson());
    } catch (e) {
      throw Exception('Lỗi khi tạo user: $e');
    }
  }

  /// Check if username exists
  Future<bool> isUsernameExists(String username) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

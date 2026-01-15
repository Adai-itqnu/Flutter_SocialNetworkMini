import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service xử lý các thao tác Firestore liên quan đến User
class UserFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USER OPERATIONS ====================

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

  /// Update user role (for admin functionality)
  Future<void> updateUserRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': role});
    } catch (e) {
      throw Exception('Lỗi khi cập nhật role: $e');
    }
  }

  /// Get all users (for suggestions)
  Future<List<UserModel>> getAllUsers({int limit = 50}) async {
    try {
      final snapshot = await _firestore.collection('users').limit(limit).get();
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách users: $e');
    }
  }

  /// Search users by displayName or username
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _firestore.collection('users').get();

      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where(
            (user) =>
                user.displayName.toLowerCase().contains(queryLower) ||
                user.username.toLowerCase().contains(queryLower),
          )
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tìm kiếm: $e');
    }
  }
}

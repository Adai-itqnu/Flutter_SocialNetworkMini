import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service xử lý Firestore cho User
/// Bao gồm: lấy, cập nhật, tìm kiếm user
class UserFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy user theo ID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? UserModel.fromFirestore(doc) : null;
    } catch (e) {
      throw Exception('Lỗi khi lấy thông tin user: $e');
    }
  }

  // Cập nhật profile user
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật profile: $e');
    }
  }

  // Cập nhật role (cho chức năng admin)
  Future<void> updateUserRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': role});
    } catch (e) {
      throw Exception('Lỗi khi cập nhật role: $e');
    }
  }

  // Lấy tất cả users (cho suggestions)
  Future<List<UserModel>> getAllUsers({int limit = 50}) async {
    try {
      final snapshot = await _firestore.collection('users').limit(limit).get();
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách users: $e');
    }
  }

  // Tìm kiếm users theo displayName hoặc username
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.displayName.toLowerCase().contains(queryLower) || user.username.toLowerCase().contains(queryLower))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tìm kiếm: $e');
    }
  }
}

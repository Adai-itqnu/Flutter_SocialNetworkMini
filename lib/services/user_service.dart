import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service xử lý User
/// Bao gồm: lấy, cập nhật, tạo user, kiểm tra username
class UserService {
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

  // Cập nhật profile
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật profile: $e');
    }
  }

  // Tạo user mới (cho đăng ký)
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toJson());
    } catch (e) {
      throw Exception('Lỗi khi tạo user: $e');
    }
  }

  // Kiểm tra username đã tồn tại chưa
  Future<bool> isUsernameExists(String username) async {
    try {
      final query = await _firestore.collection('users').where('username', isEqualTo: username).limit(1).get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

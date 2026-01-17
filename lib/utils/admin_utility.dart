import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_logger.dart';

/// Utility class để quản lý admin roles
/// Dùng để cập nhật role của users đã tồn tại
class AdminUtility {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Đặt role admin cho user theo email
  Future<void> setAdminByEmail(String email) async {
    try {
      final snapshot = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
      if (snapshot.docs.isEmpty) throw Exception('User with email $email not found');

      await _firestore.collection('users').doc(snapshot.docs.first.id).update({'role': 'admin'});
      AppLogger.info('✅ Successfully set admin role for: $email');
    } catch (e) {
      AppLogger.error('❌ Error setting admin role', error: e);
      rethrow;
    }
  }

  // Đặt role admin cho user theo UID
  Future<void> setAdminByUid(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) throw Exception('User with UID $uid not found');

      await _firestore.collection('users').doc(uid).update({'role': 'admin'});
      AppLogger.info('✅ Successfully set admin role for UID: $uid');
    } catch (e) {
      AppLogger.error('❌ Error setting admin role', error: e);
      rethrow;
    }
  }

  // Xóa role admin theo email
  Future<void> removeAdminByEmail(String email) async {
    try {
      final snapshot = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
      if (snapshot.docs.isEmpty) throw Exception('User with email $email not found');

      await _firestore.collection('users').doc(snapshot.docs.first.id).update({'role': 'user'});
      AppLogger.info('✅ Successfully removed admin role for: $email');
    } catch (e) {
      AppLogger.error('❌ Error removing admin role', error: e);
      rethrow;
    }
  }

  // Xóa role admin theo UID
  Future<void> removeAdminByUid(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': 'user'});
      AppLogger.info('✅ Successfully removed admin role for UID: $uid');
    } catch (e) {
      AppLogger.error('❌ Error removing admin role', error: e);
      rethrow;
    }
  }

  // Lấy danh sách tất cả admin
  Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final snapshot = await _firestore.collection('users').where('role', isEqualTo: 'admin').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'uid': doc.id, 'email': data['email'], 'displayName': data['displayName'], 'username': data['username']};
      }).toList();
    } catch (e) {
      AppLogger.error('❌ Error getting admins', error: e);
      rethrow;
    }
  }

  // Migrate users cũ chưa có field role
  // Chạy 1 lần để cập nhật users hiện có
  Future<void> migrateExistingUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      int updated = 0;

      for (var doc in snapshot.docs) {
        if (!doc.data().containsKey('role')) {
          await _firestore.collection('users').doc(doc.id).update({'role': 'user'});
          updated++;
        }
      }

      AppLogger.info('✅ Migration complete. Updated $updated users.');
    } catch (e) {
      AppLogger.error('❌ Error during migration', error: e);
      rethrow;
    }
  }
}

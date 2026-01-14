import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility class to manage admin roles
/// Dùng để cập nhật role của users đã tồn tại
class AdminUtility {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Set admin role for a specific user by email
  /// Ví dụ: await AdminUtility().setAdminByEmail('user@example.com');
  Future<void> setAdminByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('User with email $email not found');
      }

      final userDoc = snapshot.docs.first;
      await _firestore.collection('users').doc(userDoc.id).update({
        'role': 'admin',
      });

      print('✅ Successfully set admin role for: $email');
    } catch (e) {
      print('❌ Error setting admin role: $e');
      rethrow;
    }
  }

  /// Set admin role for a specific user by UID
  /// Ví dụ: await AdminUtility().setAdminByUid('abc123xyz');
  Future<void> setAdminByUid(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        throw Exception('User with UID $uid not found');
      }

      await _firestore.collection('users').doc(uid).update({'role': 'admin'});

      print('✅ Successfully set admin role for UID: $uid');
    } catch (e) {
      print('❌ Error setting admin role: $e');
      rethrow;
    }
  }

  /// Remove admin role from a user by email
  /// Ví dụ: await AdminUtility().removeAdminByEmail('user@example.com');
  Future<void> removeAdminByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('User with email $email not found');
      }

      final userDoc = snapshot.docs.first;
      await _firestore.collection('users').doc(userDoc.id).update({
        'role': 'user',
      });

      print('✅ Successfully removed admin role for: $email');
    } catch (e) {
      print('❌ Error removing admin role: $e');
      rethrow;
    }
  }

  /// Remove admin role from a user by UID
  Future<void> removeAdminByUid(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': 'user'});

      print('✅ Successfully removed admin role for UID: $uid');
    } catch (e) {
      print('❌ Error removing admin role: $e');
      rethrow;
    }
  }

  /// Get list of all admins
  Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'email': data['email'],
          'displayName': data['displayName'],
          'username': data['username'],
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting admins: $e');
      rethrow;
    }
  }

  /// Update existing users to have 'user' role if they don't have role field
  /// Run this ONCE to migrate existing users
  Future<void> migrateExistingUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      int updated = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('role')) {
          await _firestore.collection('users').doc(doc.id).update({
            'role': 'user',
          });
          updated++;
        }
      }

      print('✅ Migration complete. Updated $updated users.');
    } catch (e) {
      print('❌ Error during migration: $e');
      rethrow;
    }
  }
}

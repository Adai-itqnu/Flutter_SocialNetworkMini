import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/report_model.dart';

/// Service quản lý admin
/// Bao gồm: quản lý user, quản lý bài viết, quản lý báo cáo, thống kê
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Quản lý User

  // Lấy tất cả users với phân trang
  Future<List<UserModel>> getAllUsers({int limit = 50}) async {
    try {
      final snapshot = await _firestore.collection('users').orderBy('createdAt', descending: true).limit(limit).get();
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách users: $e');
    }
  }

  // Tìm kiếm users theo username
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore.collection('users').where('username', isGreaterThanOrEqualTo: query).where('username', isLessThanOrEqualTo: '$query\uf8ff').limit(20).get();
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Lỗi khi tìm kiếm users: $e');
    }
  }

  // Chặn/Bỏ chặn user
  Future<void> toggleUserBlock(String userId, bool isBlocked) async {
    try {
      await _firestore.collection('users').doc(userId).update({'blocked': isBlocked});
    } catch (e) {
      throw Exception('Lỗi khi toggle block user: $e');
    }
  }

  // Xóa tài khoản user (chỉ admin)
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Lỗi khi xóa user: $e');
    }
  }

  // Quản lý Bài viết

  // Lấy tất cả bài viết với phân trang
  Future<List<PostModel>> getAllPosts({int limit = 50}) async {
    try {
      final snapshot = await _firestore.collection('posts').orderBy('createdAt', descending: true).limit(limit).get();
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách bài viết: $e');
    }
  }

  // Xóa bài viết bất kỳ (quyền admin)
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      throw Exception('Lỗi khi xóa bài viết: $e');
    }
  }

  // Quản lý Báo cáo

  // Tạo báo cáo
  Future<void> createReport({required String postId, required String reportedBy, required String postOwnerId, required String reason}) async {
    try {
      // Lấy thông tin bài viết để lưu snapshot
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      String? postCaption;
      List<String>? postImageUrls;

      if (postDoc.exists) {
        final postData = postDoc.data() as Map<String, dynamic>;
        postCaption = postData['caption'];
        postImageUrls = postData['imageUrls'] != null ? List<String>.from(postData['imageUrls']) : null;
      }

      final reportRef = _firestore.collection('reports').doc();
      final report = ReportModel(
        reportId: reportRef.id,
        postId: postId,
        reportedBy: reportedBy,
        postOwnerId: postOwnerId,
        reason: reason,
        createdAt: DateTime.now(),
        status: 'pending',
        postCaption: postCaption,
        postImageUrls: postImageUrls,
      );

      await reportRef.set(report.toJson());
    } catch (e) {
      throw Exception('Lỗi khi tạo báo cáo: $e');
    }
  }

  // Stream danh sách báo cáo
  Stream<List<ReportModel>> getReportsStream({String status = 'all'}) {
    return _firestore.collection('reports').snapshots().map((snapshot) {
      var reports = snapshot.docs.map((doc) => ReportModel.fromFirestore(doc)).toList();
      if (status != 'all') reports = reports.where((r) => r.status == status).toList();
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    });
  }

  // Cập nhật trạng thái báo cáo
  Future<void> updateReportStatus(String reportId, String status) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({'status': status});
    } catch (e) {
      throw Exception('Lỗi khi cập nhật trạng thái báo cáo: $e');
    }
  }

  // Xử lý báo cáo và xóa bài viết
  Future<void> resolveReportAndDeletePost(String reportId, String postId) async {
    try {
      await deletePost(postId);
      await updateReportStatus(reportId, 'resolved');
    } catch (e) {
      throw Exception('Lỗi khi xử lý báo cáo: $e');
    }
  }

  // Bỏ qua báo cáo
  Future<void> dismissReport(String reportId) async {
    try {
      await updateReportStatus(reportId, 'dismissed');
    } catch (e) {
      throw Exception('Lỗi khi bỏ qua báo cáo: $e');
    }
  }

  // Thống kê

  // Lấy thống kê dashboard
  Future<Map<String, int>> getDashboardStats() async {
    try {
      final usersCount = await _firestore.collection('users').count().get();
      final postsCount = await _firestore.collection('posts').count().get();
      final reportsCount = await _firestore.collection('reports').where('status', isEqualTo: 'pending').count().get();

      return {
        'users': usersCount.count ?? 0,
        'posts': postsCount.count ?? 0,
        'pendingReports': reportsCount.count ?? 0,
      };
    } catch (e) {
      throw Exception('Lỗi khi lấy thống kê: $e');
    }
  }
}

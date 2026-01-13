import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/report_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ USER MANAGEMENT ============

  // Get all users with pagination
  Future<List<UserModel>> getAllUsers({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  // Search users by username or email
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // Block/Unblock user (you can add a 'blocked' field to UserModel)
  Future<void> toggleUserBlock(String userId, bool isBlocked) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'blocked': isBlocked,
      });
    } catch (e) {
      throw Exception('Failed to toggle user block: $e');
    }
  }

  // Delete user account (admin only)
  Future<void> deleteUser(String userId) async {
    try {
      // Delete user document
      await _firestore.collection('users').doc(userId).delete();

      // Note: You may want to also delete user's posts, comments, etc.
      // This is a simplified version
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // ============ POST MANAGEMENT ============

  // Get all posts with pagination
  Future<List<PostModel>> getAllPosts({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get posts: $e');
    }
  }

  // Delete any post (admin power)
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // ============ REPORT MANAGEMENT ============

  // Create a report
  Future<void> createReport({
    required String postId,
    required String reportedBy,
    required String postOwnerId,
    required String reason,
  }) async {
    try {
      // Fetch post data to save snapshot
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      String? postCaption;
      List<String>? postImageUrls;

      if (postDoc.exists) {
        final postData = postDoc.data() as Map<String, dynamic>;
        postCaption = postData['caption'];
        postImageUrls = postData['imageUrls'] != null
            ? List<String>.from(postData['imageUrls'])
            : null;
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
      throw Exception('Failed to create report: $e');
    }
  }

  // Get all reports
  // Note: We fetch all and filter client-side to avoid composite index requirement
  Stream<List<ReportModel>> getReportsStream({String status = 'all'}) {
    return _firestore.collection('reports').snapshots().map((snapshot) {
      // Get all reports
      var reports = snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();

      // Filter by status if not 'all'
      if (status != 'all') {
        reports = reports.where((r) => r.status == status).toList();
      }

      // Sort by createdAt descending
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return reports;
    });
  }

  // Update report status
  Future<void> updateReportStatus(String reportId, String status) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }

  // Resolve report and delete post
  Future<void> resolveReportAndDeletePost(
    String reportId,
    String postId,
  ) async {
    try {
      // Delete the post
      await deletePost(postId);

      // Update report status
      await updateReportStatus(reportId, 'resolved');
    } catch (e) {
      throw Exception('Failed to resolve report: $e');
    }
  }

  // Dismiss report
  Future<void> dismissReport(String reportId) async {
    try {
      await updateReportStatus(reportId, 'dismissed');
    } catch (e) {
      throw Exception('Failed to dismiss report: $e');
    }
  }

  // ============ STATISTICS ============

  // Get dashboard statistics
  Future<Map<String, int>> getDashboardStats() async {
    try {
      final usersCount = await _firestore.collection('users').count().get();
      final postsCount = await _firestore.collection('posts').count().get();
      final reportsCount = await _firestore
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      return {
        'users': usersCount.count ?? 0,
        'posts': postsCount.count ?? 0,
        'pendingReports': reportsCount.count ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to get dashboard stats: $e');
    }
  }
}

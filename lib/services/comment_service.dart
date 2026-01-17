import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

/// Service xử lý Comment
/// Bao gồm: thêm, xóa, like comment, lấy replies
class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Thêm comment
  Future<String> addComment({required String postId, required String userId, required String text, String? parentCommentId}) async {
    try {
      final commentRef = _firestore.collection('comments').doc();
      final newComment = CommentModel(commentId: commentRef.id, postId: postId, userId: userId, text: text, parentCommentId: parentCommentId, createdAt: DateTime.now());

      await commentRef.set(newComment.toJson());
      await _firestore.collection('posts').doc(postId).update({'commentsCount': FieldValue.increment(1)});

      return commentRef.id;
    } catch (e) {
      throw Exception('Lỗi khi thêm comment: $e');
    }
  }

  // Lấy comments của bài viết
  Stream<List<CommentModel>> getComments(String postId) {
    return _firestore.collection('comments').where('postId', isEqualTo: postId).snapshots().map((snapshot) {
      final comments = snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList();
      comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return comments;
    });
  }

  // Lấy replies của comment
  Stream<List<CommentModel>> getReplies(String parentCommentId) {
    return _firestore.collection('comments').where('parentCommentId', isEqualTo: parentCommentId).snapshots().map((snapshot) {
      final replies = snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList();
      replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return replies;
    });
  }

  // Xóa comment
  Future<void> deleteComment(String commentId, String postId) async {
    try {
      await _firestore.collection('comments').doc(commentId).delete();
      await _firestore.collection('posts').doc(postId).update({'commentsCount': FieldValue.increment(-1)});
    } catch (e) {
      throw Exception('Lỗi khi xóa comment: $e');
    }
  }

  // Like comment
  Future<void> likeComment(String commentId, String userId) async {
    try {
      await _firestore.collection('comments').doc(commentId).update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Lỗi khi thích comment: $e');
    }
  }

  // Unlike comment
  Future<void> unlikeComment(String commentId, String userId) async {
    try {
      await _firestore.collection('comments').doc(commentId).update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likesCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Lỗi khi bỏ thích comment: $e');
    }
  }

  // Kiểm tra đã like chưa
  Future<bool> hasLikedComment(String commentId, String userId) async {
    try {
      final doc = await _firestore.collection('comments').doc(commentId).get();
      if (!doc.exists) return false;
      final likedBy = List<String>.from(doc.data()?['likedBy'] ?? []);
      return likedBy.contains(userId);
    } catch (e) {
      return false;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

/// Service xử lý các operations liên quan đến Comment
class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add comment to post
  Future<String> addComment({
    required String postId,
    required String userId,
    required String text,
    String? parentCommentId,
  }) async {
    try {
      final commentRef = _firestore.collection('comments').doc();

      CommentModel newComment = CommentModel(
        commentId: commentRef.id,
        postId: postId,
        userId: userId,
        text: text,
        parentCommentId: parentCommentId,
        createdAt: DateTime.now(),
      );

      await commentRef.set(newComment.toJson());

      // Increment post's comment count
      await _firestore.collection('posts').doc(postId).update({
        'commentsCount': FieldValue.increment(1),
      });

      return commentRef.id;
    } catch (e) {
      throw Exception('Lỗi khi thêm comment: $e');
    }
  }

  /// Get comments for a post
  Stream<List<CommentModel>> getComments(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((snapshot) {
          final comments = snapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc))
              .toList();
          comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return comments;
        });
  }

  /// Get replies for a comment
  Stream<List<CommentModel>> getReplies(String parentCommentId) {
    return _firestore
        .collection('comments')
        .where('parentCommentId', isEqualTo: parentCommentId)
        .snapshots()
        .map((snapshot) {
          final replies = snapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc))
              .toList();
          replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return replies;
        });
  }

  /// Delete comment
  Future<void> deleteComment(String commentId, String postId) async {
    try {
      await _firestore.collection('comments').doc(commentId).delete();

      await _firestore.collection('posts').doc(postId).update({
        'commentsCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Lỗi khi xóa comment: $e');
    }
  }

  /// Like a comment
  Future<void> likeComment(String commentId, String userId) async {
    try {
      final commentRef = _firestore.collection('comments').doc(commentId);

      await commentRef.update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Lỗi khi thích comment: $e');
    }
  }

  /// Unlike a comment
  Future<void> unlikeComment(String commentId, String userId) async {
    try {
      final commentRef = _firestore.collection('comments').doc(commentId);

      await commentRef.update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likesCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Lỗi khi bỏ thích comment: $e');
    }
  }

  /// Check if user liked a comment
  Future<bool> hasLikedComment(String commentId, String userId) async {
    try {
      final commentDoc = await _firestore
          .collection('comments')
          .doc(commentId)
          .get();
      if (!commentDoc.exists) return false;

      final data = commentDoc.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      return likedBy.contains(userId);
    } catch (e) {
      return false;
    }
  }
}

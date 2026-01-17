import 'package:cloud_firestore/cloud_firestore.dart';

/// Model bình luận trên bài viết
class CommentModel {
  final String commentId;          // ID bình luận
  final String postId;             // ID bài viết
  final String userId;             // ID người bình luận
  final String text;               // Nội dung bình luận
  final int likesCount;            // Số lượt thích
  final List<String> likedBy;      // Danh sách userId đã thích
  final String? parentCommentId;   // ID comment cha (nếu là reply)
  final DateTime createdAt;        // Thời gian tạo

  CommentModel({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.text,
    this.likesCount = 0,
    this.likedBy = const [],
    this.parentCommentId,
    required this.createdAt,
  });

  // Chuyển sang JSON để lưu Firestore
  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'postId': postId,
      'userId': userId,
      'text': text,
      'likesCount': likesCount,
      'likedBy': likedBy,
      'parentCommentId': parentCommentId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Tạo từ Firestore document
  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      commentId: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      text: data['text'] ?? '',
      likesCount: data['likesCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      parentCommentId: data['parentCommentId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Tạo từ JSON
  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      commentId: json['commentId'] ?? '',
      postId: json['postId'] ?? '',
      userId: json['userId'] ?? '',
      text: json['text'] ?? '',
      likesCount: json['likesCount'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      parentCommentId: json['parentCommentId'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt']),
    );
  }
}

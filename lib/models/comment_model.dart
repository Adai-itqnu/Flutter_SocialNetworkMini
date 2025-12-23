import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String commentId;
  final String postId;
  final String userId;
  final String text;
  final int likesCount;
  final List<String> likedBy; // List of user IDs who liked this comment
  final String? parentCommentId; // ID of parent comment if this is a reply
  final DateTime createdAt;

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

  // Convert CommentModel to JSON for Firestore
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

  // Create CommentModel from Firestore document
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

  // Create CommentModel from JSON
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

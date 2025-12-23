import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String userId;
  final String caption;
  final List<String> imageUrls;
  final int likesCount;
  final int commentsCount;
  final List<String> likedBy; // List of user IDs who liked this post
  final String? sharedPostId; // ID of the original post if this is a share
  final String?
  sharedUserId; // ID of the original post author if this is a share
  final DateTime createdAt;
  final DateTime updatedAt;

  PostModel({
    required this.postId,
    required this.userId,
    required this.caption,
    required this.imageUrls,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedBy = const [],
    this.sharedPostId,
    this.sharedUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert PostModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'userId': userId,
      'caption': caption,
      'imageUrls': imageUrls,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'likedBy': likedBy,
      'sharedPostId': sharedPostId,
      'sharedUserId': sharedUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create PostModel from Firestore document
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostModel(
      postId: doc.id,
      userId: data['userId'] ?? '',
      caption: data['caption'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      sharedPostId: data['sharedPostId'],
      sharedUserId: data['sharedUserId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Create PostModel from JSON
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      postId: json['postId'] ?? '',
      userId: json['userId'] ?? '',
      caption: json['caption'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      sharedPostId: json['sharedPostId'],
      sharedUserId: json['sharedUserId'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt']),
    );
  }

  // Copy with method for updates
  PostModel copyWith({
    String? postId,
    String? userId,
    String? caption,
    List<String>? imageUrls,
    int? likesCount,
    int? commentsCount,
    List<String>? likedBy,
    String? sharedPostId,
    String? sharedUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      caption: caption ?? this.caption,
      imageUrls: imageUrls ?? this.imageUrls,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likedBy: likedBy ?? this.likedBy,
      sharedPostId: sharedPostId ?? this.sharedPostId,
      sharedUserId: sharedUserId ?? this.sharedUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

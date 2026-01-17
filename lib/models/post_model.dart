import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum quyền riêng tư của bài viết
enum PostVisibility { 
  public,        // Công khai - ai cũng xem được
  followersOnly  // Chỉ người theo dõi
}

/// Model bài viết
class PostModel {
  final String postId;           // ID bài viết
  final String userId;           // ID người đăng
  final String caption;          // Nội dung caption
  final List<String> imageUrls;  // Danh sách URL ảnh
  final int likesCount;          // Số lượt thích
  final int commentsCount;       // Số bình luận
  final List<String> likedBy;    // Danh sách userId đã thích
  final String? sharedPostId;    // ID bài gốc nếu là bài share
  final String? sharedUserId;    // ID người đăng bài gốc
  final PostVisibility visibility; // Quyền riêng tư
  final DateTime createdAt;      // Thời gian tạo
  final DateTime updatedAt;      // Thời gian cập nhật

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
    this.visibility = PostVisibility.public,
    required this.createdAt,
    required this.updatedAt,
  });

  // Chuyển sang JSON để lưu Firestore
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
      'visibility': visibility.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Tạo từ Firestore document
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
      visibility: _parseVisibility(data['visibility']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Tạo từ JSON
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
      visibility: _parseVisibility(json['visibility']),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt']),
    );
  }

  // Parse string thành PostVisibility
  static PostVisibility _parseVisibility(String? value) {
    if (value == 'followersOnly') return PostVisibility.followersOnly;
    return PostVisibility.public;
  }

  // Tạo bản sao với các field được cập nhật
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
    PostVisibility? visibility,
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
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

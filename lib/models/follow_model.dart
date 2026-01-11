import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho mối quan hệ follow giữa 2 users
class FollowModel {
  final String followId;        // ID của document (format: followerId_followingId)
  final String followerId;      // ID người đi follow
  final String followingId;     // ID người được follow
  final DateTime createdAt;     // Thời điểm follow

  FollowModel({
    required this.followId,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'followId': followId,
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from Firestore document
  factory FollowModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FollowModel(
      followId: doc.id,
      followerId: data['followerId'] ?? '',
      followingId: data['followingId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Create from JSON
  factory FollowModel.fromJson(Map<String, dynamic> json) {
    return FollowModel(
      followId: json['followId'] ?? '',
      followerId: json['followerId'] ?? '',
      followingId: json['followingId'] ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt']),
    );
  }

  /// Helper: Generate follow document ID
  static String generateFollowId(String followerId, String followingId) {
    return '${followerId}_$followingId';
  }
}

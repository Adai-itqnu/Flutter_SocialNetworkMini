import 'package:cloud_firestore/cloud_firestore.dart';

/// Model báo cáo vi phạm bài viết
class ReportModel {
  final String reportId;          // ID báo cáo
  final String postId;            // ID bài viết bị báo cáo
  final String reportedBy;        // ID người báo cáo
  final String postOwnerId;       // ID chủ bài viết
  final String reason;            // Lý do báo cáo
  final DateTime createdAt;       // Thời gian báo cáo
  final String status;            // Trạng thái: 'pending', 'resolved', 'dismissed'
  
  // Snapshot của bài viết (giữ lại kể cả bài bị xóa)
  final String? postCaption;      // Caption bài viết
  final List<String>? postImageUrls; // Ảnh bài viết

  ReportModel({
    required this.reportId,
    required this.postId,
    required this.reportedBy,
    required this.postOwnerId,
    required this.reason,
    required this.createdAt,
    this.status = 'pending',
    this.postCaption,
    this.postImageUrls,
  });

  // Chuyển sang JSON để lưu Firestore
  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'postId': postId,
      'reportedBy': reportedBy,
      'postOwnerId': postOwnerId,
      'reason': reason,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'postCaption': postCaption,
      'postImageUrls': postImageUrls,
    };
  }

  // Tạo từ Firestore document
  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      reportId: doc.id,
      postId: data['postId'] ?? '',
      reportedBy: data['reportedBy'] ?? '',
      postOwnerId: data['postOwnerId'] ?? '',
      reason: data['reason'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      postCaption: data['postCaption'],
      postImageUrls: data['postImageUrls'] != null
          ? List<String>.from(data['postImageUrls'])
          : null,
    );
  }

  // Tạo từ JSON
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      reportId: json['reportId'] ?? '',
      postId: json['postId'] ?? '',
      reportedBy: json['reportedBy'] ?? '',
      postOwnerId: json['postOwnerId'] ?? '',
      reason: json['reason'] ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt']),
      status: json['status'] ?? 'pending',
      postCaption: json['postCaption'],
      postImageUrls: json['postImageUrls'] != null
          ? List<String>.from(json['postImageUrls'])
          : null,
    );
  }

  // Tạo bản sao với các field được cập nhật
  ReportModel copyWith({
    String? reportId,
    String? postId,
    String? reportedBy,
    String? postOwnerId,
    String? reason,
    DateTime? createdAt,
    String? status,
    String? postCaption,
    List<String>? postImageUrls,
  }) {
    return ReportModel(
      reportId: reportId ?? this.reportId,
      postId: postId ?? this.postId,
      reportedBy: reportedBy ?? this.reportedBy,
      postOwnerId: postOwnerId ?? this.postOwnerId,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      postCaption: postCaption ?? this.postCaption,
      postImageUrls: postImageUrls ?? this.postImageUrls,
    );
  }
}

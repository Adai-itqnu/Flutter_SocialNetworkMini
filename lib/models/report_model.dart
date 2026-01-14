import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String reportId;
  final String postId;
  final String reportedBy; // User ID who reported
  final String postOwnerId; // User ID of post owner
  final String reason;
  final DateTime createdAt;
  final String status; // 'pending', 'resolved', 'dismissed'

  // Snapshot of post data (preserved even if post is deleted)
  final String? postCaption;
  final List<String>? postImageUrls;

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

  // Convert ReportModel to JSON for Firestore
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

  // Create ReportModel from Firestore document
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

  // Create ReportModel from JSON
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

  // Copy with method for updates
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

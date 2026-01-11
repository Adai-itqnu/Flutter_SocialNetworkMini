import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification types enum
enum NotificationType {
  like,      // Ai đó thích bài viết của bạn
  comment,   // Ai đó bình luận bài viết của bạn
  follow,    // Ai đó bắt đầu follow bạn
  newPost,   // Người bạn follow đăng bài mới
  share,     // Ai đó chia sẻ bài viết của bạn
}

class NotificationModel {
  final String notificationId;
  final String fromUserId;     // Người tạo ra action (người like, comment, follow...)
  final String toUserId;       // Người nhận notification
  final NotificationType type;
  final String? postId;        // Post liên quan (nếu có)
  final String? commentText;   // Nội dung comment (nếu là comment notification)
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.fromUserId,
    required this.toUserId,
    required this.type,
    this.postId,
    this.commentText,
    this.isRead = false,
    required this.createdAt,
  });

  /// Convert NotificationType to string for Firestore
  static String typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return 'like';
      case NotificationType.comment:
        return 'comment';
      case NotificationType.follow:
        return 'follow';
      case NotificationType.newPost:
        return 'newPost';
      case NotificationType.share:
        return 'share';
    }
  }

  /// Convert string from Firestore to NotificationType
  static NotificationType stringToType(String type) {
    switch (type) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'newPost':
        return NotificationType.newPost;
      case 'share':
        return NotificationType.share;
      default:
        return NotificationType.like;
    }
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'type': typeToString(type),
      'postId': postId,
      'commentText': commentText,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      notificationId: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      type: stringToType(data['type'] ?? 'like'),
      postId: data['postId'],
      commentText: data['commentText'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Create from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'] ?? '',
      fromUserId: json['fromUserId'] ?? '',
      toUserId: json['toUserId'] ?? '',
      type: stringToType(json['type'] ?? 'like'),
      postId: json['postId'],
      commentText: json['commentText'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt']),
    );
  }

  /// Copy with method for updates
  NotificationModel copyWith({
    String? notificationId,
    String? fromUserId,
    String? toUserId,
    NotificationType? type,
    String? postId,
    String? commentText,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      type: type ?? this.type,
      postId: postId ?? this.postId,
      commentText: commentText ?? this.commentText,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get notification content based on type
  String getContent(String fromUserName) {
    switch (type) {
      case NotificationType.like:
        return 'đã thích bài viết của bạn';
      case NotificationType.comment:
        if (commentText != null && commentText!.isNotEmpty) {
          final truncated = commentText!.length > 50 
              ? '${commentText!.substring(0, 50)}...' 
              : commentText!;
          return 'đã bình luận: "$truncated"';
        }
        return 'đã bình luận bài viết của bạn';
      case NotificationType.follow:
        return 'đã bắt đầu theo dõi bạn';
      case NotificationType.newPost:
        return 'vừa đăng bài viết mới';
      case NotificationType.share:
        return 'đã chia sẻ bài viết của bạn';
    }
  }
}
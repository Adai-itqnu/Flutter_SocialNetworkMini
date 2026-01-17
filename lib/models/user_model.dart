import 'package:cloud_firestore/cloud_firestore.dart';

/// Model người dùng
class UserModel {
  final String uid;              // ID người dùng (Firebase Auth UID)
  final String email;            // Email
  final String username;         // Tên người dùng (unique, dùng cho @mention)
  final String displayName;      // Tên hiển thị
  final String? photoURL;        // URL ảnh đại diện
  final String? bio;             // Tiểu sử
  final String? pronouns;        // Đại từ nhân xưng
  final String? tagline;         // Khẩu hiệu
  final String? link;            // Link website/social
  final String? gender;          // Giới tính
  final int followersCount;      // Số người theo dõi
  final int followingCount;      // Số người đang theo dõi
  final int postsCount;          // Số bài viết
  final DateTime createdAt;      // Thời gian tạo tài khoản
  final String role;             // Vai trò: 'user' hoặc 'admin'

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.displayName,
    this.photoURL,
    this.bio,
    this.pronouns,
    this.tagline,
    this.link,
    this.gender,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    required this.createdAt,
    this.role = 'user',
  });

  // Chuyển sang JSON để lưu Firestore
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'displayName': displayName,
      'photoURL': photoURL,
      'bio': bio,
      'pronouns': pronouns,
      'tagline': tagline,
      'link': link,
      'gender': gender,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'role': role,
    };
  }

  // Tạo từ Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      bio: data['bio'],
      pronouns: data['pronouns'],
      tagline: data['tagline'],
      link: data['link'],
      gender: data['gender'],
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      postsCount: data['postsCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      role: data['role'] ?? 'user',
    );
  }

  // Tạo từ JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      displayName: json['displayName'] ?? '',
      photoURL: json['photoURL'],
      bio: json['bio'],
      pronouns: json['pronouns'],
      tagline: json['tagline'],
      link: json['link'],
      gender: json['gender'],
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      postsCount: json['postsCount'] ?? 0,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt']),
      role: json['role'] ?? 'user',
    );
  }

  // Tạo bản sao với các field được cập nhật
  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? displayName,
    String? photoURL,
    String? bio,
    String? pronouns,
    String? tagline,
    String? link,
    String? gender,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    DateTime? createdAt,
    String? role,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      pronouns: pronouns ?? this.pronouns,
      tagline: tagline ?? this.tagline,
      link: link ?? this.link,
      gender: gender ?? this.gender,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
    );
  }
}

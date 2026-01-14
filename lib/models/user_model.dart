import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String displayName;
  final String? photoURL;
  final String? bio;
  final String? pronouns;
  final String? tagline;
  final String? link;
  final String? gender;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final DateTime createdAt;
  final String role; // 'user' or 'admin'

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
    this.role = 'user', // Default role
  });

  // Convert UserModel to JSON for Firestore
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

  // Create UserModel from Firestore document
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

  // Create UserModel from JSON
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

  // Copy with method for updates
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

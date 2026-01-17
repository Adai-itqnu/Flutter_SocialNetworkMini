import 'package:cloud_firestore/cloud_firestore.dart';

/// Thông tin người tham gia trong phòng chat
class ParticipantInfo {
  final String displayName;
  final String username;
  final String? photoURL;

  ParticipantInfo({
    required this.displayName,
    required this.username,
    this.photoURL,
  });

  // Chuyển sang JSON để lưu Firestore
  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'username': username,
      'photoURL': photoURL,
    };
  }

  // Tạo từ JSON
  factory ParticipantInfo.fromJson(Map<String, dynamic> json) {
    return ParticipantInfo(
      displayName: json['displayName'] ?? '',
      username: json['username'] ?? '',
      photoURL: json['photoURL'],
    );
  }
}

/// Model phòng chat giữa 2 người dùng
class ChatRoomModel {
  final String chatId;                              // ID phòng chat
  final List<String> participants;                  // Danh sách ID người tham gia
  final Map<String, ParticipantInfo> participantDetails; // Thông tin chi tiết người tham gia
  final String? lastMessage;                        // Tin nhắn cuối cùng
  final DateTime? lastMessageTime;                  // Thời gian tin nhắn cuối
  final String? lastMessageSenderId;                // Người gửi tin nhắn cuối
  final DateTime createdAt;                         // Thời gian tạo phòng
  final DateTime updatedAt;                         // Thời gian cập nhật
  final Map<String, int> unreadCount;               // Số tin chưa đọc theo userId

  ChatRoomModel({
    required this.chatId,
    required this.participants,
    required this.participantDetails,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = const {},
  });

  // Chuyển sang JSON để lưu Firestore
  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'participants': participants,
      'participantDetails': participantDetails.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'lastMessageSenderId': lastMessageSenderId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'unreadCount': unreadCount,
    };
  }

  // Tạo từ Firestore document
  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse participantDetails map
    final participantDetailsData =
        data['participantDetails'] as Map<String, dynamic>? ?? {};
    final participantDetails = participantDetailsData.map(
      (key, value) => MapEntry(
        key,
        ParticipantInfo.fromJson(value as Map<String, dynamic>),
      ),
    );

    // Parse unreadCount map
    final unreadCountData = data['unreadCount'] as Map<String, dynamic>? ?? {};
    final unreadCount = unreadCountData.map(
      (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
    );

    return ChatRoomModel(
      chatId: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantDetails: participantDetails,
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastMessageSenderId: data['lastMessageSenderId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      unreadCount: unreadCount,
    );
  }

  // Lấy số tin chưa đọc của user
  int getUnreadCountFor(String userId) {
    return unreadCount[userId] ?? 0;
  }

  // Lấy thông tin người còn lại trong phòng chat (không phải current user)
  ParticipantInfo? getOtherParticipant(String currentUserId) {
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    return otherUserId.isNotEmpty ? participantDetails[otherUserId] : null;
  }
}

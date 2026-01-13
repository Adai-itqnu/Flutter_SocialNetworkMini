import 'package:cloud_firestore/cloud_firestore.dart';

class ParticipantInfo {
  final String displayName;
  final String username;
  final String? photoURL;

  ParticipantInfo({
    required this.displayName,
    required this.username,
    this.photoURL,
  });

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'username': username,
      'photoURL': photoURL,
    };
  }

  factory ParticipantInfo.fromJson(Map<String, dynamic> json) {
    return ParticipantInfo(
      displayName: json['displayName'] ?? '',
      username: json['username'] ?? '',
      photoURL: json['photoURL'],
    );
  }
}

class ChatRoomModel {
  final String chatId;
  final List<String> participants;
  final Map<String, ParticipantInfo> participantDetails;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatRoomModel({
    required this.chatId,
    required this.participants,
    required this.participantDetails,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    required this.createdAt,
    required this.updatedAt,
  });

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
    };
  }

  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final participantDetailsData = data['participantDetails'] as Map<String, dynamic>? ?? {};
    final participantDetails = participantDetailsData.map(
      (key, value) => MapEntry(
        key,
        ParticipantInfo.fromJson(value as Map<String, dynamic>),
      ),
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
    );
  }

  /// Get other participant info (not current user)
  ParticipantInfo? getOtherParticipant(String currentUserId) {
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    return otherUserId.isNotEmpty ? participantDetails[otherUserId] : null;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Model tin nhắn trong cuộc trò chuyện
class MessageModel {
  final String messageId;   // ID tin nhắn
  final String senderId;    // ID người gửi
  final String text;        // Nội dung (text hoặc [IMAGE]url)
  final DateTime timestamp; // Thời gian gửi
  final String type;        // Loại: "text", "image", "video"

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.type = 'text',
  });

  // Chuyển sang JSON để lưu Firestore
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
    };
  }

  // Tạo từ Firestore document
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      messageId: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: data['type'] ?? 'text',
    );
  }

  // Tạo từ JSON
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['messageId'] ?? '',
      senderId: json['senderId'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.parse(json['timestamp']),
      type: json['type'] ?? 'text',
    );
  }
}

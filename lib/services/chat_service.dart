import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

/// Service xử lý chat
/// Bao gồm: tạo phòng chat, gửi tin nhắn, đánh dấu đã đọc
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tạo ID chat từ 2 user ID (đảm bảo consistent)
  String generateChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Tạo hoặc lấy phòng chat giữa 2 users
  Future<ChatRoomModel> createOrGetChatRoom(String currentUserId, UserModel otherUser, UserModel currentUser) async {
    final chatId = generateChatId(currentUserId, otherUser.uid);
    final chatRef = _firestore.collection('chats').doc(chatId);
    final chatDoc = await chatRef.get();

    if (chatDoc.exists) return ChatRoomModel.fromFirestore(chatDoc);

    // Tạo phòng chat mới
    final now = DateTime.now();
    final newChatRoom = ChatRoomModel(
      chatId: chatId,
      participants: [currentUserId, otherUser.uid],
      participantDetails: {
        currentUserId: ParticipantInfo(displayName: currentUser.displayName, username: currentUser.username, photoURL: currentUser.photoURL),
        otherUser.uid: ParticipantInfo(displayName: otherUser.displayName, username: otherUser.username, photoURL: otherUser.photoURL),
      },
      createdAt: now,
      updatedAt: now,
    );

    await chatRef.set(newChatRoom.toJson());
    return newChatRoom;
  }

  // Gửi tin nhắn
  Future<void> sendMessage({required String chatId, required String senderId, required String text}) async {
    if (text.trim().isEmpty) return;

    final now = DateTime.now();
    
    // Lấy người nhận
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) return;
    
    final chatData = chatDoc.data() as Map<String, dynamic>;
    final participants = List<String>.from(chatData['participants'] ?? []);
    final recipientId = participants.firstWhere((id) => id != senderId, orElse: () => '');
    
    // Tạo tin nhắn
    final messageRef = _firestore.collection('chats').doc(chatId).collection('messages').doc();
    final message = MessageModel(messageId: messageRef.id, senderId: senderId, text: text.trim(), timestamp: now, type: 'text');

    // Dùng batch để update cả tin nhắn và room
    final batch = _firestore.batch();
    batch.set(messageRef, message.toJson());
    batch.update(_firestore.collection('chats').doc(chatId), {
      'lastMessage': text.trim(),
      'lastMessageTime': Timestamp.fromDate(now),
      'lastMessageSenderId': senderId,
      'updatedAt': Timestamp.fromDate(now),
      if (recipientId.isNotEmpty) 'unreadCount.$recipientId': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // Đánh dấu đã đọc
  Future<void> markAsRead(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({'unreadCount.$userId': 0});
  }

  // Lấy tổng số tin chưa đọc
  Future<int> getTotalUnreadCount(String userId) async {
    final snapshot = await _firestore.collection('chats').where('participants', arrayContains: userId).get();
    int total = 0;
    for (final doc in snapshot.docs) {
      final unreadCount = doc.data()['unreadCount'] as Map<String, dynamic>? ?? {};
      total += (unreadCount[userId] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  // Stream tổng số tin chưa đọc
  Stream<int> getTotalUnreadCountStream(String userId) {
    return _firestore.collection('chats').where('participants', arrayContains: userId).snapshots().map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        final unreadCount = doc.data()['unreadCount'] as Map<String, dynamic>? ?? {};
        total += (unreadCount[userId] as num?)?.toInt() ?? 0;
      }
      return total;
    });
  }

  // Stream tin nhắn (realtime)
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore.collection('chats').doc(chatId).collection('messages').orderBy('timestamp', descending: true).limit(100).snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList());
  }

  // Stream danh sách phòng chat
  Stream<List<ChatRoomModel>> getChatRooms(String userId) {
    return _firestore.collection('chats').where('participants', arrayContains: userId).snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ChatRoomModel.fromFirestore(doc)).toList());
  }

  // Lấy 1 phòng chat
  Future<ChatRoomModel?> getChatRoom(String chatId) async {
    final doc = await _firestore.collection('chats').doc(chatId).get();
    return doc.exists ? ChatRoomModel.fromFirestore(doc) : null;
  }
}

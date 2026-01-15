import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate consistent chat ID from two user IDs
  String generateChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Create or get existing chat room between two users
  Future<ChatRoomModel> createOrGetChatRoom(
    String currentUserId,
    UserModel otherUser,
    UserModel currentUser,
  ) async {
    final chatId = generateChatId(currentUserId, otherUser.uid);
    final chatRef = _firestore.collection('chats').doc(chatId);

    final chatDoc = await chatRef.get();

    if (chatDoc.exists) {
      // Chat room already exists
      return ChatRoomModel.fromFirestore(chatDoc);
    }

    // Create new chat room
    final now = DateTime.now();
    final newChatRoom = ChatRoomModel(
      chatId: chatId,
      participants: [currentUserId, otherUser.uid],
      participantDetails: {
        currentUserId: ParticipantInfo(
          displayName: currentUser.displayName,
          username: currentUser.username,
          photoURL: currentUser.photoURL,
        ),
        otherUser.uid: ParticipantInfo(
          displayName: otherUser.displayName,
          username: otherUser.username,
          photoURL: otherUser.photoURL,
        ),
      },
      createdAt: now,
      updatedAt: now,
    );

    await chatRef.set(newChatRoom.toJson());
    return newChatRoom;
  }

  /// Send a message in a chat room
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final now = DateTime.now();
    
    // Get chat room to find recipient
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) return;
    
    final chatData = chatDoc.data() as Map<String, dynamic>;
    final participants = List<String>.from(chatData['participants'] ?? []);
    final recipientId = participants.firstWhere(
      (id) => id != senderId,
      orElse: () => '',
    );
    
    // Create message document
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final message = MessageModel(
      messageId: messageRef.id,
      senderId: senderId,
      text: text.trim(),
      timestamp: now,
      type: 'text',
    );

    // Use batch write to update both message and chat room
    final batch = _firestore.batch();

    // Add message
    batch.set(messageRef, message.toJson());

    // Update chat room with last message info and increment unread count for recipient
    final chatRef = _firestore.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': text.trim(),
      'lastMessageTime': Timestamp.fromDate(now),
      'lastMessageSenderId': senderId,
      'updatedAt': Timestamp.fromDate(now),
      if (recipientId.isNotEmpty)
        'unreadCount.$recipientId': FieldValue.increment(1),
    });

    await batch.commit();
  }

  /// Mark all messages as read for a user in a chat room
  Future<void> markAsRead(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount.$userId': 0,
    });
  }

  /// Get total unread count for a user across all chats
  Future<int> getTotalUnreadCount(String userId) async {
    final snapshot = await _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .get();
    
    int total = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final unreadCount = data['unreadCount'] as Map<String, dynamic>? ?? {};
      total += (unreadCount[userId] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  /// Stream of total unread count for a user
  Stream<int> getTotalUnreadCountStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final unreadCount = data['unreadCount'] as Map<String, dynamic>? ?? {};
            total += (unreadCount[userId] as num?)?.toInt() ?? 0;
          }
          return total;
        });
  }

  /// Get messages stream for a chat room (realtime)
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  /// Get chat rooms for a user (realtime)
  Stream<List<ChatRoomModel>> getChatRooms(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoomModel.fromFirestore(doc))
            .toList());
  }

  /// Get a specific chat room
  Future<ChatRoomModel?> getChatRoom(String chatId) async {
    final doc = await _firestore.collection('chats').doc(chatId).get();
    if (doc.exists) {
      return ChatRoomModel.fromFirestore(doc);
    }
    return null;
  }
}

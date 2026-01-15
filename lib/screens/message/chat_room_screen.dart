import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/chat_room_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../../services/imgbb_service.dart';
import '../../services/active_chat_service.dart';
import '../profile/user_profile_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoomModel? chatRoom;
  final UserModel otherUser;
  final UserModel currentUser;

  const ChatRoomScreen({
    super.key,
    this.chatRoom,
    required this.otherUser,
    required this.currentUser,
  });

  static const routeName = '/chat-room';

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  ChatRoomModel? _chatRoom;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initChatRoom();
  }

  Future<void> _initChatRoom() async {
    if (widget.chatRoom != null) {
      setState(() {
        _chatRoom = widget.chatRoom;
        _isInitializing = false;
      });
      // Mark as read when opening existing chat room
      _markAsRead();
      return;
    }

    // Create or get chat room
    try {
      final room = await _chatService.createOrGetChatRoom(
        widget.currentUser.uid,
        widget.otherUser,
        widget.currentUser,
      );
      if (mounted) {
        setState(() {
          _chatRoom = room;
          _isInitializing = false;
        });
        // Mark as read when chat room is ready
        _markAsRead();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  /// Mark all messages as read for current user and set active chat
  void _markAsRead() {
    if (_chatRoom != null) {
      _chatService.markAsRead(_chatRoom!.chatId, widget.currentUser.uid);
      // Set this chat as active to suppress notifications
      ActiveChatService.setActiveChat(_chatRoom!.chatId);
    }
  }

  @override
  void dispose() {
    // Clear active chat when leaving
    ActiveChatService.clearActiveChat();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatRoom == null) return;

    _chatService.sendMessage(
      chatId: _chatRoom!.chatId,
      senderId: widget.currentUser.uid,
      text: text,
    );

    _messageController.clear();
    
    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.otherUser.displayName),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_chatRoom == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Không thể tải cuộc trò chuyện')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue[700],
              backgroundImage: widget.otherUser.photoURL != null &&
                      widget.otherUser.photoURL!.isNotEmpty
                  ? NetworkImage(widget.otherUser.photoURL!)
                  : null,
              child: widget.otherUser.photoURL == null ||
                      widget.otherUser.photoURL!.isEmpty
                  ? Text(
                      widget.otherUser.displayName.isNotEmpty
                          ? widget.otherUser.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.displayName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@${widget.otherUser.username}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.blue),
            onPressed: _showUserProfile,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(_chatRoom!.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final messages = snapshot.data ?? [];
                
                // Mark as read whenever we receive new messages while viewing
                if (messages.isNotEmpty) {
                  // Use Future.microtask to avoid calling during build
                  Future.microtask(() => _markAsRead());
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có tin nhắn',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gửi tin nhắn đầu tiên để bắt đầu cuộc trò chuyện',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  color: Colors.grey[50],
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Start from bottom
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isSent = message.senderId == widget.currentUser.uid;
                      
                      return _buildMessageBubble(message, isSent);
                    },
                  ),
                );
              },
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image, color: Colors.blue[700]),
                  onPressed: _pickAndSendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Aa',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue[700]),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pick image and send to chat
  Future<void> _pickAndSendImage() async {
    if (_chatRoom == null) return;

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      
      if (image == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang gửi ảnh...'), duration: Duration(seconds: 2)),
      );

      final imageUrl = await ImgBBService.uploadImage(image);
      
      await _chatService.sendMessage(
        chatId: _chatRoom!.chatId,
        senderId: widget.currentUser.uid,
        text: '[IMAGE]$imageUrl',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi ảnh: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Show user profile
  void _showUserProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: widget.otherUser.uid),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isSent) {
    // Check if message contains image
    final isImage = message.text.startsWith('[IMAGE]');
    final imageUrl = isImage ? message.text.substring(7) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.blue[700],
              backgroundImage: widget.otherUser.photoURL != null &&
                      widget.otherUser.photoURL!.isNotEmpty
                  ? NetworkImage(widget.otherUser.photoURL!)
                  : null,
              child: widget.otherUser.photoURL == null ||
                      widget.otherUser.photoURL!.isEmpty
                  ? Text(
                      widget.otherUser.displayName.isNotEmpty
                          ? widget.otherUser.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (isImage && imageUrl != null)
                  // Image message
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GestureDetector(
                      onTap: () => _showFullImage(imageUrl),
                      child: Image.network(
                        imageUrl,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: 200, height: 200,
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stack) => Container(
                          width: 200, height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 40),
                        ),
                      ),
                    ),
                  )
                else
                  // Text message
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSent ? Colors.blue[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: isSent ? Colors.white : Colors.black,
                        fontSize: 15,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show full image in dialog
  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}

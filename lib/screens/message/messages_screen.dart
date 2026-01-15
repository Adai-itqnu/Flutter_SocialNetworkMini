import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/follow_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../models/chat_room_model.dart';
import '../../models/message_model.dart';
import '../../services/chat_service.dart';
import '../../services/imgbb_service.dart';
import '../profile/user_profile_screen.dart';
import 'chat_room_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  static const routeName = '/messages';

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  int? _selectedChatIndex;
  UserModel? _selectedUser;
  ChatRoomModel? _currentChatRoom;
  bool _isLoadingChat = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final followProvider = context.read<FollowProvider>();
      
      if (authProvider.userModel != null) {
        followProvider.loadFollowData(authProvider.userModel!.uid);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectUser(int index, UserModel user) async {
    setState(() {
      _selectedChatIndex = index;
      _selectedUser = user;
      _isLoadingChat = true;
    });

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) {
      setState(() => _isLoadingChat = false);
      return;
    }

    try {
      final chatRoom = await _chatService.createOrGetChatRoom(
        currentUser.uid,
        user,
        currentUser,
      );
      setState(() {
        _currentChatRoom = chatRoom;
        _isLoadingChat = false;
      });
    } catch (e) {
      setState(() => _isLoadingChat = false);
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentChatRoom == null) return;

    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.userModel?.uid;
    if (currentUserId == null) return;

    _chatService.sendMessage(
      chatId: _currentChatRoom!.chatId,
      senderId: currentUserId,
      text: text,
    );

    _messageController.clear();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  /// Show user profile screen
  void _showUserProfile(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: user.uid),
      ),
    );
  }

  /// Pick image and send to chat
  Future<void> _pickAndSendImage() async {
    if (_currentChatRoom == null || _selectedUser == null) return;
    
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.userModel?.uid;
    if (currentUserId == null) return;

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      
      if (image == null) return;

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang gửi ảnh...'), duration: Duration(seconds: 2)),
      );

      // Upload to ImgBB
      final imageUrl = await ImgBBService.uploadImage(image);
      
      // Send image as message
      await _chatService.sendMessage(
        chatId: _currentChatRoom!.chatId,
        senderId: currentUserId,
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

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder for responsive design
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile layout: only show chat list, tap navigates to chat room
        final isMobile = constraints.maxWidth < 600;
        
        if (isMobile) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Tin nhắn', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              actions: [
                IconButton(icon: const Icon(Icons.more_horiz, color: Colors.black), onPressed: () {}),
                IconButton(icon: const Icon(Icons.edit_square, color: Colors.black), onPressed: () {}),
              ],
            ),
            body: _buildMobileChatList(),
          );
        }
        
        // Desktop/Tablet layout: side by side
        return Scaffold(
          backgroundColor: Colors.white,
          body: Row(
            children: [
              _buildChatList(),
              Container(width: 1, color: Colors.grey[300]),
              Expanded(flex: 2, child: _buildChatConversation()),
            ],
          ),
        );
      },
    );
  }

  /// Mobile chat list - tap to navigate to chat room
  Widget _buildMobileChatList() {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.userModel?.uid;

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm trên Messenger',
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        // Chat List - now using ChatRooms directly (no follow requirement)
        Expanded(
          child: currentUserId == null
              ? const Center(child: Text('Vui lòng đăng nhập'))
              : StreamBuilder<List<ChatRoomModel>>(
                  stream: _chatService.getChatRooms(currentUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final chatRooms = snapshot.data ?? [];
                    
                    if (chatRooms.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('Chưa có tin nhắn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                            const SizedBox(height: 8),
                            Text('Nhắn tin với ai đó để bắt đầu', style: TextStyle(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
                          ],
                        ),
                      );
                    }

                    // Sort by last message time (newest first)
                    final sortedRooms = List<ChatRoomModel>.from(chatRooms)
                      ..sort((a, b) {
                        final timeA = a.lastMessageTime;
                        final timeB = b.lastMessageTime;
                        if (timeA == null && timeB == null) return 0;
                        if (timeA == null) return 1;
                        if (timeB == null) return -1;
                        return timeB.compareTo(timeA);
                      });

                    return ListView.builder(
                      itemCount: sortedRooms.length,
                      itemBuilder: (context, index) {
                        final room = sortedRooms[index];
                        final otherParticipant = room.getOtherParticipant(currentUserId);
                        final unreadCount = room.getUnreadCountFor(currentUserId);
                        final hasUnread = unreadCount > 0;
                        
                        if (otherParticipant == null) return const SizedBox.shrink();
                        
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.blue[700],
                            backgroundImage: otherParticipant.photoURL != null && otherParticipant.photoURL!.isNotEmpty 
                                ? NetworkImage(otherParticipant.photoURL!) 
                                : null,
                            child: otherParticipant.photoURL == null || otherParticipant.photoURL!.isEmpty
                                ? Text(
                                    otherParticipant.displayName.isNotEmpty ? otherParticipant.displayName[0].toUpperCase() : 'U',
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          title: Text(
                            otherParticipant.displayName,
                            style: TextStyle(
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                              color: hasUnread ? Colors.black : Colors.grey[800],
                            ),
                          ),
                          subtitle: Text(
                            room.lastMessage ?? 'Bắt đầu trò chuyện',
                            style: TextStyle(
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                              color: hasUnread ? Colors.black87 : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: hasUnread
                              ? Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[700],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                )
                              : null,
                          onTap: () => _openChatRoomFromRoom(room, currentUserId),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Open chat room from ChatRoomModel
  Future<void> _openChatRoomFromRoom(ChatRoomModel room, String currentUserId) async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userModel;
    if (currentUser == null) return;

    // Mark as read when opening
    await _chatService.markAsRead(room.chatId, currentUserId);

    // Get other user info
    final otherUserId = room.participants.firstWhere((id) => id != currentUserId, orElse: () => '');
    final otherParticipant = room.participantDetails[otherUserId];
    
    if (otherParticipant == null) return;

    // Create UserModel from ParticipantInfo for ChatRoomScreen
    final otherUser = UserModel(
      uid: otherUserId,
      email: '',
      username: otherParticipant.username,
      displayName: otherParticipant.displayName,
      photoURL: otherParticipant.photoURL,
      createdAt: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          chatRoom: room,
          otherUser: otherUser,
          currentUser: currentUser,
        ),
      ),
    );
  }

  Widget _buildChatList() {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.userModel?.uid;

    return Container(
      width: 360,
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text('Tin nhắn', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.more_horiz, color: Colors.black), onPressed: () {}),
                IconButton(icon: const Icon(Icons.edit_square, color: Colors.black), onPressed: () {}),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm trên Messenger',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          // Chat List - using ChatRooms directly
          Expanded(
            child: currentUserId == null
                ? const Center(child: Text('Vui lòng đăng nhập'))
                : StreamBuilder<List<ChatRoomModel>>(
                    stream: _chatService.getChatRooms(currentUserId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final chatRooms = snapshot.data ?? [];
                      
                      if (chatRooms.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('Chưa có tin nhắn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                              const SizedBox(height: 8),
                              Text('Nhắn tin với ai đó để bắt đầu', style: TextStyle(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
                            ],
                          ),
                        );
                      }

                      // Sort by last message time (newest first)
                      final sortedRooms = List<ChatRoomModel>.from(chatRooms)
                        ..sort((a, b) {
                          final timeA = a.lastMessageTime;
                          final timeB = b.lastMessageTime;
                          if (timeA == null && timeB == null) return 0;
                          if (timeA == null) return 1;
                          if (timeB == null) return -1;
                          return timeB.compareTo(timeA);
                        });

                      return ListView.builder(
                        itemCount: sortedRooms.length,
                        itemBuilder: (context, index) {
                          final room = sortedRooms[index];
                          final otherParticipant = room.getOtherParticipant(currentUserId);
                          final unreadCount = room.getUnreadCountFor(currentUserId);
                          final hasUnread = unreadCount > 0;
                          final otherUserId = room.participants.firstWhere((id) => id != currentUserId, orElse: () => '');
                          final isSelected = _selectedUser?.uid == otherUserId;
                          
                          if (otherParticipant == null) return const SizedBox.shrink();
                          
                          return InkWell(
                            onTap: () => _selectUserFromRoom(room, currentUserId),
                            child: Container(
                              color: isSelected ? Colors.grey[200] : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.blue[700],
                                    backgroundImage: otherParticipant.photoURL != null && otherParticipant.photoURL!.isNotEmpty 
                                        ? NetworkImage(otherParticipant.photoURL!) 
                                        : null,
                                    child: otherParticipant.photoURL == null || otherParticipant.photoURL!.isEmpty
                                        ? Text(
                                            otherParticipant.displayName.isNotEmpty ? otherParticipant.displayName[0].toUpperCase() : 'U',
                                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          otherParticipant.displayName,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                                            color: hasUnread ? Colors.black : Colors.grey[800],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          room.lastMessage ?? 'Bắt đầu trò chuyện',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                            color: hasUnread ? Colors.black87 : Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (hasUnread)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[700],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Select user from ChatRoomModel for desktop view
  Future<void> _selectUserFromRoom(ChatRoomModel room, String currentUserId) async {
    // Mark as read
    await _chatService.markAsRead(room.chatId, currentUserId);

    // Get other user info
    final otherUserId = room.participants.firstWhere((id) => id != currentUserId, orElse: () => '');
    final otherParticipant = room.participantDetails[otherUserId];
    
    if (otherParticipant == null) return;

    // Create UserModel from ParticipantInfo
    final otherUser = UserModel(
      uid: otherUserId,
      email: '',
      username: otherParticipant.username,
      displayName: otherParticipant.displayName,
      photoURL: otherParticipant.photoURL,
      createdAt: DateTime.now(),
    );

    setState(() {
      _selectedUser = otherUser;
      _currentChatRoom = room;
      _isLoadingChat = false;
    });
  }

  Widget _buildChatConversation() {
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.userModel?.uid ?? '';

    if (_selectedUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Chọn một cuộc trò chuyện', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Chọn từ danh sách bên trái để bắt đầu chat', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      );
    }

    final selectedUser = _selectedUser!;

    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1))),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue[700],
                backgroundImage: selectedUser.photoURL != null && selectedUser.photoURL!.isNotEmpty ? NetworkImage(selectedUser.photoURL!) : null,
                child: selectedUser.photoURL == null || selectedUser.photoURL!.isEmpty
                    ? Text(selectedUser.displayName.isNotEmpty ? selectedUser.displayName[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selectedUser.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('@${selectedUser.username}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.blue), 
                onPressed: () => _showUserProfile(selectedUser),
              ),
            ],
          ),
        ),

        // Messages Area
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: _isLoadingChat
                ? const Center(child: CircularProgressIndicator())
                : _currentChatRoom == null
                    ? const Center(child: Text('Không thể tải cuộc trò chuyện'))
                    : StreamBuilder<List<MessageModel>>(
                        stream: _chatService.getMessages(_currentChatRoom!.chatId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final messages = snapshot.data ?? [];

                          if (messages.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text('Chưa có tin nhắn', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                                  const SizedBox(height: 8),
                                  Text('Gửi tin nhắn đầu tiên!', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isSent = message.senderId == currentUserId;
                              return _buildMessageBubble(message, isSent);
                            },
                          );
                        },
                      ),
          ),
        ),

        // Message Input
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1))),
          child: Row(
            children: [
              IconButton(icon: Icon(Icons.image, color: Colors.blue[700]), onPressed: _pickAndSendImage),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Aa',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(icon: Icon(Icons.send, color: Colors.blue[700]), onPressed: _sendMessage),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isSent) {
    // Check if message contains image
    final isImage = message.text.startsWith('[IMAGE]');
    final imageUrl = isImage ? message.text.substring(7) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent && _selectedUser != null) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.blue[700],
              backgroundImage: _selectedUser!.photoURL != null && _selectedUser!.photoURL!.isNotEmpty ? NetworkImage(_selectedUser!.photoURL!) : null,
              child: _selectedUser!.photoURL == null || _selectedUser!.photoURL!.isEmpty
                  ? Text(_selectedUser!.displayName.isNotEmpty ? _selectedUser!.displayName[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSent ? Colors.blue[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(message.text, style: TextStyle(color: isSent ? Colors.white : Colors.black, fontSize: 15)),
                  ),
                const SizedBox(height: 4),
                Text(_formatTime(message.timestamp), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
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

  Widget _buildLastMessage(UserModel user) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.userModel?.uid;
    
    if (currentUserId == null) {
      return Text('Bắt đầu trò chuyện', style: TextStyle(fontSize: 14, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final chatId = _chatService.generateChatId(currentUserId, user.uid);
    
    return StreamBuilder<List<MessageModel>>(
      stream: _chatService.getMessages(chatId),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final lastMessage = snapshot.data!.first;
          final isSent = lastMessage.senderId == currentUserId;
          final prefix = isSent ? 'Bạn: ' : '';
          return Text(
            '$prefix${lastMessage.text}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
        return Text('Bắt đầu trò chuyện', style: TextStyle(fontSize: 14, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis);
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays > 0) return '${difference.inDays} ngày trước';
    if (difference.inHours > 0) return '${difference.inHours} giờ trước';
    if (difference.inMinutes > 0) return '${difference.inMinutes} phút trước';
    return 'Vừa xong';
  }
}

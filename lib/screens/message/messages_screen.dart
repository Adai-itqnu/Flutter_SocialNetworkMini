import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/follow_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../models/chat_room_model.dart';
import '../../models/message_model.dart';
import '../../services/chat_service.dart';

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

  @override
  Widget build(BuildContext context) {
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
  }

  Widget _buildChatList() {
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
          // Chat List
          Expanded(
            child: Consumer<FollowProvider>(
              builder: (context, followProvider, _) {
                final followingUsers = followProvider.following;
                final authProvider = context.read<AuthProvider>();
                final currentUserId = authProvider.userModel?.uid;

                if (followProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (followingUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Chưa follow ai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                        const SizedBox(height: 8),
                        Text('Hãy follow bạn bè để bắt đầu chat', style: TextStyle(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }

                // Use StreamBuilder to listen to chat rooms for sorting
                return StreamBuilder<List<ChatRoomModel>>(
                  stream: currentUserId != null ? _chatService.getChatRooms(currentUserId) : null,
                  builder: (context, chatRoomsSnapshot) {
                    // Create map of userId -> lastMessageTime
                    final Map<String, DateTime?> lastMessageTimes = {};
                    if (chatRoomsSnapshot.hasData) {
                      for (final room in chatRoomsSnapshot.data!) {
                        final otherUserId = room.participants.firstWhere(
                          (id) => id != currentUserId,
                          orElse: () => '',
                        );
                        if (otherUserId.isNotEmpty) {
                          lastMessageTimes[otherUserId] = room.lastMessageTime;
                        }
                      }
                    }

                    // Sort following users by lastMessageTime
                    final sortedUsers = List<UserModel>.from(followingUsers);
                    sortedUsers.sort((a, b) {
                      final timeA = lastMessageTimes[a.uid];
                      final timeB = lastMessageTimes[b.uid];
                      if (timeA == null && timeB == null) return 0;
                      if (timeA == null) return 1;
                      if (timeB == null) return -1;
                      return timeB.compareTo(timeA); // Newest first
                    });

                    return ListView.builder(
                      itemCount: sortedUsers.length,
                      itemBuilder: (context, index) {
                        final user = sortedUsers[index];
                        final isSelected = _selectedUser?.uid == user.uid;
                        
                        return InkWell(
                          onTap: () => _selectUser(index, user),
                          child: Container(
                            color: isSelected ? Colors.grey[200] : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.blue[700],
                                  backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty ? NetworkImage(user.photoURL!) : null,
                                  child: user.photoURL == null || user.photoURL!.isEmpty
                                      ? Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(user.displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      _buildLastMessage(user),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
              IconButton(icon: const Icon(Icons.call, color: Colors.blue), onPressed: () {}),
              IconButton(icon: const Icon(Icons.videocam, color: Colors.blue), onPressed: () {}),
              IconButton(icon: const Icon(Icons.info_outline, color: Colors.blue), onPressed: () {}),
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
              IconButton(icon: Icon(Icons.add_circle, color: Colors.blue[700]), onPressed: () {}),
              IconButton(icon: Icon(Icons.image, color: Colors.blue[700]), onPressed: () {}),
              IconButton(icon: Icon(Icons.mic, color: Colors.blue[700]), onPressed: () {}),
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

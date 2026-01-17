import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../models/chat_room_model.dart';
import '../../services/chat_service.dart';
import 'chat_room_screen.dart';

/// Hiển thị danh sách các cuộc trò chuyện, tap để mở ChatRoomScreen
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  static const routeName = '/messages';

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tin nhắn',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildChatRoomsList()),
        ],
      ),
    );
  }

  /// Search bar để tìm kiếm theo tên người dùng
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase().trim();
          });
        },
        decoration: InputDecoration(
          hintText: 'Tìm kiếm trên Messenger',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  /// Danh sách các phòng chat
  Widget _buildChatRoomsList() {
    final currentUserId = context.read<AuthProvider>().userModel?.uid;

    if (currentUserId == null) {
      return const Center(child: Text('Vui lòng đăng nhập'));
    }

    return StreamBuilder<List<ChatRoomModel>>(
      stream: _chatService.getChatRooms(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final chatRooms = snapshot.data ?? [];

        if (chatRooms.isEmpty) {
          return _buildEmptyState();
        }

        final filteredRooms = _filterAndSortRooms(chatRooms, currentUserId);

        if (filteredRooms.isEmpty && _searchQuery.isNotEmpty) {
          return _buildNoResultsState();
        }

        return ListView.builder(
          itemCount: filteredRooms.length,
          itemBuilder: (context, index) {
            final room = filteredRooms[index];
            return _buildChatRoomTile(room, currentUserId);
          },
        );
      },
    );
  }

  /// Hiển thị 1 phòng chat trong danh sách
  Widget _buildChatRoomTile(ChatRoomModel room, String currentUserId) {
    final otherParticipant = room.getOtherParticipant(currentUserId);
    if (otherParticipant == null) return const SizedBox.shrink();

    final unreadCount = room.getUnreadCountFor(currentUserId);
    final hasUnread = unreadCount > 0;

    return ListTile(
      leading: _buildUserAvatar(otherParticipant),
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
      trailing: hasUnread ? _buildUnreadBadge(unreadCount) : null,
      onTap: () => _openChatRoom(room, currentUserId),
    );
  }

  /// Mở ChatRoomScreen
  Future<void> _openChatRoom(ChatRoomModel room, String currentUserId) async {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) return;

    // Đánh dấu đã đọc
    await _chatService.markAsRead(room.chatId, currentUserId);

    // Lấy thông tin user khác
    final otherUser = _createUserFromRoom(room, currentUserId);
    if (otherUser == null) return;

    if (!mounted) return;
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

  // ==================== WIDGETS ====================

  /// Avatar người dùng
  Widget _buildUserAvatar(ParticipantInfo participant) {
    final hasPhoto = participant.photoURL != null && participant.photoURL!.isNotEmpty;

    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.blue[700],
      backgroundImage: hasPhoto ? NetworkImage(participant.photoURL!) : null,
      child: !hasPhoto
          ? Text(
              participant.displayName.isNotEmpty
                  ? participant.displayName[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  /// Badge số tin chưa đọc
  Widget _buildUnreadBadge(int count) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        shape: BoxShape.circle,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// State khi chưa có tin nhắn
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có tin nhắn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhắn tin với ai đó để bắt đầu',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// State khi không tìm thấy kết quả
  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy "$_searchQuery"',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  /// Lọc và sắp xếp danh sách phòng chat
  List<ChatRoomModel> _filterAndSortRooms(
    List<ChatRoomModel> rooms,
    String currentUserId,
  ) {
    var filteredRooms = rooms.where((room) {
      if (_searchQuery.isEmpty) return true;
      final otherParticipant = room.getOtherParticipant(currentUserId);
      if (otherParticipant == null) return false;
      final displayName = otherParticipant.displayName.toLowerCase();
      final username = otherParticipant.username.toLowerCase();
      return displayName.contains(_searchQuery) || username.contains(_searchQuery);
    }).toList();

    filteredRooms.sort((a, b) {
      final timeA = a.lastMessageTime;
      final timeB = b.lastMessageTime;
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      return timeB.compareTo(timeA);
    });

    return filteredRooms;
  }

  /// Tạo UserModel từ ChatRoomModel
  UserModel? _createUserFromRoom(ChatRoomModel room, String currentUserId) {
    final otherUserId = room.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    final otherParticipant = room.participantDetails[otherUserId];

    if (otherParticipant == null) return null;

    return UserModel(
      uid: otherUserId,
      email: '',
      username: otherParticipant.username,
      displayName: otherParticipant.displayName,
      photoURL: otherParticipant.photoURL,
      createdAt: DateTime.now(),
    );
  }
}

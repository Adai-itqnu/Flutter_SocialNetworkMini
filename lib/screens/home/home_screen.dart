import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/post_card.dart';
import 'create_post_screen.dart';
import 'search_screen.dart';
import '../notification/notifications_screen.dart';
import '../message/messages_screen.dart';
import '../follow/my_follow_screen.dart';
import '../profile/profile_screen.dart';

/// Màn hình chính của ứng dụng
/// Chứa 4 tab: Home Feed, Search, Follow, Profile
/// AppBar có logo, chat button và notification button
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isAddPressed = false;
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  // Trạng thái ẩn/hiện title khi scroll
  bool _showTitle = true;
  double _lastScrollOffset = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _tabs = [
      _buildHomeContent(),
      const SearchScreen(),
      const MyFollowScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Ẩn/hiện title khi scroll
  void _onScroll() {
    final offset = _scrollController.offset;
    if (offset > _lastScrollOffset && offset > 50) {
      // Scroll xuống -> ẩn title
      if (_showTitle) setState(() => _showTitle = false);
    } else if (offset < _lastScrollOffset) {
      // Scroll lên -> hiện title
      if (!_showTitle) setState(() => _showTitle = true);
    }
    _lastScrollOffset = offset;
  }

  // Xử lý khi tap vào item trong bottom nav
  Future<void> _onNavTapped(int index) async {
    if (index == 2) {
      // Nút "+" tạo bài viết
      setState(() => _isAddPressed = true);
      await _openCreateOptions();
      setState(() => _isAddPressed = false);
      return;
    }

    final stackIndex = index < 2 ? index : index - 1;

    if (_selectedIndex == stackIndex && stackIndex == 0) {
      // Tap lại Home -> scroll lên đầu
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    } else if (_selectedIndex != stackIndex) {
      setState(() => _selectedIndex = stackIndex);
    }
  }

  // Hiện bottom sheet chọn loại bài viết
  Future<void> _openCreateOptions() {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.post_add_outlined),
              title: const Text('Tạo bài viết'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // AppBar với logo, chat và notification
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: _showTitle ? 0 : 0.5,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipOval(
          child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
        ),
      ),
      title: AnimatedOpacity(
        opacity: _showTitle ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: const Text(
          'SNMini',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        _buildChatButton(),
        _buildNotificationButton(),
      ],
    );
  }

  // Nút chat với badge số tin chưa đọc
  Widget _buildChatButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final currentUserId = authProvider.userModel?.uid;
        if (currentUserId == null) {
          return IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MessagesScreen()),
            ),
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.black),
          );
        }

        return StreamBuilder<int>(
          stream: _chatService.getTotalUnreadCountStream(currentUserId),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;

            return IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MessagesScreen()),
              ),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Colors.black),
                  if (unreadCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: _buildBadge(unreadCount),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Nút notification với badge
  Widget _buildNotificationButton() {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        final unreadCount = notificationProvider.unreadCount;

        return IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.black),
              if (unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: _buildBadge(unreadCount),
                ),
            ],
          ),
        );
      },
    );
  }

  // Badge hiển thị số
  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Bottom navigation bar
  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: SafeArea(
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(index: 0, icon: Icons.home_outlined, activeIcon: Icons.home),
              _buildNavItem(index: 1, icon: Icons.search_outlined, activeIcon: Icons.search),
              _buildAddButton(),
              _buildNavItem(index: 3, icon: Icons.group_outlined, activeIcon: Icons.group),
              _buildProfileItem(index: 4),
            ],
          ),
        ),
      ),
    );
  }

  // Item trong bottom nav
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final stackIndex = index < 2 ? index : index - 1;
    final bool selected = _selectedIndex == stackIndex;
    final Color iconColor = selected ? Colors.black : Colors.black54;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.black.withOpacity(0.06),
        highlightColor: Colors.black.withOpacity(0.02),
        onTap: () => _onNavTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: selected ? Colors.grey.shade200 : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(selected ? activeIcon : icon, size: 24, color: iconColor),
        ),
      ),
    );
  }

  // Nút "+" tạo bài viết
  Widget _buildAddButton() {
    final double scale = _isAddPressed ? 0.9 : 1.0;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        splashColor: Colors.black.withOpacity(0.08),
        highlightColor: Colors.black.withOpacity(0.02),
        onTap: () => _onNavTapped(2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          width: 34,
          height: 34,
          transform: Matrix4.identity()..scale(scale),
          decoration: BoxDecoration(
            color: _isAddPressed ? Colors.black.withOpacity(0.04) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: Colors.black,
              width: _isAddPressed ? 2.2 : 1.8,
            ),
          ),
          child: const Icon(Icons.add, size: 22, color: Colors.black),
        ),
      ),
    );
  }

  // Avatar profile trong bottom nav
  Widget _buildProfileItem({required int index}) {
    final stackIndex = index - 1;
    final bool selected = _selectedIndex == stackIndex;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final photoURL = authProvider.userModel?.photoURL;

        return InkWell(
          onTap: () => _onNavTapped(index),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: selected ? Colors.grey.shade200 : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.black : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey[300],
                backgroundImage: photoURL != null && photoURL.isNotEmpty
                    ? NetworkImage(photoURL)
                    : null,
                child: photoURL == null || photoURL.isEmpty
                    ? const Icon(Icons.person, size: 16, color: Colors.grey)
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }

  // Tab Home - hiển thị danh sách bài viết
  Widget _buildHomeContent() {
    return Consumer2<PostProvider, AuthProvider>(
      builder: (context, postProvider, authProvider, _) {
        final posts = postProvider.posts;

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Loading
            if (postProvider.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            // Chưa có bài viết
            else if (posts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Chưa có bài viết nào', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('Hãy tạo bài viết đầu tiên!', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                ),
              )
            // Danh sách bài viết
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  childCount: posts.length,
                  (context, index) {
                    final post = posts[index];
                    final author = postProvider.getPostAuthor(post.userId);

                    return Column(
                      children: [
                        PostCard(key: ValueKey(post.postId), post: post, author: author),
                        Container(height: 8, width: double.infinity, color: Colors.grey.shade200),
                      ],
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }
}

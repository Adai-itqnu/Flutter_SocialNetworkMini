import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/post_card.dart';
import 'create_post_screen.dart';
import 'SearchScreen.dart';
import '../notification/notifications_screen.dart';
import '../follow/my_follow_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isAddPressed = false;
  final ScrollController _scrollController = ScrollController();
  
  // For hide-on-scroll title
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

  void _onScroll() {
    final offset = _scrollController.offset;
    if (offset > _lastScrollOffset && offset > 50) {
      // Scrolling down
      if (_showTitle) setState(() => _showTitle = false);
    } else if (offset < _lastScrollOffset) {
      // Scrolling up
      if (!_showTitle) setState(() => _showTitle = true);
    }
    _lastScrollOffset = offset;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onNavTapped(int index) async {
    if (index == 2) {
      setState(() => _isAddPressed = true);
      await _openCreateOptions();
      setState(() => _isAddPressed = false);
      return;
    }

    final stackIndex = index < 2 ? index : index - 1;

    if (_selectedIndex == stackIndex && stackIndex == 0) {
      // Nếu đang ở Home và nhấn Home tiếp -> cuộn lên đầu và load lại
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
      // Gọi initializePostStream (hoặc chỉ scroll lên vì stream tự cập nhật)
      // context.read<PostProvider>().initializePostStream();
    } else if (_selectedIndex != stackIndex) {
      setState(() => _selectedIndex = stackIndex);
    }
  }

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: _showTitle ? 0 : 0.5,
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
          Consumer<NotificationProvider>(
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      // Body: IndexedStack cho tất cả tab, bottom nav luôn cố định
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      // Menu cố định (hiển thị luôn)
      bottomNavigationBar: Container(
        height: 80, // Tăng height để cân đối hơn
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly, // Thay đổi để spacing đều hơn
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.search_outlined,
                  activeIcon: Icons.search,
                ),
                _buildAddButton(),
                _buildNavItem(
                  index: 3,
                  icon: Icons.group_outlined,
                  activeIcon: Icons.group,
                ),
                _buildProfileItem(index: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Inline menu helpers (cố định, với mapping selected cho index 3/4)
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
  }) {
    // Mapping nav index sang stack index để check selected
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

  Widget _buildAddButton() {
    final double scale = _isAddPressed ? 0.9 : 1.0;

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      width: 34,
      height: 34,
      transform: Matrix4.identity()..scale(scale),
      decoration: BoxDecoration(
        color: _isAddPressed
            ? Colors.black.withOpacity(0.04)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Colors.black,
          width: _isAddPressed ? 2.2 : 1.8,
        ),
      ),
      child: const Icon(Icons.add, size: 22, color: Colors.black),
    );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        splashColor: Colors.black.withOpacity(0.08),
        highlightColor: Colors.black.withOpacity(0.02),
        onTap: () => _onNavTapped(2),
        child: child,
      ),
    );
  }

  Widget _buildProfileItem({required int index}) {
    final stackIndex = index - 1;
    final bool selected = _selectedIndex == stackIndex;

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
          child: const CircleAvatar(
            radius: 14,
            child: Icon(Icons.person, size: 16),
          ),
        ),
      ),
    );
  }

  // Nội dung tab Home - Load từ Firebase
  Widget _buildHomeContent() {
    return Consumer2<PostProvider, AuthProvider>(
      builder: (context, postProvider, authProvider, _) {
        final posts = postProvider.posts;

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Posts from Firebase
            if (postProvider.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (posts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có bài viết nào',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hãy tạo bài viết đầu tiên!',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(childCount: posts.length, (
                  context,
                  index,
                ) {
                  final post = posts[index];
                  final author = postProvider.getPostAuthor(post.userId);

                  return Column(
                    children: [
                      PostCard(
                        key: ValueKey(post.postId),
                        post: post,
                        author: author,
                      ),
                      // Thanh gạch ngang xám phân chia bài viết (Facebook style)
                      Container(
                        height: 8,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                      ),
                    ],
                  );
                }),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }
}

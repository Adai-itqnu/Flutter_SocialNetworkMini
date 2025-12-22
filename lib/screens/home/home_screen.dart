import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import 'create_post_screen.dart';
import 'story_upload_screen.dart';
import '../comments/comment_screen.dart';
import 'SearchScreen.dart';
import '../notification/notifications_screen.dart';
import '../notification/friend_requests_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isAddPressed = false;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      _buildHomeContent(),
      const SearchScreen(),
      const FriendRequestsScreen(),
      const ProfileScreen(),
    ];
  }

  Future<void> _onNavTapped(int index) async {
    if (index == 2) {
      setState(() => _isAddPressed = true);
      await _openCreateOptions();
      setState(() => _isAddPressed = false);
      return;
    }

    // Mapping nav index sang stack index (bỏ qua add button)
    final stackIndex = index < 2 ? index : index - 1;
    if (_selectedIndex != stackIndex) {
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
              leading: const Icon(Icons.history_toggle_off),
              title: const Text('Tạo tin'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StoryUploadScreen()),
                );
              },
            ),
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
        elevation: 0,
        title: const Text(
          'Mạng Xã Hội Mini',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.black),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Body: IndexedStack cho tất cả tab, bottom nav luôn cố định
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Thay đổi để spacing đều hơn
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
          child: Icon(
            selected ? activeIcon : icon,
            size: 24,
            color: iconColor,
          ),
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
        color: _isAddPressed ? Colors.black.withOpacity(0.04) : Colors.transparent,
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
    // Mapping nav index sang stack index để check selected
    final stackIndex = index - 1;
    final bool selected = _selectedIndex == stackIndex;

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
          child: GestureDetector(
            onTap: () => setState(() => _selectedIndex = 4),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.black : Colors.transparent,
                  width: 2,
                ),
              ),
              child: const CircleAvatar(
                radius: 14,
                child: Icon(Icons.person, size: 14),
              ),
            ),
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
        final currentUser = authProvider.userModel;

        return CustomScrollView(
          slivers: [
            // Header with user avatar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: currentUser?.photoURL != null
                          ? NetworkImage(currentUser!.photoURL!)
                          : null,
                      child: currentUser?.photoURL == null
                          ? const Icon(Icons.person, size: 20)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Xin chào, ${currentUser?.displayName ?? "User"}!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Divider(height: 1)),

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
                      Icon(Icons.photo_library_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có bài viết nào',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
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
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: posts.length,
                    (context, index) {
                      final post = posts[index];
                      final author = postProvider.getPostAuthor(post.userId);

                      return _buildPostCard(
                        post: post,
                        author: author,
                        currentUserId: currentUser?.uid ?? '',
                      );
                    },
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  // Nội dung tab Search (placeholder)
  Widget _buildSearchContent() {
    return const Center(
      child: Text('Tìm kiếm', style: TextStyle(fontSize: 24)),
    );
  }

  Widget _buildPostCard({
    required dynamic post,
    required dynamic author,
    required String currentUserId,
  }) {
    final width = MediaQuery.of(context).size.width;
    final aspect = width > 500 ? 16 / 9 : 4 / 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundImage: author?.photoURL != null
                ? NetworkImage(author!.photoURL!)
                : null,
            child: author?.photoURL == null
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(
            author?.displayName ?? 'Unknown User',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.more_vert),
        ),
        // Display post images
        if (post.imageUrls.isNotEmpty)
          AspectRatio(
            aspectRatio: aspect,
            child: Container(
              width: double.infinity,
              color: Colors.grey[200],
              child: Image.network(
                post.imageUrls[0],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(Icons.broken_image,
                        size: 64, color: Colors.grey[400]),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 6),
          child: Row(
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
              const SizedBox(width: 6),  
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CommentScreen(
                        postAuthor: author?.displayName ?? 'Unknown',
                        postCaption: post.caption,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.mode_comment_outlined),
              ),
              const SizedBox(width: 6),
              IconButton(onPressed: () {}, icon: const Icon(Icons.send)),
              const Spacer(),
              IconButton(onPressed: () {}, icon: const Icon(Icons.bookmark_border)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${post.likesCount} lượt thích',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              if (post.caption.isNotEmpty)
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: '${author?.username ?? "user"} ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: post.caption),
                    ],
                  ),
                ),
              if (post.commentsCount > 0) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CommentScreen(
                          postAuthor: author?.displayName ?? 'Unknown',
                          postCaption: post.caption,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Xem tất cả ${post.commentsCount} bình luận',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
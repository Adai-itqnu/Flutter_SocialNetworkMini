import 'package:flutter/material.dart';

import 'create_post_screen.dart';
import 'story_upload_screen.dart';
import '../comments/comment_screen.dart'; // Import CommentScreen
import 'SearchScreen.dart';
import '../notification/notifications_screen.dart';
import '../notification/friend_requests_screen.dart'; // Import full screen for stack
import '../profile/profile_screen.dart'; // Import full screen for stack

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isAddPressed = false; // trạng thái nhấn nút +

  // Danh sách nội dung tab (IndexedStack cho tất cả tab 0/1/3/4, tab 2 là add không thay đổi content)
  late final List<Widget> _tabs = [
    _buildHomeContent(), // Tab 0: Home
    const SearchScreen(), // Tab 1: Search
    const FriendRequestsScreen(), // Tab 2: Friends (thay thế index 3 trong nav)
    const ProfileScreen(), // Tab 3: Profile (thay thế index 4 trong nav)
  ];

  // Dữ liệu mẫu cho Home
  final List<Map<String, String>> _stories = [
    {'name': 'buitruonggiang', 'avatar': 'https://i.pravatar.cc/150?img=11'},
    {'name': 'linguyen', 'avatar': 'https://i.pravatar.cc/150?img=12'},
    {'name': 'meokun', 'avatar': 'https://i.pravatar.cc/150?img=13'},
    {'name': 'travel_love', 'avatar': 'https://i.pravatar.cc/150?img=14'},
    {'name': 'photography', 'avatar': 'https://i.pravatar.cc/150?img=15'},
  ];

  final List<Map<String, String>> _posts = List.generate(
    5,
    (i) => {
      'author': 'user$i',
      'avatar': 'https://i.pravatar.cc/150?img=${20 + i}',
      'image': 'https://picsum.photos/seed/post$i/800/800',
      'caption': 'Đây là bài viết demo số ${i + 1}',
    },
  );

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
          child: Center(
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
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Nội dung tab Home
  Widget _buildHomeContent() {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width > 600 ? 24.0 : 12.0;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              itemCount: _stories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildYourStory();
                final s = _stories[index - 1];
                return _buildStoryItem(name: s['name']!, avatarUrl: s['avatar']!);
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: Divider(height: 1)),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: _posts.length,
              (context, index) {
                final p = _posts[index];
                return _buildPostCard(
                  author: p['author']!,
                  avatarUrl: p['avatar']!,
                  imageUrl: p['image']!,
                  caption: p['caption']!,
                );
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // Nội dung tab Search (placeholder)
  Widget _buildSearchContent() {
    return const Center(
      child: Text('Tìm kiếm', style: TextStyle(fontSize: 24)),
    );
  }

  // Các hàm helper cho Home (giữ nguyên)
  Widget _buildYourStory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(radius: 30, backgroundColor: Colors.grey[300]),
              Container(
                decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                padding: const EdgeInsets.all(2),
                child: const Icon(Icons.add, size: 16, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Tin của bạn', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStoryItem({required String name, required String avatarUrl}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Colors.orange, Colors.pink, Colors.purple]),
            ),
            child: CircleAvatar(radius: 28, backgroundImage: NetworkImage(avatarUrl)),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard({
    required String author,
    required String avatarUrl,
    required String imageUrl,
    required String caption,
  }) {
    final width = MediaQuery.of(context).size.width;
    final aspect = width > 500 ? 16 / 9 : 4 / 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(backgroundImage: NetworkImage(avatarUrl)),
          title: Text(author, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.more_vert),
        ),
        AspectRatio(
          aspectRatio: aspect,
          child: Container(
            width: double.infinity,
            color: Colors.grey[200],
            child: Image.network(imageUrl, fit: BoxFit.cover),
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
                        postAuthor: author,
                        postCaption: caption,
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
              const Text('1.171 lượt thích', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black),
                  children: [
                    TextSpan(text: '$author ', style: const TextStyle(fontWeight: FontWeight.w600)),
                    TextSpan(text: caption),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
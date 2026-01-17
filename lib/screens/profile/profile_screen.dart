import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';

import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/post_card.dart';
import 'edit_profile_screen.dart';
import 'saved_posts_screen.dart';
import 'widgets/index.dart';

/// Màn hình profile của user hiện tại
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<PostModel> _originalPosts = [];              // Bài đăng gốc
  List<PostModel> _sharedPosts = [];                // Bài đăng lại
  Map<String, PostModel> _sharedPostsData = {};     // Cache bài gốc
  bool _isLoadingPosts = true;
  StreamSubscription? _postsSubscription;
  PostProvider? _postProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      _loadUserPosts();
      _postProvider = context.read<PostProvider>();
      _postProvider?.addListener(_onPostProviderChange);
    });
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    _postProvider?.removeListener(_onPostProviderChange);
    super.dispose();
  }

  // Lắng nghe khi bài viết bị xóa
  void _onPostProviderChange() {
    if (!mounted || _postProvider == null) return;
    final deletedId = _postProvider!.lastDeletedPostId;
    if (deletedId != null) {
      bool changed = false;
      if (_originalPosts.any((p) => p.postId == deletedId)) {
        _originalPosts.removeWhere((p) => p.postId == deletedId);
        changed = true;
      }
      if (_sharedPosts.any((p) => p.postId == deletedId)) {
        _sharedPosts.removeWhere((p) => p.postId == deletedId);
        changed = true;
      }
      if (changed) setState(() {});
    }
  }

  // Tải thông tin user
  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.firebaseUser != null) {
      context.read<UserProvider>().loadUser(authProvider.firebaseUser!.uid);
    }
  }

  // Tải bài viết của user
  Future<void> _loadUserPosts() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.firebaseUser == null) return;

    try {
      final userId = authProvider.firebaseUser!.uid;
      _postsSubscription = _firestoreService.getUserPosts(userId).listen((posts) async {
        if (mounted) {
          final original = posts.where((p) => p.sharedPostId == null).toList();
          final shared = posts.where((p) => p.sharedPostId != null).toList();

          // Load bài gốc cho bài share
          for (var post in shared) {
            if (post.sharedPostId != null && !_sharedPostsData.containsKey(post.sharedPostId)) {
              final originalPost = await _firestoreService.getPost(post.sharedPostId!);
              if (originalPost != null) _sharedPostsData[post.sharedPostId!] = originalPost;
            }
          }

          setState(() {
            _originalPosts = original;
            _sharedPosts = shared;
            _isLoadingPosts = false;
          });
        }
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingPosts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.currentUser;
        if (userProvider.isLoading || user == null) return _buildLoadingScreen();
        return _buildProfileScreen(user);
      },
    );
  }

  // Màn hình loading
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: const Text('Đang tải...', style: TextStyle(color: Colors.black))),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  // Màn hình profile chính
  Widget _buildProfileScreen(UserModel user) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white, elevation: 0, titleSpacing: 0,
          title: Row(children: [
            Text(user.username, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600)),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black, size: 18),
          ]),
          actions: [IconButton(onPressed: _showMenuOptions, icon: const Icon(Icons.menu, color: Colors.black))],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Column(children: [
                ProfileHeader(user: user, onEdit: _openEditProfile),
                const SizedBox(height: 12),
                ProfileActions(onEdit: _openEditProfile, onShare: _shareProfile),
                const SizedBox(height: 16),
              ]),
            ),
            SliverPersistentHeader(pinned: true, delegate: ProfileTabBarDelegate(_buildTabBar())),
          ],
          body: TabBarView(children: [
            ProfilePostsGrid(posts: _originalPosts, user: user, isSharedTab: false, isLoadingPosts: _isLoadingPosts, sharedPostsData: _sharedPostsData, onPostTap: _openPostDetail),
            ProfilePostsGrid(posts: _sharedPosts, user: user, isSharedTab: true, isLoadingPosts: _isLoadingPosts, sharedPostsData: _sharedPostsData, onPostTap: _openPostDetail),
          ]),
        ),
      ),
    );
  }

  // TabBar
  TabBar _buildTabBar() {
    return TabBar(
      indicatorColor: Colors.black, labelColor: Colors.black, unselectedLabelColor: Colors.grey,
      tabs: [
        Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.grid_on, size: 20), const SizedBox(width: 4), Text('${_originalPosts.length}')])),
        Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.repeat, size: 20), const SizedBox(width: 4), Text('${_sharedPosts.length}')])),
      ],
    );
  }

  // Mở chi tiết bài viết
  void _openPostDetail(PostModel post, UserModel user) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
        builder: (context, scrollController) => StreamBuilder<PostModel?>(
          stream: _firestoreService.getPostStream(post.postId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active && snapshot.data == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && Navigator.canPop(context)) Navigator.pop(context);
              });
              return const Center(child: Text("Bài viết không còn tồn tại"));
            }
            final currentPost = snapshot.data ?? post;
            return SingleChildScrollView(controller: scrollController, child: Column(children: [
              Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              PostCard(post: currentPost, author: user),
            ]));
          },
        ),
      ),
    );
  }

  // Mở màn hình chỉnh sửa profile
  Future<void> _openEditProfile() async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return;
    final updated = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)));
    if (updated == true && mounted) _loadUserData();
  }

  // Chia sẻ profile
  void _shareProfile() {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return;
    final shareText = '''
🌟 Hãy theo dõi ${user.displayName} trên SNMini!
👤 @${user.username}
${user.bio != null && user.bio!.isNotEmpty ? '📝 ${user.bio}' : ''}
📊 ${user.postsCount} bài viết • ${user.followersCount} người theo dõi
''';
    Share.share(shareText.trim());
  }

  // Menu options
  void _showMenuOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          ListTile(leading: const Icon(Icons.bookmark_border), title: const Text('Đã lưu'), onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPostsScreen()));
          }),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            onTap: () async { Navigator.pop(context); await context.read<AuthProvider>().signOut(); },
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

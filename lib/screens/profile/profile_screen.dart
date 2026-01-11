import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/avatar_picker_dialog.dart';
import 'edit_profile_screen.dart';
import 'saved_posts_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<PostModel> _originalPosts = []; // Bài đăng gốc
  List<PostModel> _sharedPosts = [];   // Bài đăng lại
  Map<String, PostModel> _sharedPostsData = {}; // Cache bài gốc của bài share
  bool _isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      _loadUserPosts();
    });
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.firebaseUser != null) {
      context.read<UserProvider>().loadUser(authProvider.firebaseUser!.uid);
    }
  }

  Future<void> _loadUserPosts() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.firebaseUser == null) return;

    try {
      final userId = authProvider.firebaseUser!.uid;
      
      // Listen to user posts stream
      _firestoreService.getUserPosts(userId).listen((posts) async {
        if (mounted) {
          final original = posts.where((p) => p.sharedPostId == null).toList();
          final shared = posts.where((p) => p.sharedPostId != null).toList();
          
          // Load original posts for shared posts
          for (var post in shared) {
            if (post.sharedPostId != null && !_sharedPostsData.containsKey(post.sharedPostId)) {
              final originalPost = await _firestoreService.getPost(post.sharedPostId!);
              if (originalPost != null) {
                _sharedPostsData[post.sharedPostId!] = originalPost;
              }
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
      if (mounted) {
        setState(() => _isLoadingPosts = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.currentUser;
        
        if (userProvider.isLoading || user == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text('Đang tải...', style: TextStyle(color: Colors.black)),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return DefaultTabController(
          length: 2, // 2 tabs: Bài đăng gốc và Bài đăng lại
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              titleSpacing: 0,
              title: Row(
                children: [
                  Text(
                    user.username,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black, size: 18),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: _showCreatePostOptions,
                  icon: const Icon(Icons.add_box_outlined, color: Colors.black),
                ),
                IconButton(onPressed: _showMenuOptions, icon: const Icon(Icons.menu, color: Colors.black)),
              ],
            ),
            body: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _ProfileHeader(user: user, onEdit: _openEditProfile),
                      const SizedBox(height: 12),
                      _ProfileActions(
                        onEdit: _openEditProfile,
                        onShare: _shareProfile,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ProfileTabBarDelegate(
                    TabBar(
                      indicatorColor: Colors.black,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.grid_on, size: 20),
                              const SizedBox(width: 4),
                              Text('${_originalPosts.length}'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.repeat, size: 20),
                              const SizedBox(width: 4),
                              Text('${_sharedPosts.length}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  // Tab 1: Bài đăng gốc (Grid)
                  _buildPostsGrid(_originalPosts, user, isSharedTab: false),
                  // Tab 2: Bài đăng lại
                  _buildPostsGrid(_sharedPosts, user, isSharedTab: true),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostsGrid(List<PostModel> posts, UserModel user, {required bool isSharedTab}) {
    if (_isLoadingPosts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSharedTab ? Icons.repeat : Icons.photo_library_outlined, 
              size: 64, 
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isSharedTab ? 'Chưa có bài đăng lại' : 'Chưa có bài đăng',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        
        // Lấy ảnh: nếu là bài share thì lấy ảnh từ bài gốc
        String? imageUrl;
        if (isSharedTab && post.sharedPostId != null) {
          final originalPost = _sharedPostsData[post.sharedPostId];
          if (originalPost != null && originalPost.imageUrls.isNotEmpty) {
            imageUrl = originalPost.imageUrls[0];
          }
        } else if (post.imageUrls.isNotEmpty) {
          imageUrl = post.imageUrls[0];
        }
        
        return GestureDetector(
          onTap: () => _openPostDetail(post, user),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                )
              else
                Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        post.caption,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              // Icon cho bài share
              if (isSharedTab)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(
                    Icons.repeat,
                    color: Colors.white,
                    size: 18,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              // Multiple images indicator - chỉ hiện khi không phải tab share
              if (!isSharedTab && post.imageUrls.length > 1)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(
                    Icons.collections,
                    color: Colors.white,
                    size: 18,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openPostDetail(PostModel post, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Post card
              PostCard(post: post, author: user),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditProfile() async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
    );

    if (updated == true && mounted) {
      _loadUserData();
    }
  }

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

  void _showCreatePostOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tạo bài viết mới...')),
    );
  }

  void _showMenuOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Cài đặt'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text('Đã lưu'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await context.read<AuthProvider>().signOut();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ==================== WIDGETS ====================

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.onEdit});

  final UserModel user;
  final VoidCallback onEdit;

  void _showAvatarPicker(BuildContext context) {
    AvatarPickerDialog.show(
      context,
      currentPhotoURL: user.photoURL,
      onSave: (newUrl) async {
        final userProvider = context.read<UserProvider>();
        await userProvider.updateProfile(user.uid, {'photoURL': newUrl});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar - tap to change
              GestureDetector(
                onTap: () => _showAvatarPicker(context),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                          ? CachedNetworkImageProvider(user.photoURL!)
                          : null,
                      child: user.photoURL == null || user.photoURL!.isEmpty
                          ? const Icon(Icons.person, size: 44, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(count: user.postsCount.toString(), label: 'Bài viết'),
                    _StatItem(count: user.followersCount.toString(), label: 'Người theo dõi'),
                    _StatItem(count: user.followingCount.toString(), label: 'Đang theo dõi'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(user.bio!, style: const TextStyle(fontSize: 14)),
          ],
          if (user.link != null && user.link!.isNotEmpty) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: () async {
                final link = user.link!;
                final uri = Uri.tryParse(
                  link.startsWith('http') ? link : 'https://$link',
                );
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                user.link!,
                style: const TextStyle(color: Colors.blue, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.count, required this.label});

  final String count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({required this.onEdit, required this.onShare});

  final VoidCallback onEdit;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onEdit,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text('Chỉnh sửa'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: onShare,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text('Chia sẻ'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  _ProfileTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_ProfileTabBarDelegate oldDelegate) => tabBar != oldDelegate.tabBar;
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/follow_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/avatar_view_dialog.dart';

/// Profile screen for viewing OTHER users (not current user)
class UserProfileScreen extends StatefulWidget {
  final String userId;
  
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  UserModel? _user;
  List<PostModel> _originalPosts = []; // Bài đăng gốc
  List<PostModel> _sharedPosts = [];   // Bài đăng lại
  Map<String, PostModel> _sharedPostsData = {}; // Cache bài gốc của bài share
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Load user info
      final user = await _firestoreService.getUser(widget.userId);
      
      // Check if current user is following this user
      final authProvider = context.read<AuthProvider>();
      bool isFollowing = false;
      if (authProvider.firebaseUser != null) {
        isFollowing = await _firestoreService.isFollowing(
          authProvider.firebaseUser!.uid,
          widget.userId,
        );
      }

      if (mounted) {
        setState(() {
          _user = user;
          _isFollowing = isFollowing;
          _isLoading = false;
        });
      }

      // Load user posts
      _firestoreService.getUserPosts(widget.userId).listen((posts) async {
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
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.firebaseUser == null) return;

    setState(() => _isFollowLoading = true);

    try {
      final currentUserId = authProvider.firebaseUser!.uid;
      final followProvider = context.read<FollowProvider>();

      if (_isFollowing) {
        await followProvider.unfollowUser(currentUserId, widget.userId);
      } else {
        await followProvider.followUser(currentUserId, widget.userId);
      }

      // Reload user data to update follower count
      final user = await _firestoreService.getUser(widget.userId);
      
      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          _user = user;
          _isFollowLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFollowLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _showMessageComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng nhắn tin sẽ sớm ra mắt!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: const Center(child: Text('Không tìm thấy người dùng')),
      );
    }

    final user = _user!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          title: Text(
            user.username,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar and stats row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => AvatarViewDialog.show(
                            context,
                            imageUrl: user.photoURL,
                            displayName: user.displayName,
                          ),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                                ? CachedNetworkImageProvider(user.photoURL!)
                                : null,
                            child: user.photoURL == null || user.photoURL!.isEmpty
                                ? const Icon(Icons.person, size: 44, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStat(user.postsCount.toString(), 'Bài viết'),
                              _buildStat(user.followersCount.toString(), 'Người theo dõi'),
                              _buildStat(user.followingCount.toString(), 'Đang theo dõi'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Name and bio
                    Text(
                      user.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(user.bio!, style: const TextStyle(fontSize: 14)),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isFollowLoading ? null : _toggleFollow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFollowing ? Colors.grey[200] : Colors.blue,
                              foregroundColor: _isFollowing ? Colors.black : Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: _isFollowLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(_isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _showMessageComingSoon,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text('Nhắn tin'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Tab bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
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
              // Tab 1: Bài đăng gốc
              _buildPostsGrid(_originalPosts, isSharedTab: false),
              // Tab 2: Bài đăng lại
              _buildPostsGrid(_sharedPosts, isSharedTab: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostsGrid(List<PostModel> posts, {required bool isSharedTab}) {
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
          onTap: () => _openPostDetail(post),
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
              // Icon cho nhiều ảnh
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

  Widget _buildStat(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  void _openPostDetail(PostModel post) {
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
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              PostCard(post: post, author: _user),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);
  
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => tabBar != oldDelegate.tabBar;
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/follow_provider.dart';
import '../profile/user_profile_screen.dart';

/// Screen hiển thị followers/following/suggestions của user hiện tại
class MyFollowScreen extends StatefulWidget {
  const MyFollowScreen({super.key});

  @override
  State<MyFollowScreen> createState() => _MyFollowScreenState();
}

class _MyFollowScreenState extends State<MyFollowScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 tabs now
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final currentUserId = context.read<AuthProvider>().firebaseUser?.uid;
    if (currentUserId != null) {
      final followProvider = context.read<FollowProvider>();
      followProvider.loadFollowData(currentUserId);
      followProvider.loadSuggestedUsers(currentUserId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().firebaseUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Theo dõi',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Consumer<FollowProvider>(
            builder: (context, followProvider, _) => TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              isScrollable: true,
              tabs: [
                Tab(text: 'Có thể biết (${followProvider.suggestedUsers.length})'),
                Tab(text: 'Người theo dõi (${followProvider.followersCount})'),
                Tab(text: 'Đang theo dõi (${followProvider.followingCount})'),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<FollowProvider>(
        builder: (context, followProvider, _) {
          if (followProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (currentUserId != null) {
                await followProvider.refresh(currentUserId);
              }
            },
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSuggestedList(followProvider.suggestedUsers, followProvider, currentUserId),
                _buildUserList(followProvider.followers, followProvider, currentUserId),
                _buildUserList(followProvider.following, followProvider, currentUserId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestedList(List<UserModel> users, FollowProvider followProvider, String? currentUserId) {
    if (users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không tìm thấy người dùng nào',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isFollowing = followProvider.isFollowing(user.uid);

        return ListTile(
          leading: GestureDetector(
            onTap: () => _navigateToProfile(user.uid),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300],
              backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                  ? CachedNetworkImageProvider(user.photoURL!)
                  : null,
              child: user.photoURL == null || user.photoURL!.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          ),
          title: GestureDetector(
            onTap: () => _navigateToProfile(user.uid),
            child: Text(
              user.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          subtitle: Text('@${user.username}'),
          trailing: ElevatedButton(
            onPressed: () async {
              if (currentUserId != null) {
                await followProvider.toggleFollow(currentUserId, user.uid);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? Colors.grey[200] : Colors.blue,
              foregroundColor: isFollowing ? Colors.black : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: Text(isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
          ),
        );
      },
    );
  }

  Widget _buildUserList(List<UserModel> users, FollowProvider followProvider, String? currentUserId) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có ai',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isCurrentUser = currentUserId == user.uid;
        final isFollowing = followProvider.isFollowing(user.uid);

        return ListTile(
          leading: GestureDetector(
            onTap: () => _navigateToProfile(user.uid),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300],
              backgroundImage:
                  user.photoURL != null && user.photoURL!.isNotEmpty
                      ? CachedNetworkImageProvider(user.photoURL!)
                      : null,
              child: user.photoURL == null || user.photoURL!.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          ),
          title: GestureDetector(
            onTap: () => _navigateToProfile(user.uid),
            child: Text(
              user.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          subtitle: Text('@${user.username}'),
          trailing: isCurrentUser
              ? null
              : OutlinedButton(
                  onPressed: () async {
                    if (currentUserId != null) {
                      await followProvider.toggleFollow(currentUserId, user.uid);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isFollowing ? Colors.white : Colors.blue,
                    foregroundColor: isFollowing ? Colors.black : Colors.white,
                    side: BorderSide(
                      color: isFollowing ? Colors.grey[300]! : Colors.blue,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
                ),
        );
      },
    );
  }

  void _navigateToProfile(String userId) {
    final currentUserId = context.read<AuthProvider>().firebaseUser?.uid;
    if (userId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đây là trang cá nhân của bạn')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: userId),
      ),
    );
  }
}

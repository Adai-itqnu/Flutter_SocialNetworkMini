import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/follow_provider.dart';
import '../profile/user_profile_screen.dart';

/// Màn hình theo dõi của user hiện tại
/// Gồm 3 tab: Gợi ý, Người theo dõi, Đang theo dõi
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
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Tải dữ liệu follow
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
        title: const Text('Theo dõi', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Consumer<FollowProvider>(
            builder: (context, fp, _) => TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.black,
              isScrollable: true,
              tabs: [
                Tab(text: 'Có thể biết (${fp.suggestedUsers.length})'),
                Tab(text: 'Người theo dõi (${fp.followersCount})'),
                Tab(text: 'Đang theo dõi (${fp.followingCount})'),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<FollowProvider>(
        builder: (context, fp, _) {
          if (fp.isLoading) return const Center(child: CircularProgressIndicator());

          return RefreshIndicator(
            onRefresh: () async {
              if (currentUserId != null) await fp.refresh(currentUserId);
            },
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSuggestedList(fp.suggestedUsers, fp, currentUserId),
                _buildUserList(fp.followers, fp, currentUserId),
                _buildUserList(fp.following, fp, currentUserId),
              ],
            ),
          );
        },
      ),
    );
  }

  // Danh sách gợi ý
  Widget _buildSuggestedList(List<UserModel> users, FollowProvider fp, String? currentUserId) {
    if (users.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.person_search, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('Không tìm thấy người dùng nào', style: TextStyle(fontSize: 16, color: Colors.grey)),
      ]));
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isFollowing = fp.isFollowing(user.uid);
        return _buildUserTile(user, isFollowing, () async {
          if (currentUserId != null) await fp.toggleFollow(currentUserId, user.uid);
        }, isElevated: true);
      },
    );
  }

  // Danh sách followers/following
  Widget _buildUserList(List<UserModel> users, FollowProvider fp, String? currentUserId) {
    if (users.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text('Chưa có ai', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
      ]));
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isCurrentUser = currentUserId == user.uid;
        final isFollowing = fp.isFollowing(user.uid);
        return _buildUserTile(
          user, isFollowing,
          isCurrentUser ? null : () async {
            if (currentUserId != null) await fp.toggleFollow(currentUserId, user.uid);
          },
        );
      },
    );
  }

  // Item user
  Widget _buildUserTile(UserModel user, bool isFollowing, VoidCallback? onFollow, {bool isElevated = false}) {
    return ListTile(
      leading: GestureDetector(
        onTap: () => _navigateToProfile(user.uid),
        child: CircleAvatar(
          radius: 24, backgroundColor: Colors.grey[300],
          backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
              ? CachedNetworkImageProvider(user.photoURL!) : null,
          child: user.photoURL == null || user.photoURL!.isEmpty
              ? const Icon(Icons.person, color: Colors.white) : null,
        ),
      ),
      title: GestureDetector(
        onTap: () => _navigateToProfile(user.uid),
        child: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      subtitle: Text('@${user.username}'),
      trailing: onFollow == null ? null : (isElevated
          ? ElevatedButton(
              onPressed: onFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing ? Colors.grey[200] : Colors.blue,
                foregroundColor: isFollowing ? Colors.black : Colors.white,
                elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
            )
          : OutlinedButton(
              onPressed: onFollow,
              style: OutlinedButton.styleFrom(
                backgroundColor: isFollowing ? Colors.white : Colors.blue,
                foregroundColor: isFollowing ? Colors.black : Colors.white,
                side: BorderSide(color: isFollowing ? Colors.grey[300]! : Colors.blue),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
            )),
    );
  }

  // Điều hướng profile
  void _navigateToProfile(String userId) {
    final currentUserId = context.read<AuthProvider>().firebaseUser?.uid;
    if (userId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đây là trang cá nhân của bạn')));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)));
  }
}

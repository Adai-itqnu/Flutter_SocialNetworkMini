import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/follow_provider.dart';
import '../../services/firestore_service.dart';
import '../profile/user_profile_screen.dart';

/// Enum loại danh sách follow
enum FollowListType { followers, following }

/// Màn hình danh sách followers/following của một user
class FollowListScreen extends StatefulWidget {
  final String userId;
  final FollowListType type;
  final String username;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.type,
    required this.username,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<UserModel> _users = [];
  Map<String, bool> _followingStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final currentUserId = context.read<AuthProvider>().firebaseUser?.uid;
      List<String> userIds;

      if (widget.type == FollowListType.followers) {
        userIds = await _firestoreService.getFollowers(widget.userId);
      } else {
        userIds = await _firestoreService.getFollowing(widget.userId);
      }

      final users = <UserModel>[];
      for (final uid in userIds) {
        final user = await _firestoreService.getUser(uid);
        if (user != null && user.role != 'admin') {
          users.add(user);
          if (currentUserId != null && currentUserId != uid) {
            _followingStatus[uid] = await _firestoreService.isFollowing(currentUserId, uid);
          }
        }
      }

      if (mounted) setState(() { _users = users; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _toggleFollow(String targetUserId) async {
    final currentUserId = context.read<AuthProvider>().firebaseUser?.uid;
    if (currentUserId == null || currentUserId == targetUserId) return;

    final followProvider = context.read<FollowProvider>();
    final isFollowing = _followingStatus[targetUserId] ?? false;
    setState(() => _followingStatus[targetUserId] = !isFollowing);

    try {
      isFollowing
          ? await followProvider.unfollowUser(currentUserId, targetUserId)
          : await followProvider.followUser(currentUserId, targetUserId);
    } catch (e) {
      setState(() => _followingStatus[targetUserId] = isFollowing);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().firebaseUser?.uid;
    final title = widget.type == FollowListType.followers ? 'Người theo dõi' : 'Đang theo dõi';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.username, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ]),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(widget.type == FollowListType.followers ? Icons.people_outline : Icons.person_add_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(widget.type == FollowListType.followers ? 'Chưa có người theo dõi' : 'Chưa theo dõi ai', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ]))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final isCurrentUser = currentUserId == user.uid;
                    final isFollowing = _followingStatus[user.uid] ?? false;
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
                      trailing: isCurrentUser ? null : OutlinedButton(
                        onPressed: () => _toggleFollow(user.uid),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isFollowing ? Colors.white : Colors.blue,
                          foregroundColor: isFollowing ? Colors.black : Colors.white,
                          side: BorderSide(color: isFollowing ? Colors.grey[300]! : Colors.blue),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
                      ),
                    );
                  }),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../screens/profile/user_profile_screen.dart';

/// Widget hiển thị header của bài viết (avatar, tên, thời gian)
class PostHeader extends StatelessWidget {
  final PostModel post;
  final UserModel? author;
  final VoidCallback? onMorePressed;

  const PostHeader({
    super.key,
    required this.post,
    required this.author,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: GestureDetector(
        onTap: () => _navigateToUserProfile(context),
        child: CircleAvatar(
          backgroundColor: Colors.grey[200],
          backgroundImage: author?.photoURL != null
              ? CachedNetworkImageProvider(author!.photoURL!)
              : null,
          child: author?.photoURL == null
              ? const Icon(Icons.person, color: Colors.grey)
              : null,
        ),
      ),
      title: GestureDetector(
        onTap: () => _navigateToUserProfile(context),
        child: Text(
          author?.displayName ?? 'Người dùng',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      subtitle: Text(
        timeago.format(post.createdAt, locale: 'vi'),
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_horiz),
        onPressed: onMorePressed ?? () {},
      ),
    );
  }

  void _navigateToUserProfile(BuildContext context) {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser?.uid == post.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đây là trang cá nhân của bạn'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(userId: post.userId),
      ),
    );
  }
}

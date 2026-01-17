import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../screens/profile/user_profile_screen.dart';
import '../../providers/post_provider.dart';

/// Widget header của bài viết
/// Hiển thị: avatar, tên, thời gian đăng, menu (sửa/xóa/báo cáo)
class PostHeader extends StatelessWidget {
  final PostModel post;
  final UserModel? author;

  const PostHeader({super.key, required this.post, required this.author});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().userModel;
    final isOwner = currentUser?.uid == post.userId;
    final isAdmin = currentUser?.role == 'admin';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      // Avatar
      leading: GestureDetector(
        onTap: () => _navigateToUserProfile(context),
        child: CircleAvatar(
          backgroundColor: Colors.grey[200],
          backgroundImage: author?.photoURL != null ? CachedNetworkImageProvider(author!.photoURL!) : null,
          child: author?.photoURL == null ? const Icon(Icons.person, color: Colors.grey) : null,
        ),
      ),
      // Tên người đăng
      title: GestureDetector(
        onTap: () => _navigateToUserProfile(context),
        child: Text(author?.displayName ?? 'Người dùng', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
      // Thời gian đăng
      subtitle: Text(timeago.format(post.createdAt, locale: 'vi'), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      // Menu popup
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_horiz),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context) => [
          // Sửa - chỉ chủ bài
          if (isOwner) const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 20), SizedBox(width: 12), Text('Sửa bài viết')])),
          // Xóa - chủ bài hoặc admin
          if (isOwner || isAdmin) PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red[700], size: 20), const SizedBox(width: 12), Text('Xóa bài viết', style: TextStyle(color: Colors.red[700]))])),
          // Báo cáo - không phải chủ bài
          if (!isOwner) const PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.flag, color: Colors.orange, size: 20), SizedBox(width: 12), Text('Báo cáo vi phạm')])),
        ],
        onSelected: (value) {
          switch (value) {
            case 'edit': _editPost(context); break;
            case 'delete': _deletePost(context); break;
            case 'report': _reportPost(context); break;
          }
        },
      ),
    );
  }

  // Chuyển đến trang profile của user
  void _navigateToUserProfile(BuildContext context) {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser?.uid == post.userId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đây là trang cá nhân của bạn'), duration: Duration(seconds: 1)));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => UserProfileScreen(userId: post.userId)));
  }

  // Dialog sửa bài viết
  void _editPost(BuildContext context) {
    final captionController = TextEditingController(text: post.caption);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa bài viết'),
        content: TextField(controller: captionController, decoration: const InputDecoration(hintText: 'Nhập nội dung mới...', border: OutlineInputBorder()), maxLines: 5, minLines: 1),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              final newCaption = captionController.text.trim();
              if (newCaption == post.caption) { Navigator.pop(context); return; }
              try {
                Navigator.pop(context);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang cập nhật...'), duration: Duration(seconds: 1)));
                await context.read<PostProvider>().updatePost(post.postId, {'caption': newCaption});
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật bài viết')));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // Dialog xóa bài viết
  void _deletePost(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài viết'),
        content: const Text('Bạn có chắc chắn muốn xóa bài viết này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                await context.read<PostProvider>().deletePost(post.postId, post.userId);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa bài viết')));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: Text('Xóa', style: TextStyle(color: Colors.red[700])),
          ),
        ],
      ),
    );
  }

  // Dialog báo cáo bài viết
  void _reportPost(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Báo cáo bài viết'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Vui lòng cho biết lý do báo cáo:'),
          const SizedBox(height: 16),
          TextField(controller: reasonController, decoration: const InputDecoration(hintText: 'Ví dụ: Nội dung không phù hợp', border: OutlineInputBorder()), maxLines: 3),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập lý do')));
                return;
              }
              try {
                final currentUser = context.read<AuthProvider>().userModel!;
                await AdminService().createReport(postId: post.postId, reportedBy: currentUser.uid, postOwnerId: post.userId, reason: reasonController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi báo cáo. Cảm ơn bạn!')));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text('Gửi báo cáo', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}

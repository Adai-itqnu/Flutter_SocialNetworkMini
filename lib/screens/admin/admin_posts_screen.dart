import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../services/admin_service.dart';
import '../../services/firestore_service.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';

/// Màn hình quản lý bài viết cho Admin
class AdminPostsScreen extends StatefulWidget {
  const AdminPostsScreen({super.key});

  @override
  State<AdminPostsScreen> createState() => _AdminPostsScreenState();
}

class _AdminPostsScreenState extends State<AdminPostsScreen> {
  final AdminService _adminService = AdminService();
  final FirestoreService _firestoreService = FirestoreService();
  List<PostModel> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  // Tải danh sách bài viết
  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final posts = await _adminService.getAllPosts();
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Lỗi: $e', isError: true);
      }
    }
  }

  // Hiển thị thông báo
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Bài Viết'),
        backgroundColor: const Color(0xFF006CFF),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPosts,
              child: ListView.builder(
                itemCount: _posts.length,
                itemBuilder: (context, index) => _buildPostCard(_posts[index]),
              ),
            ),
    );
  }

  // Card hiển thị bài viết
  Widget _buildPostCard(PostModel post) {
    return FutureBuilder<UserModel?>(
      future: _firestoreService.getUser(post.userId),
      builder: (context, snapshot) {
        final author = snapshot.data;
        return Card(
          margin: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với avatar và tên tác giả
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: author?.photoURL != null
                      ? NetworkImage(author!.photoURL!)
                      : null,
                  child: author?.photoURL == null ? const Icon(Icons.person) : null,
                ),
                title: Text(author?.displayName ?? 'Loading...'),
                subtitle: Text(timeago.format(post.createdAt, locale: 'vi')),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(post),
                ),
              ),

              // Caption
              if (post.caption.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    post.caption,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Ảnh đầu tiên
              if (post.imageUrls.isNotEmpty)
                Image.network(
                  post.imageUrls[0],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

              // Thống kê like/comment
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Icon(Icons.favorite, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${post.likesCount}', style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(width: 16),
                    Icon(Icons.comment, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${post.commentsCount}', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Xác nhận xóa bài viết
  void _confirmDelete(PostModel post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài viết'),
        content: const Text('Bạn có chắc muốn xóa bài viết này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => _deletePost(post),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Thực hiện xóa bài viết
  Future<void> _deletePost(PostModel post) async {
    Navigator.pop(context);
    try {
      await _adminService.deletePost(post.postId);
      if (mounted) {
        _showMessage('Đã xóa bài viết');
        _loadPosts();
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Lỗi: $e', isError: true);
      }
    }
  }
}

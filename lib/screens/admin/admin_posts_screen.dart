import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/firestore_service.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import 'package:timeago/timeago.dart' as timeago;

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
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
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return FutureBuilder<UserModel?>(
                    future: _firestoreService.getUser(post.userId),
                    builder: (context, snapshot) {
                      final author = snapshot.data;
                      return Card(
                        margin: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundImage: author?.photoURL != null
                                    ? NetworkImage(author!.photoURL!)
                                    : null,
                                child: author?.photoURL == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(author?.displayName ?? 'Loading...'),
                              subtitle: Text(
                                timeago.format(post.createdAt, locale: 'vi'),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _confirmDelete(post),
                              ),
                            ),
                            if (post.caption.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  8,
                                ),
                                child: Text(
                                  post.caption,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (post.imageUrls.isNotEmpty)
                              Image.network(
                                post.imageUrls[0],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${post.likesCount}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.comment,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${post.commentsCount}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }

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
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _adminService.deletePost(post.postId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa bài viết')),
                  );
                  _loadPosts();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

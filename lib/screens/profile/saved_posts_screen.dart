import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/post_card.dart';

/// Màn hình hiển thị các bài viết đã lưu
class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<PostModel> _savedPosts = [];
  Map<String, UserModel> _authorsCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
  }

  // Tải danh sách bài viết đã lưu
  Future<void> _loadSavedPosts() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = context.read<AuthProvider>().userModel;
      if (currentUser == null) return;

      final posts = await _firestoreService.getSavedPosts(currentUser.uid);

      // Load thông tin tác giả
      for (final post in posts) {
        if (!_authorsCache.containsKey(post.userId)) {
          final author = await _firestoreService.getUser(post.userId);
          if (author != null) _authorsCache[post.userId] = author;
        }
      }

      if (mounted) setState(() { _savedPosts = posts; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Bài viết đã lưu', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedPosts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadSavedPosts,
                  child: ListView.builder(
                    itemCount: _savedPosts.length,
                    itemBuilder: (context, index) {
                      final post = _savedPosts[index];
                      return PostCard(post: post, author: _authorsCache[post.userId]);
                    },
                  ),
                ),
    );
  }

  // Trạng thái chưa lưu bài nào
  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.bookmark_border, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text('Chưa có bài viết đã lưu', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text('Nhấn biểu tượng lưu trên bài viết\nđể lưu lại xem sau', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
      ]),
    );
  }
}

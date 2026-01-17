import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../models/post_model.dart';
import '../../../models/user_model.dart';

/// Widget hiển thị grid các bài viết trong profile
class ProfilePostsGrid extends StatelessWidget {
  const ProfilePostsGrid({
    super.key,
    required this.posts,
    required this.user,
    required this.isSharedTab,
    required this.isLoadingPosts,
    required this.sharedPostsData,
    required this.onPostTap,
  });

  final List<PostModel> posts;
  final UserModel user;
  final bool isSharedTab;         // Tab bài đăng lại
  final bool isLoadingPosts;
  final Map<String, PostModel> sharedPostsData; // Cache bài gốc
  final void Function(PostModel post, UserModel user) onPostTap;

  @override
  Widget build(BuildContext context) {
    if (isLoadingPosts) return const Center(child: CircularProgressIndicator());
    if (posts.isEmpty) return _buildEmptyState();
    return _buildGrid();
  }

  // Trạng thái trống
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSharedTab ? Icons.repeat : Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(isSharedTab ? 'Chưa có bài đăng lại' : 'Chưa có bài đăng',
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // Grid bài viết
  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final imageUrl = _getImageUrl(post);

        return GestureDetector(
          onTap: () => onPostTap(post, user),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null)
                CachedNetworkImage(
                  imageUrl: imageUrl, fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                )
              else
                _buildTextPost(post),
              // Icon bài share
              if (isSharedTab) _buildIcon(Icons.repeat),
              // Icon nhiều ảnh
              if (!isSharedTab && post.imageUrls.length > 1) _buildIcon(Icons.collections),
            ],
          ),
        );
      },
    );
  }

  // Lấy ảnh đầu tiên: nếu là bài share thì lấy từ bài gốc
  String? _getImageUrl(PostModel post) {
    if (isSharedTab && post.sharedPostId != null) {
      final original = sharedPostsData[post.sharedPostId];
      if (original != null && original.imageUrls.isNotEmpty) return original.imageUrls[0];
    } else if (post.imageUrls.isNotEmpty) {
      return post.imageUrls[0];
    }
    return null;
  }

  // Bài viết chỉ có text
  Widget _buildTextPost(PostModel post) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(post.caption, maxLines: 3, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  // Icon góc phải
  Widget _buildIcon(IconData icon) {
    return Positioned(
      top: 6, right: 6,
      child: Icon(icon, color: Colors.white, size: 18,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 4)]),
    );
  }
}

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
  final bool isSharedTab;
  final bool isLoadingPosts;
  final Map<String, PostModel> sharedPostsData;
  final void Function(PostModel post, UserModel user) onPostTap;

  @override
  Widget build(BuildContext context) {
    if (isLoadingPosts) {
      return const Center(child: CircularProgressIndicator());
    }

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
          final originalPost = sharedPostsData[post.sharedPostId];
          if (originalPost != null && originalPost.imageUrls.isNotEmpty) {
            imageUrl = originalPost.imageUrls[0];
          }
        } else if (post.imageUrls.isNotEmpty) {
          imageUrl = post.imageUrls[0];
        }

        return GestureDetector(
          onTap: () => onPostTap(post, user),
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
              // Multiple images indicator - chỉ hiện khi không phải tab share
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
}

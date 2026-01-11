import 'package:flutter/material.dart';

/// Widget hiển thị các nút tương tác (like, comment, share, bookmark)
class PostInteractionBar extends StatelessWidget {
  final bool isLiked;
  final bool isSaved;
  final int likesCount;
  final int commentsCount;
  final Animation<double> likeAnimation;
  final VoidCallback onLikePressed;
  final VoidCallback onCommentPressed;
  final VoidCallback onSharePressed;
  final VoidCallback onBookmarkPressed;

  const PostInteractionBar({
    super.key,
    required this.isLiked,
    required this.isSaved,
    required this.likesCount,
    required this.commentsCount,
    required this.likeAnimation,
    required this.onLikePressed,
    required this.onCommentPressed,
    required this.onSharePressed,
    required this.onBookmarkPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Nút Thích + Số lượng
        InkWell(
          onTap: onLikePressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ScaleTransition(
                  scale: likeAnimation,
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.black87,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 4),
                if (likesCount > 0)
                  Text(
                    '$likesCount',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
        ),
        // Nút Bình luận + Số lượng
        InkWell(
          onTap: onCommentPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.black87,
                  size: 22,
                ),
                const SizedBox(width: 4),
                if (commentsCount > 0)
                  Text(
                    '$commentsCount',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
        ),
        // Nút Chia sẻ
        IconButton(
          onPressed: onSharePressed,
          icon: const Icon(
            Icons.share_outlined,
            color: Colors.black87,
            size: 22,
          ),
        ),
        const Spacer(),
        // Nút Lưu (Bookmark)
        IconButton(
          onPressed: onBookmarkPressed,
          icon: Icon(
            isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: isSaved ? Colors.black : Colors.black87,
            size: 22,
          ),
        ),
      ],
    );
  }
}

/// Widget hiển thị thống kê (lượt thích, bình luận)
class PostStats extends StatelessWidget {
  final int likesCount;
  final int commentsCount;
  final VoidCallback onCommentPressed;

  const PostStats({
    super.key,
    required this.likesCount,
    required this.commentsCount,
    required this.onCommentPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (likesCount > 0)
            Text(
              '$likesCount lượt thích',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          if (commentsCount > 0)
            GestureDetector(
              onTap: onCommentPressed,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Xem tất cả $commentsCount bình luận',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../screens/comments/comment_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final UserModel? author;

  const PostCard({super.key, required this.post, required this.author});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLiked = false;
  int _likesCount = 0;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;

  PostModel? _sharedPost;
  UserModel? _sharedPostAuthor;
  bool _isLoadingShared = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likesCount;
    _checkIfLiked();

    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _likeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.easeOut),
    );

    if (widget.post.sharedPostId != null) {
      _loadSharedData();
    }
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Cập nhật lại số lượng tim nếu dữ liệu từ Firestore thay đổi
    if (widget.post.likesCount != oldWidget.post.likesCount) {
      if (mounted) {
        setState(() {
          _likesCount = widget.post.likesCount;
        });
      }
    }
    // Cập nhật lại trạng thái like nếu danh sách người like thay đổi
    _checkIfLiked();
  }

  Future<void> _loadSharedData() async {
    if (mounted) setState(() => _isLoadingShared = true);
    try {
      final post = await _firestoreService.getPost(widget.post.sharedPostId!);
      UserModel? author;
      if (post != null && widget.post.sharedUserId != null) {
        author = await _firestoreService.getUser(widget.post.sharedUserId!);
      }
      if (mounted) {
        setState(() {
          _sharedPost = post;
          _sharedPostAuthor = author;
          _isLoadingShared = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingShared = false);
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _checkIfLiked() async {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser != null) {
      final liked = widget.post.likedBy.contains(currentUser.uid);
      if (mounted) {
        setState(() {
          _isLiked = liked;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) return;

    setState(() {
      _isLiked = !_isLiked;
      _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1;
    });

    // Animate
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
    });

    try {
      if (_isLiked) {
        await _firestoreService.likePost(widget.post.postId, currentUser.uid);
      } else {
        await _firestoreService.unlikePost(widget.post.postId, currentUser.uid);
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isLiked = !_isLiked;
        _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  void _openComments() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommentScreen(
          postId: widget.post.postId,
          postAuthor: widget.author?.displayName ?? 'Unknown',
          postCaption: widget.post.caption,
        ),
      ),
    );
  }

  void _showShareDialog() {
    final TextEditingController captionController = TextEditingController();
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: const Center(
                  child: Text(
                    'Chia sẻ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 16),
              // User info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: currentUser.photoURL != null
                          ? CachedNetworkImageProvider(currentUser.photoURL!)
                          : null,
                      child: currentUser.photoURL == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      currentUser.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Text field with a slightly larger minimum height
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: captionController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Hãy nói gì đó về nội dung này...',
                    border: InputBorder.none,
                  ),
                  maxLines: 4, // Cho phép hiện nhiều dòng hơn ban đầu
                  minLines: 2,
                ),
              ),
              // Footer with Blue Submit Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await _firestoreService.sharePost(
                            userId: currentUser.uid,
                            caption: captionController.text,
                            sharedPostId: widget.post.postId,
                            sharedUserId: widget.post.userId,
                          );

                          if (context.mounted) {
                            Navigator.pop(context); // Close dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã chia sẻ bài viết!'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006CFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Chia sẻ ngay',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final width = MediaQuery.of(context).size.width;
    final aspect = width > 500 ? 16 / 9 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPostHeader(),
        _buildCaption(),
        _buildMainContent(aspect),
        const Divider(height: 1),
        _buildInteractionBar(),
        _buildStats(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPostHeader() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: CircleAvatar(
        backgroundColor: Colors.grey[200],
        backgroundImage: widget.author?.photoURL != null
            ? CachedNetworkImageProvider(widget.author!.photoURL!)
            : null,
        child: widget.author?.photoURL == null
            ? const Icon(Icons.person, color: Colors.grey)
            : null,
      ),
      title: Text(
        widget.author?.displayName ?? 'Người dùng',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Text(
        timeago.format(widget.post.createdAt, locale: 'vi'),
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_horiz),
        onPressed: () {},
      ),
    );
  }

  Widget _buildCaption() {
    if (widget.post.caption.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Text(
        widget.post.caption,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
  }

  Widget _buildMainContent(double aspect) {
    if (widget.post.sharedPostId != null) {
      if (_isLoadingShared) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      return _sharedPost != null
          ? _buildSharedPreview()
          : const SizedBox.shrink();
    }

    if (widget.post.imageUrls.isNotEmpty) {
      return AspectRatio(
        aspectRatio: aspect,
        child: CachedNetworkImage(
          imageUrl: widget.post.imageUrls[0],
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[100],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSharedPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              backgroundImage: _sharedPostAuthor?.photoURL != null
                  ? CachedNetworkImageProvider(_sharedPostAuthor!.photoURL!)
                  : null,
              child: _sharedPostAuthor?.photoURL == null
                  ? const Icon(Icons.person, size: 14)
                  : null,
            ),
            title: Text(
              _sharedPostAuthor?.displayName ?? 'Người dùng',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          if (_sharedPost!.imageUrls.isNotEmpty)
            CachedNetworkImage(
              imageUrl: _sharedPost!.imageUrls[0],
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[100],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          if (_sharedPost!.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                _sharedPost!.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInteractionBar() {
    return Row(
      children: [
        // Nút Thích + Số lượng
        InkWell(
          onTap: _toggleLike,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ScaleTransition(
                  scale: _likeAnimation,
                  child: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.black87,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 4),
                if (_likesCount > 0)
                  Text(
                    '$_likesCount',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
        ),
        // Nút Bình luận + Số lượng
        InkWell(
          onTap: _openComments,
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
                if (widget.post.commentsCount > 0)
                  Text(
                    '${widget.post.commentsCount}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
        ),
        // Nút Chia sẻ
        IconButton(
          onPressed: _showShareDialog,
          icon: const Icon(
            Icons.share_outlined,
            color: Colors.black87,
            size: 22,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.bookmark_border, size: 22),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_likesCount > 0)
            Text(
              '$_likesCount lượt thích',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          if (widget.post.commentsCount > 0)
            GestureDetector(
              onTap: _openComments,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Xem tất cả ${widget.post.commentsCount} bình luận',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

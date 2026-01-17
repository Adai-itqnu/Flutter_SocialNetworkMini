import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../screens/comments/comment_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'post_card/post_header.dart';
import 'post_card/post_interaction_bar.dart';

// Kích thước cache ảnh để tối ưu bộ nhớ
const int _imageCacheWidth = 800;
const int _imageCacheHeight = 800;

/// Widget hiển thị 1 bài viết
/// Bao gồm: header, caption, ảnh/shared post, thanh tương tác, thống kê
class PostCard extends StatefulWidget {
  final PostModel post;
  final UserModel? author;

  const PostCard({super.key, required this.post, required this.author});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  bool _isLiked = false;
  bool _isSaved = false;
  int _likesCount = 0;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;

  // Image carousel
  int _currentImageIndex = 0;
  final PageController _imagePageController = PageController();

  // Shared post data
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
    _isSaved = context.read<PostProvider>().isSaved(widget.post.postId);

    _likeAnimationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _likeAnimationController, curve: Curves.easeOut));

    if (widget.post.sharedPostId != null) _loadSharedData();
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.likesCount != oldWidget.post.likesCount) {
      if (mounted) setState(() => _likesCount = widget.post.likesCount);
    }
    _checkIfLiked();
  }

  // Tải dữ liệu bài viết được chia sẻ
  Future<void> _loadSharedData() async {
    if (mounted) setState(() => _isLoadingShared = true);
    try {
      final post = await _firestoreService.getPost(widget.post.sharedPostId!);
      UserModel? author;
      if (post != null && widget.post.sharedUserId != null) {
        author = await _firestoreService.getUser(widget.post.sharedUserId!);
      }
      if (mounted) setState(() { _sharedPost = post; _sharedPostAuthor = author; _isLoadingShared = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingShared = false);
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  // Kiểm tra user đã like chưa
  Future<void> _checkIfLiked() async {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser != null) {
      final liked = widget.post.likedBy.contains(currentUser.uid);
      if (mounted) setState(() => _isLiked = liked);
    }
  }

  // Toggle lưu bài viết
  Future<void> _toggleSave() async {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) return;

    setState(() => _isSaved = !_isSaved);
    final success = await context.read<PostProvider>().toggleSave(currentUser.uid, widget.post.postId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isSaved ? 'Đã lưu bài viết' : 'Đã bỏ lưu bài viết'), duration: const Duration(seconds: 1)));
    } else if (!success && mounted) {
      setState(() => _isSaved = !_isSaved);
    }
  }

  // Toggle like bài viết
  Future<void> _toggleLike() async {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) return;

    setState(() { _isLiked = !_isLiked; _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1; });
    _likeAnimationController.forward().then((_) => _likeAnimationController.reverse());

    try {
      if (_isLiked) {
        await _firestoreService.likePost(widget.post.postId, currentUser.uid);
        if (widget.post.userId != currentUser.uid) {
          await _notificationService.createLikeNotification(fromUserId: currentUser.uid, postOwnerId: widget.post.userId, postId: widget.post.postId);
        }
      } else {
        await _firestoreService.unlikePost(widget.post.postId, currentUser.uid);
      }
    } catch (e) {
      setState(() { _isLiked = !_isLiked; _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  // Mở màn hình bình luận
  void _openComments() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CommentScreen(postId: widget.post.postId, postAuthor: widget.author?.displayName ?? 'Unknown', postCaption: widget.post.caption, postOwnerId: widget.post.userId),
    ));
  }

  // Mở dialog chia sẻ
  void _showShareDialog() {
    final captionController = TextEditingController();
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text('Chia sẻ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // Thông tin user
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(children: [
                CircleAvatar(radius: 20, backgroundImage: currentUser.photoURL != null ? CachedNetworkImageProvider(currentUser.photoURL!) : null, child: currentUser.photoURL == null ? const Icon(Icons.person) : null),
                const SizedBox(width: 12),
                Text(currentUser.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 8),
            // Text field
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: TextField(controller: captionController, autofocus: true, decoration: const InputDecoration(hintText: 'Hãy nói gì đó về nội dung này...', border: InputBorder.none), maxLines: 4, minLines: 2)),
            // Nút chia sẻ
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await _firestoreService.sharePost(userId: currentUser.uid, caption: captionController.text, sharedPostId: widget.post.postId, sharedUserId: widget.post.userId);
                      if (widget.post.userId != currentUser.uid) {
                        await _notificationService.createShareNotification(fromUserId: currentUser.uid, postOwnerId: widget.post.userId, postId: widget.post.postId);
                      }
                      if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chia sẻ bài viết!'))); }
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006CFF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                  child: const Text('Chia sẻ ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final width = MediaQuery.of(context).size.width;
    final aspect = width > 500 ? 16 / 9 : 1.0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PostHeader(post: widget.post, author: widget.author),
      _buildCaption(),
      _buildMainContent(aspect),
      const Divider(height: 1),
      PostInteractionBar(isLiked: _isLiked, isSaved: _isSaved, likesCount: _likesCount, commentsCount: widget.post.commentsCount, likeAnimation: _likeAnimation, onLikePressed: _toggleLike, onCommentPressed: _openComments, onSharePressed: _showShareDialog, onBookmarkPressed: _toggleSave),
      PostStats(likesCount: _likesCount, commentsCount: widget.post.commentsCount, onCommentPressed: _openComments),
      const SizedBox(height: 12),
    ]);
  }

  // Widget caption
  Widget _buildCaption() {
    if (widget.post.caption.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 10), child: Text(widget.post.caption, style: const TextStyle(fontSize: 14, color: Colors.black87)));
  }

  // Widget nội dung chính (ảnh hoặc shared post)
  Widget _buildMainContent(double aspect) {
    if (widget.post.sharedPostId != null) {
      if (_isLoadingShared) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
      return _sharedPost != null ? _buildSharedPreview() : const SizedBox.shrink();
    }

    if (widget.post.imageUrls.isNotEmpty) {
      final imageCount = widget.post.imageUrls.length;
      return AspectRatio(
        aspectRatio: aspect,
        child: Stack(children: [
          // PageView ảnh
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad}),
            child: PageView.builder(
              controller: _imagePageController,
              itemCount: imageCount,
              onPageChanged: (index) => setState(() => _currentImageIndex = index),
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: widget.post.imageUrls[index],
                  fit: BoxFit.cover,
                  memCacheWidth: _imageCacheWidth,
                  memCacheHeight: _imageCacheHeight,
                  fadeInDuration: const Duration(milliseconds: 150),
                  fadeOutDuration: const Duration(milliseconds: 100),
                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                  errorWidget: (_, __, ___) => Container(color: Colors.grey[100], child: const Icon(Icons.broken_image, color: Colors.grey)),
                );
              },
            ),
          ),
          // Số trang
          if (imageCount > 1) Positioned(top: 12, right: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)), child: Text('${_currentImageIndex + 1}/$imageCount', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)))),
          // Dot indicators
          if (imageCount > 1) Positioned(bottom: 12, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(imageCount, (index) {
            final isActive = index == _currentImageIndex;
            return AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 3), width: isActive ? 8 : 6, height: isActive ? 8 : 6, decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? Colors.blue : Colors.white.withValues(alpha: 0.7), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 2)]));
          }))),
        ]),
      );
    }

    return const SizedBox.shrink();
  }

  // Widget preview shared post
  Widget _buildSharedPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ListTile(
          dense: true,
          leading: CircleAvatar(radius: 14, backgroundImage: _sharedPostAuthor?.photoURL != null ? CachedNetworkImageProvider(_sharedPostAuthor!.photoURL!) : null, child: _sharedPostAuthor?.photoURL == null ? const Icon(Icons.person, size: 14) : null),
          title: Text(_sharedPostAuthor?.displayName ?? 'Người dùng', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        if (_sharedPost!.imageUrls.isNotEmpty) CachedNetworkImage(imageUrl: _sharedPost!.imageUrls[0], width: double.infinity, height: 180, fit: BoxFit.cover, memCacheWidth: 600, memCacheHeight: 400, fadeInDuration: const Duration(milliseconds: 150), placeholder: (_, __) => Container(color: Colors.grey[200]), errorWidget: (_, __, ___) => Container(color: Colors.grey[100], child: const Icon(Icons.broken_image, color: Colors.grey))),
        if (_sharedPost!.caption.isNotEmpty) Padding(padding: const EdgeInsets.all(10), child: Text(_sharedPost!.caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }
}

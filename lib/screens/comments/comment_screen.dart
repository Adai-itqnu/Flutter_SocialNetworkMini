import 'package:flutter/material.dart';
import '../../models/comment_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

class CommentScreen extends StatefulWidget {
  final String postId, postAuthor, postCaption;
  const CommentScreen({
    super.key,
    required this.postId,
    required this.postAuthor,
    required this.postCaption,
  });

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _service = FirestoreService();
  String? _replyId, _replyName;

  void _submit() async {
    final user = context.read<AuthProvider>().userModel;
    if (_controller.text.trim().isEmpty || user == null) return;
    await _service.addComment(
      postId: widget.postId,
      userId: user.uid,
      text: _controller.text.trim(),
      parentCommentId: _replyId,
    );
    _controller.clear();
    _focus.unfocus();
    setState(() {
      _replyId = null;
      _replyName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bình luận', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(
              widget.postAuthor,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(widget.postCaption),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: _service.getComments(widget.postId),
              builder: (context, snap) {
                final list = (snap.data ?? [])
                    .where((c) => c.parentCommentId == null)
                    .toList();
                return list.isEmpty
                    ? const Center(child: Text('Chưa có bình luận'))
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, i) => _CommentItem(
                          comment: list[i],
                          postId: widget.postId,
                          onReply: (id, name) {
                            setState(() {
                              _replyId = id;
                              _replyName = name;
                            });
                            _focus.requestFocus();
                          },
                        ),
                      );
              },
            ),
          ),
          if (_replyName != null)
            Container(
              color: Colors.blue.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Trả lời @$_replyName',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _replyName = null),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    decoration: InputDecoration(
                      hintText: 'Viết bình luận...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _submit,
                  icon: const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatefulWidget {
  final CommentModel comment;
  final String postId;
  final Function(String, String) onReply;
  const _CommentItem({
    required this.comment,
    required this.postId,
    required this.onReply,
  });

  @override
  State<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<_CommentItem> {
  bool _liked = false, _show = false;
  int _count = 0;
  UserModel? _author;

  @override
  void initState() {
    super.initState();
    _count = widget.comment.likesCount;
    _initialLoad();
  }

  void _initialLoad() async {
    final user = context.read<AuthProvider>().userModel;
    _author = await FirestoreService().getUser(widget.comment.userId);
    if (user != null) _liked = widget.comment.likedBy.contains(user.uid);
    if (mounted) setState(() {});
  }

  void _toggleLike() async {
    final uid = context.read<AuthProvider>().userModel?.uid;
    if (uid == null) return;
    setState(() {
      _liked = !_liked;
      _count += _liked ? 1 : -1;
    });
    _liked
        ? await FirestoreService().likeComment(widget.comment.commentId, uid)
        : await FirestoreService().unlikeComment(widget.comment.commentId, uid);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: _author?.photoURL != null
                ? CachedNetworkImageProvider(_author!.photoURL!)
                : null,
          ),
          title: Row(
            children: [
              Text(
                _author?.displayName ?? '...',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeago.format(widget.comment.createdAt, locale: 'vi'),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.comment.text),
              Row(
                children: [
                  InkWell(
                    onTap: _toggleLike,
                    child: Row(
                      children: [
                        Icon(
                          _liked ? Icons.favorite : Icons.favorite_border,
                          size: 14,
                          color: _liked ? Colors.red : Colors.grey,
                        ),
                        if (_count > 0)
                          Text(
                            ' $_count',
                            style: const TextStyle(fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () => widget.onReply(
                      widget.comment.commentId,
                      _author?.displayName ?? '',
                    ),
                    child: const Text(
                      'Trả lời',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        StreamBuilder<List<CommentModel>>(
          stream: FirestoreService().getReplies(widget.comment.commentId),
          builder: (context, snap) {
            final reps = snap.data ?? [];
            if (reps.isEmpty) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_show)
                    TextButton(
                      onPressed: () => setState(() => _show = true),
                      child: Text(
                        'Xem ${reps.length} trả lời',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  if (_show) ...[
                    ...reps.map(
                      (r) => _CommentItem(
                        comment: r,
                        postId: widget.postId,
                        onReply: widget.onReply,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _show = false),
                      child: const Text('Ẩn', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

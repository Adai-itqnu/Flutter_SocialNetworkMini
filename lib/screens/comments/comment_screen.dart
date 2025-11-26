import 'package:flutter/material.dart';

class CommentScreen extends StatefulWidget {
  final String postAuthor;
  final String postCaption;

  const CommentScreen({
    super.key,
    required this.postAuthor,
    required this.postCaption,
  });

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Dữ liệu mẫu cho comments
  final List<Map<String, String>> _comments = [
    {
      'author': 'linguyen',
      'avatar': 'https://i.pravatar.cc/150?img=12',
      'text': 'Bài viết hay quá! Thích lắm 😍',
      'time': '2 giờ trước',
    },
    {
      'author': 'meokun',
      'avatar': 'https://i.pravatar.cc/150?img=13',
      'text': 'Mình cũng muốn đi du lịch như vậy. Có tip gì không?',
      'time': '1 giờ trước',
    },
    {
      'author': 'travel_love',
      'avatar': 'https://i.pravatar.cc/150?img=14',
      'text': 'Chụp ảnh đẹp thật! Location đâu vậy?',
      'time': '30 phút trước',
    },
  ];

  void _addComment() {
    if (_commentController.text.trim().isNotEmpty) {
      setState(() {
        _comments.insert(0, {
          'author': 'buitruonggiang', // Giả sử user hiện tại
          'avatar': 'https://i.pravatar.cc/150?img=11',
          'text': _commentController.text.trim(),
          'time': 'Vừa xong',
        });
      });
      _commentController.clear();
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width > 600 ? 24.0 : 12.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Bình luận',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: CustomScrollView(
        slivers: [
          // Header với post info
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=20'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.postAuthor,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              widget.postCaption,
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                ],
              ),
            ),
          ),
          // List comments
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                childCount: _comments.length,
                (context, index) {
                  final comment = _comments[index];
                  return _buildCommentItem(comment);
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      // Input comment
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(horizontalPadding, horizontalPadding, horizontalPadding, 30),
        height: 100, // Tăng height để chứa margin bottom
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  hintText: 'Viết bình luận...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onSubmitted: (_) => _addComment(),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: _addComment,
              mini: true,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(Map<String, String> comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(comment['avatar']!),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['author']!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      comment['time']!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment['text']!,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
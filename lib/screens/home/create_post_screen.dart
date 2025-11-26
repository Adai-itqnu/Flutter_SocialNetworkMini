import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Dữ liệu bài viết mới trả về cho HomeScreen
class NewPostData {
  const NewPostData({
    required this.content,
    this.imagePath,
  });

  final String content;
  final String? imagePath;
}

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _image;
  bool get _canPost =>
      _contentCtrl.text.trim().isNotEmpty || _image != null;

  @override
  void initState() {
    super.initState();
    _contentCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final img =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) {
      setState(() => _image = img);
    }
  }

  void _submit() {
    if (!_canPost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy nhập nội dung hoặc chọn ít nhất 1 ảnh'),
        ),
      );
      return;
    }

    final data = NewPostData(
      content: _contentCtrl.text.trim(),
      imagePath: _image?.path,
    );

    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('Bài viết mới'),
        actions: [
          TextButton(
            onPressed: _canPost ? _submit : null,
            child: Text(
              'Đăng',
              style: TextStyle(
                color: _canPost ? Colors.blue : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // avatar + tên (cho giống MXH)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Text(
                  'Phạm Văn Tri',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ô "Bạn đang nghĩ gì?"
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _contentCtrl,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Bạn đang nghĩ gì?',
                  hintStyle: TextStyle(fontSize: 20, color: Colors.grey),
                ),
              ),
            ),
          ),

          // preview ảnh nếu có
          if (_image != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: Image.file(
                    File(_image!.path),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          // nút Thư viện
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Thư viện'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

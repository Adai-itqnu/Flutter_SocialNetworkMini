import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../services/imgbb_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  bool _isUploading = false;

  bool get _canPost => _captionController.text.trim().isNotEmpty || _selectedImage != null;

  @override
  void initState() {
    super.initState();
    _captionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (img != null) {
      setState(() => _selectedImage = img);
    }
  }

  Future<void> _submit() async {
    if (!_canPost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy nhập caption hoặc chọn ít nhất 1 ảnh'),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final postProvider = context.read<PostProvider>();

    if (authProvider.firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập để đăng bài')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      List<String> imageUrls = [];

      // Upload image to ImgBB if selected
      if (_selectedImage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang upload ảnh...')),
        );

        final imageUrl = await ImgBBService.uploadImage(_selectedImage!);
        imageUrls.add(imageUrl);
      }

      // Create post in Firestore
      final success = await postProvider.createPost(
        userId: authProvider.firebaseUser!.uid,
        caption: _captionController.text.trim(),
        imageUrls: imageUrls,
      );

      if (mounted) {
        setState(() => _isUploading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng bài thành công!')),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(postProvider.error ?? 'Đăng bài thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userModel = authProvider.userModel;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('Bài viết mới'),
        actions: [
          TextButton(
            onPressed: (_canPost && !_isUploading) ? _submit : null,
            child: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Đăng',
                    style: TextStyle(
                      color: _canPost ? Colors.blue : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: userModel?.photoURL != null
                        ? NetworkImage(userModel!.photoURL!)
                        : null,
                    child: userModel?.photoURL == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    userModel?.displayName ?? 'User',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Caption input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _captionController,
                maxLines: 5,
                enabled: !_isUploading,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Bạn đang nghĩ gì?',
                  hintStyle: TextStyle(fontSize: 20, color: Colors.grey),
                ),
              ),
            ),

            // Image preview
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 1, // Square for better display
                        child: FutureBuilder<Uint8List>(
                          future: _selectedImage!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              );
                            }
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (!_isUploading)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => setState(() => _selectedImage = null),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Gallery button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isUploading ? null : _pickFromGallery,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Thư viện'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Add bottom padding for keyboard
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

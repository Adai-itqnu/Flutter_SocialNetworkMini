import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/post_model.dart';
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

  // Support multiple images and videos
  List<XFile> _selectedMedia = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  PostVisibility _selectedVisibility = PostVisibility.public;
  
  // Limits (Images only - ImgBB doesn't support video)
  static const int maxMediaCount = 10;
  static const int maxFileSizeMB = 10; // 10MB per image
  static const int maxTotalSizeMB = 50; // 50MB total

  bool get _canPost =>
      _captionController.text.trim().isNotEmpty || _selectedMedia.isNotEmpty;

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

  /// Pick multiple images from gallery
  Future<void> _pickFromGallery() async {
    if (_selectedMedia.length >= maxMediaCount) {
      _showLimitMessage('Tối đa $maxMediaCount ảnh');
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      // Limit to remaining slots
      final remainingSlots = maxMediaCount - _selectedMedia.length;
      final imagesToAdd = images.take(remainingSlots).toList();

      if (imagesToAdd.isNotEmpty) {
        await _validateAndAddMedia(imagesToAdd);
      }
      
      if (images.length > remainingSlots) {
        _showLimitMessage('Chỉ thêm được $remainingSlots ảnh nữa');
      }
    } catch (e) {
      _showErrorMessage('Lỗi khi chọn ảnh: $e');
    }
  }

  /// Take photo from camera
  Future<void> _takePhoto() async {
    if (_selectedMedia.length >= maxMediaCount) {
      _showLimitMessage('Tối đa $maxMediaCount ảnh/video');
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        await _validateAndAddMedia([photo]);
      }
    } catch (e) {
      _showErrorMessage('Lỗi khi chụp ảnh: $e');
    }
  }

  /// Validate file sizes and add to selected media
  Future<void> _validateAndAddMedia(List<XFile> files) async {
    List<XFile> validFiles = [];
    
    for (final file in files) {
      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);

      if (fileSizeMB > maxFileSizeMB) {
        _showLimitMessage(
          '${file.name} vượt quá ${maxFileSizeMB}MB, đã bỏ qua',
        );
        continue;
      }

      // Calculate total size
      int totalSize = fileSize;
      for (final existing in _selectedMedia) {
        totalSize += await existing.length();
      }
      for (final valid in validFiles) {
        totalSize += await valid.length();
      }

      if (totalSize / (1024 * 1024) > maxTotalSizeMB) {
        _showLimitMessage('Tổng dung lượng vượt quá ${maxTotalSizeMB}MB');
        break;
      }

      validFiles.add(file);
    }

    if (validFiles.isNotEmpty) {
      setState(() {
        _selectedMedia.addAll(validFiles);
      });
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  void _showLimitMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_canPost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy nhập caption hoặc chọn ít nhất 1 ảnh/video'),
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

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      List<String> imageUrls = [];

      // Upload all media files
      if (_selectedMedia.isNotEmpty) {
        for (int i = 0; i < _selectedMedia.length; i++) {
          final file = _selectedMedia[i];
          
          setState(() {
            _uploadProgress = (i + 1) / _selectedMedia.length;
          });

          final imageUrl = await ImgBBService.uploadImage(file);
          imageUrls.add(imageUrl);
        }
      }

      // Create post in Firestore
      final success = await postProvider.createPost(
        userId: authProvider.firebaseUser!.uid,
        caption: _captionController.text.trim(),
        imageUrls: imageUrls,
        visibility: _selectedVisibility,
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
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
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
                ? SizedBox(
                    width: 60,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: _uploadProgress > 0 ? _uploadProgress : null,
                          ),
                        ),
                        if (_uploadProgress > 0)
                          Text(
                            '${(_uploadProgress * 100).toInt()}%',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                      ],
                    ),
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
                        ? CachedNetworkImageProvider(userModel!.photoURL!)
                        : null,
                    child: userModel?.photoURL == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userModel?.displayName ?? 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (_selectedMedia.isNotEmpty)
                        Text(
                          '${_selectedMedia.length}/$maxMediaCount ảnh/video',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Visibility selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PostVisibility>(
                    value: _selectedVisibility,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    items: const [
                      DropdownMenuItem(
                        value: PostVisibility.public,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.public, size: 16, color: Colors.blue),
                            SizedBox(width: 6),
                            Text('Công khai', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: PostVisibility.followersOnly,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people, size: 16, color: Colors.green),
                            SizedBox(width: 6),
                            Text('Người theo dõi', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                    onChanged: _isUploading ? null : (value) {
                      if (value != null) setState(() => _selectedVisibility = value);
                    },
                  ),
                ),
              ),
            ),

            // Caption input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _captionController,
                maxLines: 5,
                maxLength: 2000,
                enabled: !_isUploading,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Bạn đang nghĩ gì?',
                  hintStyle: TextStyle(fontSize: 20, color: Colors.grey),
                  counterStyle: TextStyle(fontSize: 12),
                ),
              ),
            ),

            // Media preview grid
            if (_selectedMedia.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _buildMediaGrid(),
              ),

            // Media buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16)
                  .copyWith(bottom: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMediaButton(
                    icon: Icons.image_outlined,
                    label: 'Thư viện',
                    onPressed: _isUploading ? null : _pickFromGallery,
                  ),
                  _buildMediaButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Chụp ảnh',
                    onPressed: _isUploading ? null : _takePhoto,
                  ),
                ],
              ),
            ),

            // File size info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Giới hạn: ${maxFileSizeMB}MB/ảnh, tối đa $maxMediaCount ảnh, tổng ${maxTotalSizeMB}MB',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),

            // Add bottom padding for keyboard
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildMediaGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _selectedMedia.length == 1 ? 1 : 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: _selectedMedia.length == 1 ? 1.5 : 1,
      ),
      itemCount: _selectedMedia.length,
      itemBuilder: (context, index) => _buildMediaItem(index),
    );
  }

  Widget _buildMediaItem(int index) {
    final file = _selectedMedia[index];

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[200],
            child: FutureBuilder<Uint8List>(
              future: file.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallbackPreview(file, 'Không thể preview');
                    },
                  );
                }
                if (snapshot.hasError) {
                  return _buildFallbackPreview(file, 'Lỗi tải ảnh');
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
        
        // Remove button
        if (!_isUploading)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _removeMedia(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          
        // Index number
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build fallback preview for files that can't be displayed
  Widget _buildFallbackPreview(XFile file, String message) {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, size: 40, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                file.name,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(fontSize: 10, color: Colors.orange[700]),
            ),
          ],
        ),
      ),
    );
  }
}


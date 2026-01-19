import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../services/imgbb_service.dart';

/// Màn hình tạo bài viết mới
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // State
  List<XFile> _selectedMedia = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  PostVisibility _selectedVisibility = PostVisibility.public;

  // Giới hạn upload (ImgBB)
  static const int maxMediaCount = 10;
  static const int maxFileSizeMB = 10;
  static const int maxTotalSizeMB = 50;

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

  // Chọn ảnh từ thư viện
  Future<void> _pickFromGallery() async {
    if (_selectedMedia.length >= maxMediaCount) {
      _showMessage('Tối đa $maxMediaCount ảnh', isError: false);
      return;
    }

    try {
      final images = await _picker.pickMultiImage(imageQuality: 85);
      final remainingSlots = maxMediaCount - _selectedMedia.length;
      final imagesToAdd = images.take(remainingSlots).toList();

      if (imagesToAdd.isNotEmpty) {
        await _validateAndAddMedia(imagesToAdd);
      }

      if (images.length > remainingSlots) {
        _showMessage('Chỉ thêm được $remainingSlots ảnh nữa', isError: false);
      }
    } catch (e) {
      _showMessage('Lỗi khi chọn ảnh: $e', isError: true);
    }
  }

  // Chụp ảnh từ camera
  Future<void> _takePhoto() async {
    if (_selectedMedia.length >= maxMediaCount) {
      _showMessage('Tối đa $maxMediaCount ảnh', isError: false);
      return;
    }

    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null) {
        await _validateAndAddMedia([photo]);
      }
    } catch (e) {
      _showMessage('Lỗi khi chụp ảnh: $e', isError: true);
    }
  }

  // Kiểm tra dung lượng file và thêm vào danh sách
  Future<void> _validateAndAddMedia(List<XFile> files) async {
    List<XFile> validFiles = [];

    for (final file in files) {
      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);

      // Kiểm tra dung lượng từng file
      if (fileSizeMB > maxFileSizeMB) {
        _showMessage('${file.name} vượt quá ${maxFileSizeMB}MB', isError: false);
        continue;
      }

      // Tính tổng dung lượng
      int totalSize = fileSize;
      for (final existing in _selectedMedia) {
        totalSize += await existing.length();
      }
      for (final valid in validFiles) {
        totalSize += await valid.length();
      }

      if (totalSize / (1024 * 1024) > maxTotalSizeMB) {
        _showMessage('Tổng dung lượng vượt quá ${maxTotalSizeMB}MB', isError: false);
        break;
      }

      validFiles.add(file);
    }

    if (validFiles.isNotEmpty) {
      setState(() => _selectedMedia.addAll(validFiles));
    }
  }

  // Xóa ảnh khỏi danh sách
  void _removeMedia(int index) {
    setState(() => _selectedMedia.removeAt(index));
  }

  // Hiển thị thông báo
  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.orange,
      ),
    );
  }

  // Đăng bài viết
  Future<void> _submit() async {
    if (!_canPost) {
      _showMessage('Hãy nhập caption hoặc chọn ít nhất 1 ảnh', isError: true);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final postProvider = context.read<PostProvider>();

    if (authProvider.firebaseUser == null) {
      _showMessage('Bạn cần đăng nhập để đăng bài', isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Upload ảnh lên ImgBB
      List<String> imageUrls = [];
      for (int i = 0; i < _selectedMedia.length; i++) {
        setState(() => _uploadProgress = (i + 1) / _selectedMedia.length);
        final imageUrl = await ImgBBService.uploadImage(_selectedMedia[i]);
        imageUrls.add(imageUrl);
      }

      // Tạo bài viết trong Firestore
      final success = await postProvider.createPost(
        userId: authProvider.firebaseUser!.uid,
        caption: _captionController.text.trim(),
        imageUrls: imageUrls,
        visibility: _selectedVisibility,
      );

      if (mounted) {
        setState(() => _isUploading = false);
        if (success) {
          _showMessage('Đăng bài thành công!', isError: false);
          Navigator.of(context).pop();
        } else {
          _showMessage(postProvider.error ?? 'Đăng bài thất bại', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showMessage('Lỗi: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModel = context.watch<AuthProvider>().userModel;

    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfo(userModel),
            _buildVisibilitySelector(),
            _buildCaptionInput(),
            if (_selectedMedia.isNotEmpty) _buildMediaGrid(),
            _buildMediaButtons(),
            _buildLimitInfo(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // AppBar với nút đóng và nút đăng
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
              ? _buildUploadingIndicator()
              : Text(
                  'Đăng',
                  style: TextStyle(
                    color: _canPost ? Colors.blue : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  // Indicator khi đang upload
  Widget _buildUploadingIndicator() {
    return SizedBox(
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
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  // Thông tin người dùng
  Widget _buildUserInfo(userModel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: userModel?.photoURL != null
                ? CachedNetworkImageProvider(userModel!.photoURL!)
                : null,
            child: userModel?.photoURL == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userModel?.displayName ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              if (_selectedMedia.isNotEmpty)
                Text(
                  '${_selectedMedia.length}/$maxMediaCount ảnh',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Dropdown chọn quyền riêng tư
  Widget _buildVisibilitySelector() {
    return Padding(
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
            onChanged: _isUploading
                ? null
                : (value) {
                    if (value != null) setState(() => _selectedVisibility = value);
                  },
          ),
        ),
      ),
    );
  }

  // Ô nhập caption
  Widget _buildCaptionInput() {
    return Padding(
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
    );
  }

  // Grid hiển thị ảnh đã chọn
  Widget _buildMediaGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GridView.builder(
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
      ),
    );
  }

  // Một item ảnh trong grid
  Widget _buildMediaItem(int index) {
    final file = _selectedMedia[index];

    return Stack(
      children: [
        // Ảnh preview
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
                  return Image.memory(snapshot.data!, fit: BoxFit.cover);
                }
                if (snapshot.hasError) {
                  return _buildFallbackPreview(file);
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),

        // Nút xóa
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
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),

        // Số thứ tự
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

  // Preview khi không load được ảnh
  Widget _buildFallbackPreview(XFile file) {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, size: 40, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              file.name,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Các nút chọn ảnh
  Widget _buildMediaButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // Thông tin giới hạn
  Widget _buildLimitInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Giới hạn: ${maxFileSizeMB}MB/ảnh, tối đa $maxMediaCount ảnh, tổng ${maxTotalSizeMB}MB',
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
    );
  }
}

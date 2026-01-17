import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/imgbb_service.dart';

/// Dialog chọn/upload ảnh đại diện với preview
/// Hiển thị: preview ảnh, chọn từ thư viện/camera, chọn từ bài đăng
class AvatarPickerDialog extends StatefulWidget {
  final String? currentPhotoURL;
  final Function(String newPhotoURL) onSave;

  const AvatarPickerDialog({super.key, required this.currentPhotoURL, required this.onSave});

  // Mở dialog dạng bottom sheet
  static Future<void> show(BuildContext context, {required String? currentPhotoURL, required Function(String newPhotoURL) onSave}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => AvatarPickerDialog(currentPhotoURL: currentPhotoURL, onSave: onSave),
      ),
    );
  }

  @override
  State<AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<AvatarPickerDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  String? _previewUrl;
  XFile? _selectedFile;
  bool _isLoading = false;
  bool _isUploading = false;
  List<String> _userImageUrls = [];

  @override
  void initState() {
    super.initState();
    _previewUrl = widget.currentPhotoURL;
    _loadUserImages();
  }

  // Tải ảnh từ bài đăng của user
  Future<void> _loadUserImages() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = context.read<AuthProvider>().userModel;
      if (currentUser == null) return;

      _firestoreService.getUserPosts(currentUser.uid).listen((posts) {
        if (mounted) {
          final images = <String>[];
          for (final post in posts) images.addAll(post.imageUrls);
          setState(() { _userImageUrls = images.take(20).toList(); _isLoading = false; });
        }
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Chọn ảnh từ thư viện
  Future<void> _pickFromGallery() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) setState(() { _selectedFile = image; _previewUrl = null; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi chọn ảnh: $e')));
    }
  }

  // Chụp ảnh từ camera
  Future<void> _pickFromCamera() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
      if (image != null) setState(() { _selectedFile = image; _previewUrl = null; });
    } catch (e) {
      if (mounted) {
        String message = e.toString().contains('permission') ? 'Vui lòng cho phép truy cập camera trong trình duyệt.' : 'Lỗi khi chụp ảnh';
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Camera'),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
              TextButton(onPressed: () { Navigator.pop(context); _pickFromGallery(); }, child: const Text('Chọn từ thư viện')),
            ],
          ),
        );
      }
    }
  }

  // Chọn ảnh từ bài đăng
  void _selectFromPosts(String imageUrl) => setState(() { _previewUrl = imageUrl; _selectedFile = null; });

  // Lưu avatar
  Future<void> _saveAvatar() async {
    if (_previewUrl == null && _selectedFile == null) return;
    setState(() => _isUploading = true);

    try {
      String finalUrl;
      if (_selectedFile != null) {
        finalUrl = await ImgBBService.uploadImage(_selectedFile!);
      } else {
        finalUrl = _previewUrl!;
      }

      widget.onSave(finalUrl);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) { setState(() => _isUploading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'))); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Drag handle
      Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
      // Tiêu đề
      const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Chọn ảnh đại diện', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
      const SizedBox(height: 16),
      // Preview avatar
      Center(child: Stack(children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blue, width: 3)),
          child: ClipOval(child: _buildPreview()),
        ),
        if (_isUploading) Positioned.fill(child: Container(decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle), child: const Center(child: CircularProgressIndicator(color: Colors.white)))),
      ])),
      const SizedBox(height: 16),
      // Buttons chọn ảnh
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _buildActionButton(icon: Icons.photo_library, label: 'Thư viện', onTap: _pickFromGallery),
        const SizedBox(width: 24),
        _buildActionButton(icon: Icons.camera_alt, label: 'Camera', onTap: _pickFromCamera),
      ]),
      const SizedBox(height: 16),
      const Divider(),
      // Tiêu đề grid ảnh
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          const Text('Chọn từ bài đăng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          if (_isLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        ]),
      ),
      // Grid ảnh từ bài đăng
      Expanded(
        child: _userImageUrls.isEmpty && !_isLoading
            ? Center(child: Text('Chưa có ảnh nào', style: TextStyle(color: Colors.grey[500])))
            : GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: _userImageUrls.length,
                itemBuilder: (context, index) {
                  final imageUrl = _userImageUrls[index];
                  final isSelected = _previewUrl == imageUrl && _selectedFile == null;
                  return GestureDetector(
                    onTap: () => _selectFromPosts(imageUrl),
                    child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: isSelected ? Border.all(color: Colors.blue, width: 3) : null),
                      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover, placeholder: (_, __) => Container(color: Colors.grey[200]))),
                    ),
                  );
                },
              ),
      ),
      // Nút Lưu
      Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_previewUrl != null || _selectedFile != null) && !_isUploading ? _saveAvatar : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: _isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Lưu ảnh đại diện', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildPreview() {
    if (_selectedFile != null) {
      return FutureBuilder<Widget>(
        future: _buildLocalPreview(),
        builder: (context, snapshot) {
          if (snapshot.hasData) return snapshot.data!;
          return Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
        },
      );
    } else if (_previewUrl != null && _previewUrl!.isNotEmpty) {
      return CachedNetworkImage(imageUrl: _previewUrl!, fit: BoxFit.cover, placeholder: (_, __) => Container(color: Colors.grey[200]));
    }
    return Container(color: Colors.grey[200], child: Icon(Icons.person, size: 60, color: Colors.grey[400]));
  }

  Future<Widget> _buildLocalPreview() async {
    final bytes = await _selectedFile!.readAsBytes();
    return Image.memory(bytes, fit: BoxFit.cover);
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle), child: Icon(icon, size: 28, color: Colors.black87)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }
}

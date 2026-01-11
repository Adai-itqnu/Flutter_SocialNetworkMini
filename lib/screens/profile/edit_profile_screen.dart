import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_model.dart';
import '../../providers/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _pronounsCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _linkCtrl;
  late final TextEditingController _taglineCtrl;
  late final TextEditingController _genderCtrl;

  XFile? _selectedImage;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _displayNameCtrl = TextEditingController(text: widget.user.displayName);
    _usernameCtrl = TextEditingController(text: widget.user.username);
    _pronounsCtrl = TextEditingController(text: widget.user.pronouns ?? '');
    _bioCtrl = TextEditingController(text: widget.user.bio ?? '');
    _linkCtrl = TextEditingController(text: widget.user.link ?? '');
    _taglineCtrl = TextEditingController(text: widget.user.tagline ?? '');
    _genderCtrl = TextEditingController(text: widget.user.gender ?? '');

    for (final c in [
      _displayNameCtrl,
      _usernameCtrl,
      _pronounsCtrl,
      _bioCtrl,
      _linkCtrl,
      _taglineCtrl,
      _genderCtrl
    ]) {
      c.addListener(_checkChanges);
    }
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _usernameCtrl.dispose();
    _pronounsCtrl.dispose();
    _bioCtrl.dispose();
    _linkCtrl.dispose();
    _taglineCtrl.dispose();
    _genderCtrl.dispose();
    super.dispose();
  }

  void _checkChanges() {
    final changed = _hasProfileChanged();
    if (changed != _hasChanged) {
      setState(() => _hasChanged = changed);
    }
  }

  bool _hasProfileChanged() {
    return _displayNameCtrl.text != widget.user.displayName ||
        _usernameCtrl.text != widget.user.username ||
        _pronounsCtrl.text != (widget.user.pronouns ?? '') ||
        _bioCtrl.text != (widget.user.bio ?? '') ||
        _linkCtrl.text != (widget.user.link ?? '') ||
        _taglineCtrl.text != (widget.user.tagline ?? '') ||
        _genderCtrl.text != (widget.user.gender ?? '') ||
        _selectedImage != null;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _hasChanged = true;
      });
    }
  }

  Future<void> _save() async {
    if (!_hasChanged) return;

    final userProvider = context.read<UserProvider>();
    
    final data = <String, dynamic>{
      'displayName': _displayNameCtrl.text.trim(),
      'username': _usernameCtrl.text.trim(),
      'pronouns': _pronounsCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'link': _linkCtrl.text.trim(),
      'tagline': _taglineCtrl.text.trim(),
      'gender': _genderCtrl.text.trim(),
    };

    final success = await userProvider.updateProfileWithAvatar(
      uid: widget.user.uid,
      data: data,
      avatarFile: _selectedImage,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật thông tin thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userProvider.error ?? 'Có lỗi xảy ra'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: userProvider.isSaving ? null : () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Chỉnh sửa trang cá nhân',
              style: TextStyle(color: Colors.black),
            ),
            actions: [
              if (userProvider.isSaving)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  onPressed: _hasChanged ? _save : null,
                  icon: Icon(
                    Icons.check,
                    color: _hasChanged ? Colors.blue : Colors.grey,
                  ),
                ),
            ],
          ),
          body: AbsorbPointer(
            absorbing: userProvider.isSaving,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==== AVATAR SECTION ====
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              _buildAvatar(),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _pickImage,
                          child: const Text('Đổi ảnh đại diện'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _LabeledField(label: 'Tên hiển thị', controller: _displayNameCtrl),
                  _LabeledField(label: 'Tên người dùng', controller: _usernameCtrl),
                  _LabeledField(label: 'Danh xưng', controller: _pronounsCtrl),
                  _LabeledField(label: 'Tiểu sử', controller: _taglineCtrl),
                  _LabeledField(label: 'Thêm liên kết', controller: _linkCtrl),
                  _LabeledField(label: 'Giới thiệu', controller: _bioCtrl, maxLines: 3),
                  _LabeledField(label: 'Giới tính', controller: _genderCtrl),

                  const SizedBox(height: 20),

                  Text(
                    'Thông tin trên trang cá nhân',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ==== INFO CARD ====
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.email_outlined, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text('Email', style: theme.textTheme.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.user.email,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text('Ngày tham gia', style: theme.textTheme.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.user.createdAt.day}/${widget.user.createdAt.month}/${widget.user.createdAt.year}',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar() {
    if (_selectedImage != null) {
      return FutureBuilder<dynamic>(
        future: _selectedImage!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return CircleAvatar(
              radius: 50,
              backgroundImage: MemoryImage(snapshot.data),
            );
          }
          return const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey,
            child: CircularProgressIndicator(),
          );
        },
      );
    }

    final photoURL = widget.user.photoURL;
    if (photoURL != null && photoURL.isNotEmpty) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage(photoURL),
      );
    }

    return const CircleAvatar(
      radius: 50,
      backgroundColor: Colors.grey,
      child: Icon(Icons.person, size: 50, color: Colors.white),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Colors.blueAccent, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

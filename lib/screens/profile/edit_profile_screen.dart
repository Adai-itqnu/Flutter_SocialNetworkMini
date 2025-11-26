import 'package:flutter/material.dart';
import 'profile_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _pronounsCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _linkCtrl;
  late final TextEditingController _taglineCtrl;
  late final TextEditingController _genderCtrl;

  bool _showThreadsBadge = false;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.name);
    _usernameCtrl = TextEditingController(text: widget.profile.username);
    _pronounsCtrl = TextEditingController(text: widget.profile.pronouns);
    _bioCtrl = TextEditingController(text: widget.profile.bio);
    _linkCtrl = TextEditingController(text: widget.profile.link);
    _taglineCtrl = TextEditingController(text: widget.profile.tagline);
    _genderCtrl = TextEditingController(text: widget.profile.gender);
    _showThreadsBadge = widget.profile.showThreadsBadge;

    for (final c in [
      _nameCtrl,
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
    _nameCtrl.dispose();
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
    return _nameCtrl.text != widget.profile.name ||
        _usernameCtrl.text != widget.profile.username ||
        _pronounsCtrl.text != widget.profile.pronouns ||
        _bioCtrl.text != widget.profile.bio ||
        _linkCtrl.text != widget.profile.link ||
        _taglineCtrl.text != widget.profile.tagline ||
        _genderCtrl.text != widget.profile.gender ||
        _showThreadsBadge != widget.profile.showThreadsBadge;
  }

  void _save() {
    if (!_hasChanged) return;

    Navigator.of(context).pop(
      widget.profile.copyWith(
        name: _nameCtrl.text,
        username: _usernameCtrl.text,
        pronouns: _pronounsCtrl.text,
        bio: _bioCtrl.text,
        link: _linkCtrl.text,
        tagline: _taglineCtrl.text,
        gender: _genderCtrl.text,
        showThreadsBadge: _showThreadsBadge,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Chỉnh sửa trang cá nhân',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: _hasChanged ? _save : null,
            icon: Icon(
              Icons.check,
              color: _hasChanged ? Colors.blue : Colors.grey,
            ),
          ),
        ],
      ),

      // BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==== AVATAR ====
            Row(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.camera_alt_outlined, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.black12,
                  child: Icon(Icons.person, size: 36),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () {},
                  child: const Text('Đổi ảnh đại diện'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _LabeledField(label: 'Tên', controller: _nameCtrl),
            _LabeledField(label: 'Tên người dùng', controller: _usernameCtrl),
            _LabeledField(label: 'Danh xưng', controller: _pronounsCtrl),
            _LabeledField(label: 'Tiểu sử', controller: _taglineCtrl),
            _LabeledField(label: 'Thêm liên kết', controller: _linkCtrl),
            _LabeledField(label: 'Biểu ngữ', controller: _bioCtrl),
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
                  Text('Trang', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Chưa liên kết trang',
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

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

          // INPUT FIELD SÁNG
          TextField(
            controller: controller,
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

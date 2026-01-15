import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/user_model.dart';
import '../../../providers/user_provider.dart';
import '../../../widgets/avatar_picker_dialog.dart';

/// Widget hiển thị header thông tin profile
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.user, required this.onEdit});

  final UserModel user;
  final VoidCallback onEdit;

  void _showAvatarPicker(BuildContext context) {
    AvatarPickerDialog.show(
      context,
      currentPhotoURL: user.photoURL,
      onSave: (newUrl) async {
        final userProvider = context.read<UserProvider>();
        await userProvider.updateProfile(user.uid, {'photoURL': newUrl});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar - tap to change
              GestureDetector(
                onTap: () => _showAvatarPicker(context),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                          user.photoURL != null && user.photoURL!.isNotEmpty
                          ? CachedNetworkImageProvider(user.photoURL!)
                          : null,
                      child: user.photoURL == null || user.photoURL!.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 44,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      count: user.postsCount.toString(),
                      label: 'Bài viết',
                    ),
                    _StatItem(
                      count: user.followersCount.toString(),
                      label: 'Người theo dõi',
                    ),
                    _StatItem(
                      count: user.followingCount.toString(),
                      label: 'Đang theo dõi',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(user.bio!, style: const TextStyle(fontSize: 14)),
          ],
          if (user.link != null && user.link!.isNotEmpty) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: () async {
                final link = user.link!;
                final uri = Uri.tryParse(
                  link.startsWith('http') ? link : 'https://$link',
                );
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                user.link!,
                style: const TextStyle(color: Colors.blue, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget hiển thị số thống kê
class _StatItem extends StatelessWidget {
  const _StatItem({required this.count, required this.label});

  final String count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}

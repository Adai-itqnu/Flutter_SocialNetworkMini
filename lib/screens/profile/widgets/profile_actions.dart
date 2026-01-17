import 'package:flutter/material.dart';

/// Widget các nút hành động trên profile (Chỉnh sửa, Chia sẻ)
class ProfileActions extends StatelessWidget {
  const ProfileActions({super.key, required this.onEdit, required this.onShare});

  final VoidCallback onEdit;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Nút chỉnh sửa profile
          Expanded(
            child: OutlinedButton(
              onPressed: onEdit,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
              child: const Text('Chỉnh sửa'),
            ),
          ),
          const SizedBox(width: 8),
          // Nút chia sẻ profile
          Expanded(
            child: OutlinedButton(
              onPressed: onShare,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
              child: const Text('Chia sẻ'),
            ),
          ),
        ],
      ),
    );
  }
}

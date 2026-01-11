import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Dialog hiển thị avatar to, tròn khi người khác nhấn xem
class AvatarViewDialog extends StatelessWidget {
  final String? imageUrl;
  final String displayName;

  const AvatarViewDialog({
    super.key,
    required this.imageUrl,
    required this.displayName,
  });

  static void show(BuildContext context, {
    required String? imageUrl,
    required String displayName,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => AvatarViewDialog(
        imageUrl: imageUrl,
        displayName: displayName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Hero(
            tag: 'avatar_$displayName',
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.width * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipOval(
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.grey[300],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.person,
                            size: 100,
                            color: Colors.grey[500],
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.grey[500],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/post_card.dart';
import '../profile/user_profile_screen.dart';

/// Màn hình hiển thị danh sách thông báo
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Khởi tạo stream thông báo sau khi widget được build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final notificationProvider = context.read<NotificationProvider>();

      if (authProvider.firebaseUser != null &&
          notificationProvider.notifications.isEmpty) {
        notificationProvider.initializeNotificationStream(
          authProvider.firebaseUser!.uid,
        );
      }
    });
  }

  // Lấy icon theo loại thông báo
  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.comment;
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.newPost:
        return Icons.post_add;
      case NotificationType.share:
        return Icons.share;
    }
  }

  // Lấy màu theo loại thông báo
  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return Colors.red;
      case NotificationType.comment:
        return Colors.blue;
      case NotificationType.follow:
        return Colors.green;
      case NotificationType.newPost:
        return Colors.purple;
      case NotificationType.share:
        return Colors.orange;
    }
  }

  // Xử lý khi tap vào thông báo
  void _onNotificationTap(NotificationModel notification) async {
    final notificationProvider = context.read<NotificationProvider>();

    // Đánh dấu đã đọc
    if (!notification.isRead) {
      notificationProvider.markAsRead(notification.notificationId);
    }

    // Điều hướng theo loại thông báo
    if (notification.type == NotificationType.follow) {
      // Follow -> mở profile người theo dõi
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(userId: notification.fromUserId),
        ),
      );
    } else if (notification.postId != null) {
      // Like/Comment/Share -> mở bài viết
      await _openPostDetail(notification.postId!);
    } else {
      // Fallback -> mở profile
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(userId: notification.fromUserId),
        ),
      );
    }
  }

  // Mở bottom sheet hiển thị chi tiết bài viết
  Future<void> _openPostDetail(String postId) async {
    try {
      final firestoreService = FirestoreService();
      final post = await firestoreService.getPost(postId);

      if (post == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bài viết không còn tồn tại')),
          );
        }
        return;
      }

      final author = await firestoreService.getUser(post.userId);

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  // Thanh kéo
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  PostCard(post: post, author: author),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.notifications.isEmpty) {
            return _buildEmptyState();
          }
          return _buildNotificationsList(provider);
        },
      ),
    );
  }

  // AppBar với nút đánh dấu đã đọc
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Thông báo',
        style: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: Colors.black,
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            final hasUnread = provider.notifications.any((n) => !n.isRead);
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton(
                onPressed: hasUnread ? () => _markAllAsRead(provider) : null,
                child: Text(
                  'Đánh dấu đã đọc',
                  style: TextStyle(
                    fontSize: 14,
                    color: hasUnread ? Colors.blue : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Đánh dấu tất cả thông báo đã đọc
  void _markAllAsRead(NotificationProvider provider) {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.firebaseUser != null) {
      provider.markAllAsRead(authProvider.firebaseUser!.uid);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đánh dấu tất cả là đã đọc'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Trạng thái khi chưa có thông báo
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có thông báo nào',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thông báo sẽ xuất hiện khi có người\ntương tác với bạn',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Danh sách thông báo
  Widget _buildNotificationsList(NotificationProvider provider) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: provider.notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final notification = provider.notifications[index];
        final fromUser = provider.getNotificationUser(notification.fromUserId);

        return _NotificationCard(
          notification: notification,
          fromUser: fromUser,
          icon: _getNotificationIcon(notification.type),
          iconColor: _getNotificationColor(notification.type),
          onTap: () => _onNotificationTap(notification),
          onDismiss: () => provider.deleteNotification(notification.notificationId),
        );
      },
    );
  }
}

/// Widget hiển thị 1 thông báo
class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final UserModel? fromUser;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.fromUser,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final userName = fromUser?.displayName ?? 'Người dùng';
    final userPhoto = fromUser?.photoURL;
    final isRead = notification.isRead;
    final timeAgo = timeago.format(notification.createdAt, locale: 'vi');

    return Dismissible(
      key: Key(notification.notificationId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: _buildDismissBackground(),
      child: Card(
        elevation: isRead ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isRead
              ? BorderSide.none
              : BorderSide(color: Colors.blue.shade100, width: 1),
        ),
        color: isRead ? Colors.white : Colors.blue.shade50,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(userName, userPhoto),
                const SizedBox(width: 12),
                _buildContent(userName, timeAgo),
                if (!isRead) _buildUnreadIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Background khi vuốt để xóa
  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    );
  }

  // Avatar với icon loại thông báo
  Widget _buildAvatar(String userName, String? userPhoto) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[200],
          backgroundImage:
              userPhoto != null ? CachedNetworkImageProvider(userPhoto) : null,
          child: userPhoto == null
              ? Text(
                  userName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                )
              : null,
        ),
        // Badge icon loại thông báo
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.9),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(icon, size: 10, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // Nội dung thông báo
  Widget _buildContent(String userName, String timeAgo) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.3,
              ),
              children: [
                TextSpan(
                  text: userName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: ' ${notification.getContent(userName)}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeAgo,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Chấm xanh báo chưa đọc
  Widget _buildUnreadIndicator() {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
    );
  }
}

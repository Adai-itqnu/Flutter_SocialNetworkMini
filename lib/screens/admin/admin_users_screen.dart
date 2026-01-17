import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/user_model.dart';
import '../../services/admin_service.dart';

/// Màn hình quản lý người dùng cho Admin
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _adminService = AdminService();
  List<UserModel> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // Tải danh sách người dùng
  Future<void> _fetchUsers() async {
    try {
      setState(() => _loading = true);
      final data = await _adminService.getAllUsers();
      if (mounted) {
        setState(() {
          _users = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('Lỗi: $e', isError: true);
    }
  }

  // Hiển thị thông báo
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        backgroundColor: const Color(0xFF006CFF),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchUsers,
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (_, i) => _UserTile(
                  user: _users[i],
                  onDetails: _showUserDetails,
                  onDelete: _deleteUser,
                ),
              ),
            ),
    );
  }

  // Hiển thị chi tiết người dùng
  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(user.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Email', user.email),
            _detailRow('Username', '@${user.username}'),
            _detailRow('Role', user.role),
            _detailRow('Followers', user.followersCount.toString()),
            _detailRow('Following', user.followingCount.toString()),
            _detailRow('Posts', user.postsCount.toString()),
            if (user.bio != null) _detailRow('Bio', user.bio!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  // Một dòng thông tin chi tiết
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text('$label: $value'),
    );
  }

  // Xóa người dùng
  Future<void> _deleteUser(UserModel user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: Text('Bạn có chắc muốn xóa ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _adminService.deleteUser(user.uid);
      if (!mounted) return;
      _showMessage('Đã xóa tài khoản');
      _fetchUsers();
    } catch (e) {
      if (mounted) _showMessage('Lỗi: $e', isError: true);
    }
  }
}

// Card hiển thị thông tin user trong danh sách
class _UserTile extends StatelessWidget {
  final UserModel user;
  final Function(UserModel) onDetails;
  final Function(UserModel) onDelete;

  const _UserTile({
    required this.user,
    required this.onDetails,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
          child: user.photoURL == null ? const Icon(Icons.person) : null,
        ),
        title: Text(user.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${user.username}'),
            Text(
              'Tạo: ${timeago.format(user.createdAt, locale: 'vi')}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RoleBadge(user.role),
            const SizedBox(width: 8),
            PopupMenuButton(
              onSelected: (value) {
                if (value == 'details') onDetails(user);
                if (value == 'delete') onDelete(user);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'details', child: Text('Chi tiết')),
                if (user.role != 'admin')
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Xóa tài khoản', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

// Badge hiển thị role
class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge(this.role);

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? Colors.red.shade100 : Colors.blue.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'User',
        style: TextStyle(
          color: isAdmin ? Colors.red.shade700 : Colors.blue.shade700,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

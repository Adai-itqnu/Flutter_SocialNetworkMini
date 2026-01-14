import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import 'admin_users_screen.dart';
import 'admin_posts_screen.dart';
import 'admin_reports_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _adminService = AdminService();
  Map<String, int>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      setState(() => _loading = true);
      final data = await _adminService.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;

    if (user == null || user.role != 'admin') {
      return const _NoPermissionView();
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AdminHeader(user.displayName),
              const SizedBox(height: 24),
              _sectionTitle('Thống kê hệ thống'),
              const SizedBox(height: 16),
              _buildStats(),
              const SizedBox(height: 24),
              _sectionTitle('Quản lý'),
              const SizedBox(height: 16),
              _buildMenu(),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Bảng điều khiển Admin'),
      backgroundColor: const Color(0xFF006CFF),
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout,
        )
      ],
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đăng xuất')),
        ],
      ),
    );

    if (ok == true && mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  Widget _buildStats() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_stats == null) return const SizedBox();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _StatCard(title: 'Người dùng', value: _stats!['users'], icon: Icons.people, color: Colors.blue),
        _StatCard(title: 'Bài viết', value: _stats!['posts'], icon: Icons.article, color: Colors.green),
        _StatCard(title: 'Báo cáo', value: _stats!['pendingReports'], icon: Icons.flag, color: Colors.orange),
      ],
    );
  }

  Widget _buildMenu() {
    return Column(
      children: [
        _MenuCard(
          title: 'Quản lý người dùng',
          subtitle: 'Xem và khóa tài khoản',
          icon: Icons.people,
          color: Colors.blue,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
        ),
        const SizedBox(height: 12),
        _MenuCard(
          title: 'Quản lý bài viết',
          subtitle: 'Xóa bài vi phạm',
          icon: Icons.article,
          color: Colors.green,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPostsScreen())),
        ),
        const SizedBox(height: 12),
        _MenuCard(
          title: 'Báo cáo vi phạm',
          subtitle: 'Xử lý báo cáo',
          icon: Icons.flag,
          color: Colors.orange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportsScreen())),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
  }
}

/* ===================== SUB WIDGETS ===================== */

class _AdminHeader extends StatelessWidget {
  final String name;
  const _AdminHeader(this.name);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF006CFF), Color(0xFF0050C7)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Quản trị viên', style: TextStyle(color: Colors.white70)),
          ])
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int? value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
      ]),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 36, color: color),
        const SizedBox(height: 8),
        Text('${value ?? 0}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ]),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white, border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            ]),
          ),
          const Icon(Icons.chevron_right)
        ]),
      ),
    );
  }
}

class _NoPermissionView extends StatelessWidget {
  const _NoPermissionView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lock, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('Bạn không có quyền truy cập', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ]),
      ),
    );
  }
}

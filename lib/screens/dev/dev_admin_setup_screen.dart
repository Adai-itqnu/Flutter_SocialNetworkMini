import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/admin_utility.dart';
import '../../providers/auth_provider.dart';

/// 🔧 DEV ONLY - Screen để setup admin
/// Xóa screen này sau khi production!
class DevAdminSetupScreen extends StatefulWidget {
  const DevAdminSetupScreen({super.key});

  @override
  State<DevAdminSetupScreen> createState() => _DevAdminSetupScreenState();
}

class _DevAdminSetupScreenState extends State<DevAdminSetupScreen> {
  final AdminUtility _adminUtility = AdminUtility();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  List<Map<String, dynamic>>? _admins;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    try {
      final admins = await _adminUtility.getAllAdmins();
      if (mounted) {
        setState(() => _admins = admins);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = 'Lỗi: $e');
      }
    }
  }

  Future<void> _setAdminByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _message = 'Vui lòng nhập email');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _adminUtility.setAdminByEmail(email);
      if (mounted) {
        setState(() {
          _message = '✅ Đã set admin cho: $email';
          _emailController.clear();
        });
        await _loadAdmins();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = '❌ Lỗi: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _setCurrentUserAsAdmin() async {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) {
      setState(() => _message = 'Chưa đăng nhập');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _adminUtility.setAdminByUid(currentUser.uid);
      if (mounted) {
        setState(
          () => _message = '✅ Đã set admin cho bạn! Logout và login lại.',
        );
        await _loadAdmins();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = '❌ Lỗi: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _migrateUsers() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text(
          'Migrate tất cả users hiện tại để có field "role".\n\n'
          'Chỉ chạy một lần!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Migrate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _adminUtility.migrateExistingUsers();
      if (mounted) {
        setState(() => _message = '✅ Migration hoàn tất!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = '❌ Lỗi: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Admin Setup (DEV ONLY)'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Warning
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Text(
                      '⚠️ XÓA SCREEN NÀY TRƯỚC KHI PRODUCTION!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current user info
                  if (currentUser != null) ...[
                    Card(
                      child: ListTile(
                        title: Text('Bạn: ${currentUser.displayName}'),
                        subtitle: Text(
                          'Email: ${currentUser.email}\nRole: ${currentUser.role}',
                        ),
                        trailing: Icon(
                          currentUser.role == 'admin'
                              ? Icons.admin_panel_settings
                              : Icons.person,
                          color: currentUser.role == 'admin'
                              ? Colors.orange
                              : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick set self as admin
                    if (currentUser.role != 'admin')
                      ElevatedButton.icon(
                        onPressed: _setCurrentUserAsAdmin,
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('Set TÔI là Admin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],

                  // Set admin by email
                  const Text(
                    'Set Admin bằng Email:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'user@example.com',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _setAdminByEmail,
                    child: const Text('Set Admin'),
                  ),
                  const SizedBox(height: 24),

                  // Migrate button
                  OutlinedButton.icon(
                    onPressed: _migrateUsers,
                    icon: const Icon(Icons.upgrade),
                    label: const Text('Migrate Existing Users (Chạy 1 lần)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Message
                  if (_message != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _message!.startsWith('✅')
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _message!.startsWith('✅')
                              ? Colors.green.shade900
                              : Colors.red.shade900,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // List of admins
                  const Text(
                    'Danh sách Admins:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_admins == null)
                    const Center(child: CircularProgressIndicator())
                  else if (_admins!.isEmpty)
                    const Text('Chưa có admin nào')
                  else
                    ..._admins!.map(
                      (admin) => Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.orange,
                          ),
                          title: Text(admin['displayName'] ?? 'Unknown'),
                          subtitle: Text(
                            '@${admin['username']}\n${admin['email']}',
                          ),
                          isThreeLine: true,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

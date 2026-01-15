import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/validators.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/text_field_label.dart';
import '../../widgets/gradient_button.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePassword() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = context.read<AuthProvider>();
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Get error message immediately after signIn
      final errorMessage = authProvider.error;

      if (mounted) {
        if (success) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Đăng nhập thành công!')),
          );
          // Navigation will be handled automatically by main.dart
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(errorMessage ?? 'Đăng nhập thất bại'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Chào mừng trở lại',
      subtitle: 'Đăng nhập để tiếp tục trải nghiệm.',
      form: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TextFieldLabel('Email'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: emailValidator,
                  enabled: !authProvider.isLoading,
                ),
                const SizedBox(height: 20),
                const TextFieldLabel('Mật khẩu'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Thông tin bắt buộc';
                    }
                    if (value.length < 6) {
                      return 'Mật khẩu phải ít nhất 6 ký tự';
                    }
                    return null;
                  },
                  enabled: !authProvider.isLoading,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: _togglePassword,
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () => Navigator.pushNamed(
                              context,
                              '/forgot-password',
                            ),
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  onPressed: authProvider.isLoading ? null : _submit,
                  isLoading: authProvider.isLoading,
                  child: const Text('Đăng nhập'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[400])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Hoặc',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[400])),
                  ],
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          final success = await authProvider.signInWithGoogle();
                          if (mounted) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đăng nhập Google thành công!'),
                                ),
                              );
                            } else if (authProvider.error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(authProvider.error!),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  icon: Image.network(
                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                    height: 20,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.login, size: 20),
                  ),
                  label: const Text('Tiếp tục với Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () => Navigator.pushNamed(context, '/register'),
                  child: const Text('Tạo tài khoản mới'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
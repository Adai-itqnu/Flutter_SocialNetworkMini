import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/validators.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/text_field_label.dart';
import '../../widgets/gradient_button.dart';
import '../../providers/auth_provider.dart';

/// Màn hình đăng ký tài khoản mới
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const routeName = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Xử lý đăng ký
  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
        displayName: _displayNameController.text.trim(),
      );

      if (mounted) {
        if (success) {
          // Đăng xuất ngay sau khi đăng ký để bắt đăng nhập lại
          await authProvider.signOut();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
              backgroundColor: Colors.green,
            ),
          );

          // Quay về màn hình login
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Đăng ký thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Tạo tài khoản',
      subtitle: 'Chỉ mất vài giây để bắt đầu.',
      form: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Họ và tên
                const TextFieldLabel('Họ và tên'),
                TextFormField(
                  controller: _displayNameController,
                  validator: displayNameValidator,
                  enabled: !authProvider.isLoading,
                ),
                const SizedBox(height: 20),

                // Username
                const TextFieldLabel('Username'),
                TextFormField(
                  controller: _usernameController,
                  validator: usernameValidator,
                  enabled: !authProvider.isLoading,
                ),
                const SizedBox(height: 20),

                // Email
                const TextFieldLabel('Email'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: emailValidator,
                  enabled: !authProvider.isLoading,
                ),
                const SizedBox(height: 20),

                // Mật khẩu
                const TextFieldLabel('Mật khẩu'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: passwordValidator,
                  enabled: !authProvider.isLoading,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Nhập lại mật khẩu
                const TextFieldLabel('Nhập lại mật khẩu'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  validator: (value) => confirmPasswordValidator(value, _passwordController.text),
                  enabled: !authProvider.isLoading,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Nút đăng ký
                GradientButton(
                  onPressed: authProvider.isLoading ? null : _submit,
                  isLoading: authProvider.isLoading,
                  child: const Text('Đăng ký'),
                ),
                const SizedBox(height: 12),

                // Link đăng nhập
                TextButton(
                  onPressed: authProvider.isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Đã có tài khoản? Đăng nhập'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
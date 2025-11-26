import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/validators.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/text_field_label.dart';
import '../home/home_screen.dart'; // Import HomeScreen
import 'login_screen.dart'; // Import để quay lại login

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const routeName = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // Thêm controller cho confirm password
  final _emailController = TextEditingController(); // Thêm controller cho email

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Demo: Kiểm tra cơ bản (email không rỗng, password >=6 ký tự, khớp confirm)
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (email.isNotEmpty && password.length >= 6) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true); // Tự động đăng nhập sau đăng ký
        await prefs.setString('userEmail', email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng ký thành công! Đang chuyển đến trang chủ...')),
          );
          // Delay để hiển thị snackbar
          await Future.delayed(const Duration(seconds: 1));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng kiểm tra thông tin!')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Tạo tài khoản ✨',
      subtitle: 'Chỉ mất vài giây để bắt đầu.',
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TextFieldLabel('Họ và tên'),
            TextFormField(
              validator: requiredValidator,
            ),
            const SizedBox(height: 20),
            const TextFieldLabel('Email'),
            TextFormField(
              controller: _emailController, // Gán controller
              keyboardType: TextInputType.emailAddress,
              validator: requiredValidator, // Hoặc emailValidator
            ),
            const SizedBox(height: 20),
            const TextFieldLabel('Mật khẩu'),
            TextFormField(
              controller: _passwordController, // Gán controller
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Thông tin bắt buộc';
                if (value.length < 6) return 'Mật khẩu phải ít nhất 6 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 20),
            const TextFieldLabel('Nhập lại mật khẩu'),
            TextFormField(
              controller: _confirmPasswordController, // Gán controller
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Thông tin bắt buộc';
                }
                if (value != _passwordController.text) {
                  return 'Mật khẩu không khớp';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Đăng ký'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text('Đã có tài khoản? Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}
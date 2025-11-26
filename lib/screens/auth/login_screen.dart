import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/validators.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/text_field_label.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import '../home/home_screen.dart'; // Import HomeScreen để navigate

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login'; // Đổi thành '/login' để tránh conflict với '/'

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(); // Thêm controller cho email
  final _passwordController = TextEditingController(); // Thêm controller cho password
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
      // Demo: Kiểm tra tài khoản mẫu
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (email == 'admin@gmail.com' && password == '123456') {
        // Lưu trạng thái đăng nhập
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userEmail', email); // Lưu thêm email nếu cần
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng nhập thành công!')),
          );
          // Delay ngắn để hiển thị snackbar, rồi navigate
          await Future.delayed(const Duration(milliseconds: 1500));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email hoặc mật khẩu không đúng! Thử: demo@example.com / 123456')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Chào mừng trở lại 👋',
      subtitle: 'Đăng nhập để tiếp tục trải nghiệm.',
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TextFieldLabel('Email'),
            TextFormField(
              controller: _emailController, // Gán controller
              keyboardType: TextInputType.emailAddress,
              validator: requiredValidator, // Hoặc emailValidator nếu có
            ),
            const SizedBox(height: 20),
            const TextFieldLabel('Mật khẩu'),
            TextFormField(
              controller: _passwordController, // Gán controller
              obscureText: _obscurePassword,
              validator: requiredValidator,
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
                onPressed: () => Navigator.pushNamed(
                  context,
                  ForgotPasswordScreen.routeName,
                ),
                child: const Text('Quên mật khẩu?'),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Đăng nhập'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                RegisterScreen.routeName,
              ),
              child: const Text('Tạo tài khoản mới'),
            ),
          ],
        ),
      ),
    );
  }
}
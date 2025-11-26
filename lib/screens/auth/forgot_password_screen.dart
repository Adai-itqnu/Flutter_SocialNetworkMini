import 'package:flutter/material.dart';

import '../../utils/validators.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/text_field_label.dart';
import 'login_screen.dart'; // Import để quay lại login

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  static const routeName = '/forgot';

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(); // Thêm controller cho email

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Demo: Kiểm tra email mẫu
      final email = _emailController.text.trim();
      if (email == 'demo@example.com') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email đặt lại đã được gửi đến demo@example.com')),
          );
          // Quay lại login sau 2 giây
          await Future.delayed(const Duration(seconds: 2));
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email không tồn tại! Thử: demo@example.com')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Khôi phục mật khẩu 🔐',
      subtitle: 'Nhập email để nhận hướng dẫn đặt lại.',
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TextFieldLabel('Email'),
            TextFormField(
              controller: _emailController, // Gán controller
              keyboardType: TextInputType.emailAddress,
              validator: requiredValidator, // Hoặc emailValidator
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Gửi hướng dẫn'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Quay lại đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}
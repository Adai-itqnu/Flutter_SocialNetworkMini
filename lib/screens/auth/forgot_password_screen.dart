import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/validators.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/text_field_label.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  static const routeName = '/forgot-password';

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.resetPassword(
        _emailController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email đặt lại mật khẩu đã được gửi!'),
            ),
          );
          await Future.delayed(const Duration(seconds: 2));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Gửi email thất bại'),
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
      title: 'Khôi phục mật khẩu 🔐',
      subtitle: 'Nhập email để nhận hướng dẫn đặt lại.',
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
                  validator: requiredValidator,
                  enabled: !authProvider.isLoading,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _submit,
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Gửi hướng dẫn'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed:
                      authProvider.isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Quay lại đăng nhập'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
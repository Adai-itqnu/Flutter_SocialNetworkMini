import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart'; // Thêm import
import 'screens/auth/forgot_password_screen.dart'; // Thêm import

void main() {
  runApp(const SocialMockApp());
}

class SocialMockApp extends StatelessWidget {
  const SocialMockApp({super.key});

  // Hàm kiểm tra trạng thái đăng nhập
  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mạng xã hội',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(elevation: 0.5),
      ),
      // Sử dụng FutureBuilder để kiểm tra login
      home: FutureBuilder<bool>(
        future: _isLoggedIn(),
        builder: (context, snapshot) {  
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Nếu đã login, vào Home; chưa thì vào Login
          if (snapshot.hasData && snapshot.data == true) {
            return const HomeScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
      // Thêm routes để xử lý named navigation (tránh lỗi)
      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        ForgotPasswordScreen.routeName: (context) => const ForgotPasswordScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
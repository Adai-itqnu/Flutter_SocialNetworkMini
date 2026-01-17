import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/post_provider.dart';
import 'providers/user_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/follow_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'services/fcm_service.dart';
import 'utils/app_logger.dart';
import 'models/user_model.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Entry point của ứng dụng
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load biến môi trường từ file .env (không crash nếu thiếu)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    AppLogger.warn('[Main] .env load error: $e');
  }

  // Khởi tạo Firebase (xử lý nếu đã khởi tạo rồi)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    AppLogger.warn('[Main] Firebase init error (may already be initialized): $e');
  }

  // Khởi tạo FCM (Push Notifications)
  try {
    FCMService.initialize();
  } catch (e) {
    AppLogger.warn('[Main] FCM init error: $e');
  }

  // Cấu hình locale tiếng Việt cho timeago
  timeago.setLocaleMessages('vi', timeago.ViMessages());

  runApp(const SocialMockApp());
}

/// Root widget của ứng dụng
/// Cấu hình providers, theme và routes
class SocialMockApp extends StatelessWidget {
  const SocialMockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider xác thực
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Provider quản lý bài viết
        ChangeNotifierProvider(create: (_) => PostProvider()),
        // Provider quản lý thông tin user
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // Provider quản lý thông báo
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        // Provider quản lý follow (cần UserProvider để reload data)
        ChangeNotifierProxyProvider<UserProvider, FollowProvider>(
          create: (_) => FollowProvider(),
          update: (_, userProvider, followProvider) {
            followProvider?.setUserProvider(userProvider);
            return followProvider ?? FollowProvider()..setUserProvider(userProvider);
          },
        ),
      ],
      child: MaterialApp(
        title: 'Mạng xã hội',
        theme: _buildTheme(),
        home: const AuthWrapper(),
        routes: {
          LoginScreen.routeName: (context) => const LoginScreen(),
          RegisterScreen.routeName: (context) => const RegisterScreen(),
          ForgotPasswordScreen.routeName: (context) => const ForgotPasswordScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  // Cấu hình theme cho ứng dụng
  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.deepPurple,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(elevation: 0.5),

      // Theme cho TextField
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF667eea), width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
      ),

      // Theme cho ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Theme cho OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: Colors.grey[300]!),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Theme cho TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

/// Widget wrapper xử lý trạng thái đăng nhập
/// Sử dụng Selector để chỉ rebuild khi isAuthenticated thay đổi
/// Tránh rebuild LoginScreen khi đăng nhập thất bại
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AuthProvider, ({bool isAuthenticated, UserModel? userModel})>(
      selector: (_, auth) => (isAuthenticated: auth.isAuthenticated, userModel: auth.userModel),
      builder: (context, authState, _) {
        // Đã đăng nhập - kiểm tra role và chuyển hướng
        if (authState.isAuthenticated) {
          final currentUser = authState.userModel;

          // Đang tải dữ liệu user từ Firestore
          if (currentUser == null) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // Admin -> Dashboard
          if (currentUser.role == 'admin') {
            return const AdminDashboardScreen();
          }

          // User thường -> Khởi tạo streams và về Home
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final authProvider = context.read<AuthProvider>();
            context.read<PostProvider>().initializePostStream();

            if (authProvider.firebaseUser != null) {
              final uid = authProvider.firebaseUser!.uid;
              // Tải dữ liệu user
              context.read<UserProvider>().loadUser(uid);
              // Khởi tạo stream thông báo
              context.read<NotificationProvider>().initializeNotificationStream(uid);
              // Tải cache bài viết đã lưu
              context.read<PostProvider>().loadSavedPostIds(uid);
              // Lưu FCM token cho push notifications
              FCMService.saveTokenForUser(uid);
            }
          });

          return const HomeScreen();
        }

        // Chưa đăng nhập -> Login
        return const LoginScreen();
      },
    );
  }
}

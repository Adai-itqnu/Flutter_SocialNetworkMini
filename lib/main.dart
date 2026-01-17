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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (optional - won't crash if missing)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    AppLogger.warn('[Main] .env load error: $e');
  }

  // Initialize Firebase (handle if already initialized)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    AppLogger.warn(
      '[Main] Firebase init error (may already be initialized): $e',
    );
  }

  // FCM initialization
  try {
    FCMService.initialize();
  } catch (e) {
    AppLogger.warn('[Main] FCM init error: $e');
  }

  // Initialize common locales
  timeago.setLocaleMessages('vi', timeago.ViMessages());

  runApp(const SocialMockApp());
}

class SocialMockApp extends StatelessWidget {
  const SocialMockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
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
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(elevation: 0.5),

          // Input Decoration Theme
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),

          // Elevated Button Theme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Outlined Button Theme
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey[300]!),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Text Button Theme
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          LoginScreen.routeName: (context) => const LoginScreen(),
          RegisterScreen.routeName: (context) => const RegisterScreen(),
          ForgotPasswordScreen.routeName: (context) =>
              const ForgotPasswordScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// AuthWrapper handles auth state changes using Selector
/// This only rebuilds when isAuthenticated changes, NOT when isLoading changes
/// Prevents LoginScreen from rebuilding on failed login attempts
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Selector to only rebuild when these specific values change
    return Selector<AuthProvider, ({bool isAuthenticated, UserModel? userModel})>(
      selector: (_, auth) => (
        isAuthenticated: auth.isAuthenticated,
        userModel: auth.userModel,
      ),
      builder: (context, authState, _) {
        // If authenticated, check role and redirect
        if (authState.isAuthenticated) {
          final currentUser = authState.userModel;

          // Still loading user data from Firestore
          if (currentUser == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Check if admin
          if (currentUser.role == 'admin') {
            return const AdminDashboardScreen();
          }

          // Regular user: Initialize streams
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final authProvider = context.read<AuthProvider>();
            context.read<PostProvider>().initializePostStream();
            if (authProvider.firebaseUser != null) {
              final uid = authProvider.firebaseUser!.uid;
              context.read<UserProvider>().loadUser(uid);
              context
                  .read<NotificationProvider>()
                  .initializeNotificationStream(uid);
              
              // Load saved posts cache for performance
              context.read<PostProvider>().loadSavedPostIds(uid);

              // Save FCM token for user
              FCMService.saveTokenForUser(uid);
            }
          });

          return const HomeScreen();
        }

        // Not authenticated - show Login
        // This won't rebuild during login attempts because isAuthenticated stays false
        return const LoginScreen();
      },
    );
  }
}


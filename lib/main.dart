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
import 'package:timeago/timeago.dart' as timeago;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase with options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
        ChangeNotifierProvider(create: (_) => FollowProvider()),
      ],
      child: MaterialApp(
        title: 'Mạng xã hội',
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(elevation: 0.5),
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // Show loading while checking auth state
            if (authProvider.firebaseUser == null && authProvider.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // If authenticated, go to Home
            if (authProvider.isAuthenticated) {
              // Initialize streams when logged in
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<PostProvider>().initializePostStream();
                if (authProvider.firebaseUser != null) {
                  final uid = authProvider.firebaseUser!.uid;
                  context.read<UserProvider>().loadUser(uid);
                  context.read<NotificationProvider>().initializeNotificationStream(uid);
                }
              });
              return const HomeScreen();
            }

            // Otherwise, show Login
            return const LoginScreen();
          },
        ),
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

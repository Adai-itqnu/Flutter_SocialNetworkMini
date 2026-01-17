import 'package:flutter/material.dart';

/// Widget scaffold cho các màn hình xác thực (đăng nhập, đăng ký, quên mật khẩu)
/// Có animation fade/slide và thiết kế gradient đen
class AuthScaffold extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget form;

  const AuthScaffold({super.key, required this.title, required this.subtitle, required this.form});

  @override
  State<AuthScaffold> createState() => _AuthScaffoldState();
}

class _AuthScaffoldState extends State<AuthScaffold> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Gradient background đen
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a1a), Color(0xFF000000), Color(0xFF2d2d2d)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: size.width > 600 ? 480 : double.infinity),
                    // Card trắng chứa form
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40, offset: const Offset(0, 20), spreadRadius: 5)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withOpacity(0.98), Colors.white.withOpacity(0.95)])),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              // Logo
                              Center(
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: const Color(0xFF667eea).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]),
                                  child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.asset('assets/images/logo.png', fit: BoxFit.cover)),
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Tiêu đề
                              Text(widget.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1f2937), letterSpacing: -0.5), textAlign: TextAlign.center),
                              const SizedBox(height: 8),
                              // Mô tả
                              Text(widget.subtitle, style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5), textAlign: TextAlign.center),
                              const SizedBox(height: 40),
                              // Form
                              widget.form,
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

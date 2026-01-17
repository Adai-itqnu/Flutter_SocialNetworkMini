import 'package:flutter/material.dart';

/// Nút gradient tím đẹp
/// Có hỗ trợ loading state và disabled state
class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;

  const GradientButton({super.key, required this.onPressed, required this.child, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Gradient tím khi enabled, xám khi disabled
        gradient: LinearGradient(
          colors: onPressed == null ? [Colors.grey[400]!, Colors.grey[400]!] : const [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        // Shadow khi enabled
        boxShadow: onPressed != null ? [BoxShadow(color: const Color(0xFF667eea).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                : DefaultTextStyle(style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600), child: child),
          ),
        ),
      ),
    );
  }
}

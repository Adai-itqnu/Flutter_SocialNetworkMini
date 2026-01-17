import 'package:flutter/material.dart';

/// Widget label cho text field
/// Hiển thị tiêu đề trên ô input
class TextFieldLabel extends StatelessWidget {
  final String text;

  const TextFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500, color: Colors.grey[800])),
    );
  }
}

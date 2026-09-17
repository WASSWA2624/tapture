import 'package:flutter/material.dart';

/// A screen that paints itself instead of reading tokens.
class CaptureScreen extends StatelessWidget {
  const CaptureScreen({super.key});

  static const Duration _flash = Duration(milliseconds: 120);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: _flash,
      opacity: 1,
      child: Container(
        color: const Color(0xFF1A5F4A),
        padding: const EdgeInsets.all(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('capture', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}

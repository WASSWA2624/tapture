import 'package:flutter/material.dart';

/// A catalogue control; setState is legal here (FE-STATE-01).
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child});

  final Widget child;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      child: Opacity(opacity: _down ? 0.7 : 1, child: widget.child),
    );
  }
}

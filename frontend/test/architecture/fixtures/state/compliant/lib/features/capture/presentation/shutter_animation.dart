import 'package:flutter/material.dart';

/// Animation code may call setState (FE-STATE-01).
class ShutterAnimation extends StatefulWidget {
  const ShutterAnimation({super.key});

  @override
  State<ShutterAnimation> createState() => _ShutterAnimationState();
}

class _ShutterAnimationState extends State<ShutterAnimation> {
  double _opacity = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _opacity = _opacity == 1 ? 0.4 : 1),
      child: Opacity(opacity: _opacity, child: const SizedBox.shrink()),
    );
  }
}

import 'package:flutter/material.dart';

/// A screen that picks its own glyphs instead of naming a concept.
class CaptureScreen extends StatelessWidget {
  /// Creates the fixture screen.
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[Icon(Icons.fiber_manual_record), Icon(Icons.output)],
    );
  }
}

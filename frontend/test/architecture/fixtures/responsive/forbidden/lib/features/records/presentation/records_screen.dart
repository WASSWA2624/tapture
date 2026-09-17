import 'package:flutter/material.dart';

/// A screen that measures the window and hardcodes a tablet width.
class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.sizeOf(context).width > 600;
    return SizedBox(width: 1100, child: Text(wide ? 'list' : 'stack'));
  }
}

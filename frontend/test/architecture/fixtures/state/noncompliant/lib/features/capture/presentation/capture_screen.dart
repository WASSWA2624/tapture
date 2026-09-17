import 'package:flutter/material.dart';

/// The persistence port a screen must not call.
class CaptureRepository {
  void save() {}
}

/// A screen that measures itself and writes through the repository.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final CaptureRepository repository = CaptureRepository();
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        setState(() => _count++);
        repository.save();
      },
      child: Text('$_count'),
    );
  }
}

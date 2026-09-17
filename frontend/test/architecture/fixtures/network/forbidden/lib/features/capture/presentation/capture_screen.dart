import 'dart:io';

import 'package:flutter/material.dart';

/// A screen that opens a socket instead of calling a core client.
class CaptureScreen extends StatelessWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HttpClient client = HttpClient();
    return Text('${client.autoUncompress}');
  }
}

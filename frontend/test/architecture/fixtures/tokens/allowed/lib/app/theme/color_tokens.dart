import 'package:flutter/material.dart';

/// Literals belong in the token files, not in features (FE-THEME-01).
abstract final class ColorTokens {
  static const Color primary = Color(0xFF1A5F4A);
  static const Color danger = Colors.red;
  static const EdgeInsets pad = EdgeInsets.all(12);
  static final BorderRadius corner = BorderRadius.circular(8);
  static const Duration snap = Duration(milliseconds: 120);
  static const TextStyle body = TextStyle(fontSize: 16);
}

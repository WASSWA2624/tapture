import 'package:flutter/material.dart';

/// The only place 600 and 1024 exist (FE-RESP-01).
enum SizeClass { compact, medium, expanded }

/// Resolves [SizeClass] from the window width.
SizeClass sizeClassOf(BuildContext context) {
  final double width = MediaQuery.sizeOf(context).width;
  if (width < 600) {
    return SizeClass.compact;
  }
  if (width < 1024) {
    return SizeClass.medium;
  }
  return SizeClass.expanded;
}

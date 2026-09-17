import 'package:flutter/material.dart';

/// The type this file is named for (FE-STR-06). The contract name is
/// [AppText].
typedef Typography = AppText;

/// Type roles sized for reading at arm's length in sunlight.
///
/// Metrics are identical in light, dark and outdoor (FE-THEME-03). Colour
/// comes from [AppColors] at the call site, never from a one-mode default
/// baked into the style (FE-THEME-02).
abstract final class AppText {
  /// Screen or hero heading.
  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.4,
  );

  /// Page title.
  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.2,
  );

  /// Group heading inside a list or form.
  static const TextStyle section = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// Running text.
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Running text that carries emphasis.
  static const TextStyle bodyStrong = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Control labels and chip text.
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  /// Helper, timestamp and secondary copy.
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  /// Identifiers, codes and verbatim values.
  static const TextStyle mono = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    fontFamily: 'monospace',
    letterSpacing: 0.2,
  );
}

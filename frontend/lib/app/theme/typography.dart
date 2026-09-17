import 'package:flutter/material.dart';

/// The type this file is named for (FE-STR-06). The contract name is
/// [AppText].
typedef Typography = AppText;

/// Type roles sized like a messaging client: platform UI fonts, compact
/// headers, readable list rows.
///
/// Metrics are identical in light, dark and outdoor (FE-THEME-03). Colour
/// comes from [AppColors] at the call site, never from a one-mode default
/// baked into the style (FE-THEME-02).
abstract final class AppText {
  /// System UI stack used by WhatsApp-class clients: Segoe on Windows,
  /// Helvetica Neue on Apple, Roboto on Android, then generic sans.
  static const List<String> fontFallback = <String>[
    'Segoe UI',
    'Helvetica Neue',
    'Helvetica',
    'Roboto',
    'Arial',
    'sans-serif',
  ];

  /// Screen or hero heading.
  static const TextStyle display = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0,
    fontFamilyFallback: fontFallback,
  );

  /// Page and app-bar title.
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.25,
    letterSpacing: 0,
    fontFamilyFallback: fontFallback,
  );

  /// Group heading inside a list or form.
  static const TextStyle section = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0,
    fontFamilyFallback: fontFallback,
  );

  /// Running text and message body.
  static const TextStyle body = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0,
    fontFamilyFallback: fontFallback,
  );

  /// List-row title and emphasised running text.
  static const TextStyle bodyStrong = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0,
    fontFamilyFallback: fontFallback,
  );

  /// Control labels and chip text.
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.25,
    letterSpacing: 0,
    fontFamilyFallback: fontFallback,
  );

  /// Helper, timestamp and secondary copy.
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.25,
    letterSpacing: 0,
    fontFamilyFallback: fontFallback,
  );

  /// Identifiers, codes and verbatim values.
  static const TextStyle mono = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.3,
    fontFamily: 'monospace',
    letterSpacing: 0.2,
    fontFamilyFallback: fontFallback,
  );
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The type this file is named for (FE-STR-06). The contract name is
/// [AppText].
typedef Typography = AppText;

/// Type roles sized like a messaging client: platform UI fonts, compact
/// headers, readable list rows and 12dp timestamps.
///
/// Metrics are identical in light, dark and outdoor (FE-THEME-03). Colour
/// comes from [AppColors] at the call site, never from a one-mode default
/// baked into the style (FE-THEME-02).
abstract final class AppText {
  /// System UI stack used by WhatsApp-class clients. Web keeps Roboto
  /// because CanvasKit cannot load OS-installed faces.
  static const List<String> fontFallback = <String>[
    'Roboto',
    'Segoe UI',
    'Helvetica Neue',
    'Helvetica',
    'Arial',
  ];

  /// First-choice UI face for the running platform. Goldens pin Ahem on
  /// [ThemeData] instead of this name.
  static String get uiFamily {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => 'Helvetica Neue',
      TargetPlatform.windows => 'Segoe UI',
      TargetPlatform.linux => 'Ubuntu',
      TargetPlatform.android || TargetPlatform.fuchsia => 'Roboto',
    };
  }

  /// [ThemeData.fontFamily] for the running app. Tests and web keep the
  /// engine default so glyphs (including space) always resolve; CanvasKit
  /// cannot load an OS-installed face by family name.
  static String? get themeFamily {
    if (const bool.fromEnvironment('FLUTTER_TEST') || kIsWeb) {
      return null;
    }
    return uiFamily;
  }

  /// Native-only fallback list. CanvasKit cannot load OS faces, so web
  /// and tests omit this and stay on the bundled Roboto / Ahem.
  static List<String>? get themeFallback {
    if (const bool.fromEnvironment('FLUTTER_TEST') || kIsWeb) {
      return null;
    }
    return fontFallback;
  }

  /// Screen or hero heading.
  static const TextStyle display = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  /// Page and app-bar title.
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.25,
  );

  /// Group heading inside a list or form.
  static const TextStyle section = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// Running text and message body.
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  /// List-row title and emphasised running text.
  static const TextStyle bodyStrong = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  /// Control labels and chip text.
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.25,
  );

  /// Helper, timestamp and secondary copy.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  /// Identifiers, codes and verbatim values.
  static const TextStyle mono = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.3,
    fontFamily: 'monospace',
    letterSpacing: 0.2,
  );
}

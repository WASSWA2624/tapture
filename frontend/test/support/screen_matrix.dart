import 'package:flutter/material.dart';

/// The three size classes, both orientations, two scales and all themes.
final class ScreenMatrix {
  const ScreenMatrix(this.size, this.textScale, this.brightness, this.outdoor);

  final Size size;
  final double textScale;
  final Brightness brightness;
  final bool outdoor;

  /// Named visual corners include each width, a short viewport and large text.
  static Iterable<({String name, ScreenMatrix cell})> get corners sync* {
    for (final ({String name, Size size, double scale}) corner
        in <({String name, Size size, double scale})>[
          (name: 'compact', size: const Size(393, 852), scale: 1),
          (
            name: 'compact_landscape_text2',
            size: const Size(393, 320),
            scale: 2,
          ),
          (name: 'medium', size: const Size(800, 1280), scale: 1),
          (name: 'expanded_text2', size: const Size(1200, 800), scale: 2),
        ]) {
      for (final (String, Brightness, bool) theme
          in <(String, Brightness, bool)>[
            ('light', Brightness.light, false),
            ('dark', Brightness.dark, false),
            ('outdoor', Brightness.light, true),
          ]) {
        yield (
          name: '${corner.name}_${theme.$1}',
          cell: ScreenMatrix(corner.size, corner.scale, theme.$2, theme.$3),
        );
      }
    }
  }

  String get description =>
      '${size.width}x${size.height} '
      '${textScale}x ${outdoor ? 'outdoor' : brightness.name}';

  /// Representative layout corners beyond the compact portrait baselines.
  String? get goldenCorner => switch ((size.width, size.height, textScale)) {
    (393, 320, 2) => 'compact_landscape_text2',
    (800, 1280, 1) => 'medium_portrait',
    (1200, 800, 2) => 'expanded_landscape_text2',
    _ => null,
  };

  static Iterable<ScreenMatrix> get cells sync* {
    for (final double width in <double>[393, 800, 1200]) {
      for (final bool landscape in <bool>[false, true]) {
        for (final double scale in <double>[1, 2]) {
          for (final (Brightness, bool) theme in <(Brightness, bool)>[
            (Brightness.light, false),
            (Brightness.dark, false),
            (Brightness.light, true),
          ]) {
            // Landscape retains the tested size-class width. Swapping axes
            // would silently omit compact landscape and expanded portrait.
            final double portraitHeight = switch (width) {
              393 => 852,
              800 => 1280,
              _ => 1600,
            };
            final double landscapeHeight = switch (width) {
              393 => 320,
              800 => 600,
              _ => 800,
            };
            yield ScreenMatrix(
              Size(width, landscape ? landscapeHeight : portraitHeight),
              scale,
              theme.$1,
              theme.$2,
            );
          }
        }
      }
    }
  }
}

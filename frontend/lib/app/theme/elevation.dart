import 'package:flutter/material.dart';

import 'color_tokens.dart';
import 'dimensions.dart';

/// Surface depth as tone plus outline, never shadow (FE-THEME-06).
///
/// Outdoor keeps the same radius and padding and only thickens the stroke
/// (FE-THEME-03).
abstract final class Elevation {
  /// Decoration for a surface at [level] 0 (page) through 3 (dialog).
  static BoxDecoration surface(BuildContext context, {int level = 0}) {
    final AppColors colors = context.colors;
    final int rung = level < 0
        ? 0
        : level > 3
        ? 3
        : level;
    return BoxDecoration(
      color: _tone(colors, rung),
      borderRadius: BorderRadius.circular(Radii.md),
      border: Border.all(color: colors.outline, width: _width(colors, rung)),
    );
  }

  static Color _tone(AppColors colors, int level) {
    return switch (level) {
      0 => colors.background,
      1 => colors.surface,
      _ =>
        _isOutdoor(colors) || colors.background.computeLuminance() >= 0.5
            ? colors.surface
            : colors.surfaceVariant,
    };
  }

  static double _width(AppColors colors, int level) {
    if (_isOutdoor(colors)) {
      return Space.x0 + level;
    }
    return level >= 2 ? Space.x0 : Space.x0 / 2;
  }

  /// Outdoor drops tints, so every surface tone matches the page.
  static bool _isOutdoor(AppColors colors) {
    return colors.surface == colors.background &&
        colors.surfaceVariant == colors.background;
  }
}

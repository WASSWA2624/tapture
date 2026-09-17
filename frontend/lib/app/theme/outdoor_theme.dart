import 'package:flutter/material.dart';

import 'app_theme.dart';

/// The type this file is named for (FE-STR-06). The contract name is
/// [ThemeData] from [buildOutdoorTheme].
typedef OutdoorTheme = ThemeData;

/// High-contrast outdoor [ThemeData] for [brightness] (FE-THEME-03).
///
/// Contrast and outline weight change; padding, radius and control size do
/// not.
ThemeData buildOutdoorTheme(Brightness brightness) {
  return buildTheme(brightness: brightness, outdoor: true);
}

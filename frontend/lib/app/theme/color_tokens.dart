import 'package:flutter/material.dart';

/// The type this file is named for (FE-STR-06). The contract name is
/// [AppColors].
typedef ColorTokens = AppColors;

/// Semantic colours for light, dark and outdoor (FE-THEME-02, FE-THEME-04).
///
/// Widgets read these through [AppColorsX.colors], so changing the active
/// mode restyles every screen with no per-widget work. Values come from the
/// brand ramp where they still clear contrast; interactive outlines are
/// measured rather than taken from a tint that fails 3:1 (FE-THEME-10).
@immutable
final class AppColors extends ThemeExtension<AppColors> {
  /// Creates a complete palette. Every role must be set; a missing role
  /// ships as an invisible control (FE-THEME-02).
  const AppColors({
    required this.surface,
    required this.surfaceVariant,
    required this.background,
    required this.onSurface,
    required this.outline,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.danger,
    required this.warning,
    required this.success,
    required this.info,
    required this.confidenceHigh,
    required this.confidenceMedium,
    required this.confidenceLow,
  });

  /// Raised content: cards, sheets, fields.
  final Color surface;

  /// Recessed fills: grouped rows, input wells.
  final Color surfaceVariant;

  /// The page behind [surface].
  final Color background;

  /// Body text and icons sitting on [surface], [surfaceVariant] or
  /// [background].
  ///
  /// The published contract listed no text-on-surface role; 4.5:1 body
  /// contrast (FE-THEME-10) still needs one, so it lives here rather than as
  /// a one-off in a screen (FE-THEME-11).
  final Color onSurface;

  /// Dividers and control bounds. Never the only state signal
  /// (FE-THEME-05).
  final Color outline;

  /// The brand action colour.
  final Color primary;

  /// Text and icons on [primary].
  final Color onPrimary;

  /// Supporting accent, distinct from status.
  final Color secondary;

  /// Destructive or invalid state.
  final Color danger;

  /// Needs attention, not yet invalid.
  final Color warning;

  /// Completed or verified state.
  final Color success;

  /// Neutral information, not a verdict.
  final Color info;

  /// Extraction or match confidence at or above the high band.
  final Color confidenceHigh;

  /// Extraction or match confidence between the medium and high bands.
  final Color confidenceMedium;

  /// Extraction or match confidence below the medium band.
  final Color confidenceLow;

  /// Daylight palette: white lists on a chat-wallpaper page, header teal.
  static const AppColors light = AppColors(
    surface: _white,
    surfaceVariant: _chromeLight,
    background: _pageLight,
    onSurface: _inkLight,
    outline: _outlineLight,
    primary: _headerLight,
    onPrimary: _white,
    secondary: _accentLight,
    danger: _dangerLight,
    warning: _warningLight,
    success: _successLight,
    info: _infoLight,
    confidenceHigh: _successLight,
    confidenceMedium: _warningLight,
    confidenceLow: _dangerLight,
  );

  /// Dim palette: charcoal panels, bright accent, lighter status.
  static const AppColors dark = AppColors(
    surface: _panelDark,
    surfaceVariant: _wellDark,
    background: _pageDark,
    onSurface: _inkDark,
    outline: _outlineDark,
    primary: _accentDark,
    onPrimary: _pageDark,
    secondary: _accentDarkSoft,
    danger: _dangerDark,
    warning: _warningDark,
    success: _successDark,
    info: _infoDark,
    confidenceHigh: _successDark,
    confidenceMedium: _warningDark,
    confidenceLow: _dangerDark,
  );

  /// Sunlight palette: no surface tints, near-black ink, heavier contrast.
  ///
  /// Geometry is unchanged; only tone and outline weight move
  /// (FE-THEME-03).
  static const AppColors outdoor = AppColors(
    surface: _white,
    surfaceVariant: _white,
    background: _white,
    onSurface: _black,
    outline: _black,
    primary: _headerLight,
    onPrimary: _white,
    secondary: _accentOutdoor,
    danger: _dangerOutdoor,
    warning: _warningOutdoor,
    success: _successOutdoor,
    info: _infoOutdoor,
    confidenceHigh: _successOutdoor,
    confidenceMedium: _warningOutdoor,
    confidenceLow: _dangerOutdoor,
  );

  @override
  AppColors copyWith({
    Color? surface,
    Color? surfaceVariant,
    Color? background,
    Color? onSurface,
    Color? outline,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? danger,
    Color? warning,
    Color? success,
    Color? info,
    Color? confidenceHigh,
    Color? confidenceMedium,
    Color? confidenceLow,
  }) {
    return AppColors(
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      background: background ?? this.background,
      onSurface: onSurface ?? this.onSurface,
      outline: outline ?? this.outline,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      success: success ?? this.success,
      info: info ?? this.info,
      confidenceHigh: confidenceHigh ?? this.confidenceHigh,
      confidenceMedium: confidenceMedium ?? this.confidenceMedium,
      confidenceLow: confidenceLow ?? this.confidenceLow,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      background: Color.lerp(background, other.background, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
      info: Color.lerp(info, other.info, t)!,
      confidenceHigh: Color.lerp(confidenceHigh, other.confidenceHigh, t)!,
      confidenceMedium: Color.lerp(
        confidenceMedium,
        other.confidenceMedium,
        t,
      )!,
      confidenceLow: Color.lerp(confidenceLow, other.confidenceLow, t)!,
    );
  }
}

/// Resolves [AppColors] from [BuildContext].
extension AppColorsX on BuildContext {
  /// The palette of the active mode. Falls back to light or dark from
  /// [ThemeData.brightness] when a tree has not installed the extension.
  AppColors get colors {
    return Theme.of(this).extension<AppColors>() ??
        (Theme.of(this).brightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light);
  }
}

// Messaging-client chrome. Public tokens stay semantic (FE-THEME-04);
// these names are the private source of the hex values.
const Color _white = Color(0xFFFFFFFF);
const Color _black = Color(0xFF000000);

/// Classic header teal; holds 4.5:1 as ink and as a fill for white.
const Color _headerLight = Color(0xFF075E54);

/// Supporting teal, darker than [ _headerLight ] so the two stay distinct.
const Color _accentLight = Color(0xFF0A5C4E);

/// High-contrast outdoor supporting ink.
const Color _accentOutdoor = Color(0xFF042F28);

/// Bright accent used as dark-mode ink and selected chrome.
const Color _accentDark = Color(0xFF00A884);

/// Softer mint for dark-mode supporting ink.
const Color _accentDarkSoft = Color(0xFF8FE3C8);

/// Chat-wallpaper page, list chrome, and ink.
const Color _pageLight = Color(0xFFEFEAE2);
const Color _chromeLight = Color(0xFFF0F2F5);
const Color _inkLight = Color(0xFF111B21);
const Color _pageDark = Color(0xFF0B141A);
const Color _panelDark = Color(0xFF111B21);
const Color _wellDark = Color(0xFF202C33);
const Color _inkDark = Color(0xFFE9EDEF);

/// Interactive outline on light surfaces; also the secondary-text grey.
const Color _outlineLight = Color(0xFF54656F);

/// Interactive outline on dark surfaces; still clears 3:1 on the well.
const Color _outlineDark = Color(0xFF8696A0);

const Color _dangerLight = Color(0xFFB42318);
const Color _warningLight = Color(0xFF93370D);
const Color _successLight = Color(0xFF05603A);
const Color _infoLight = Color(0xFF026AA2);

const Color _dangerDark = Color(0xFFFDA29B);
const Color _warningDark = Color(0xFFFDB022);
const Color _successDark = Color(0xFF6CE9A6);
const Color _infoDark = Color(0xFF7CD4FD);

const Color _dangerOutdoor = Color(0xFF7A271A);
const Color _warningOutdoor = Color(0xFF7A2E0E);
const Color _successOutdoor = Color(0xFF054F31);
const Color _infoOutdoor = Color(0xFF0B4A6F);

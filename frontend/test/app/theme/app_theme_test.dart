import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';

void main() {
  test('light, dark and outdoor ColorSchemes use the token roles', () {
    final ThemeData light = buildTheme(brightness: Brightness.light);
    final ThemeData dark = buildTheme(brightness: Brightness.dark);
    final ThemeData outdoor = buildOutdoorTheme(Brightness.light);

    expect(identical(light.extension<AppColors>(), AppColors.light), isTrue);
    expect(identical(dark.extension<AppColors>(), AppColors.dark), isTrue);
    expect(
      identical(outdoor.extension<AppColors>(), AppColors.outdoor),
      isTrue,
    );
    expect(light.colorScheme.primary, AppColors.light.primary);
    expect(dark.colorScheme.surface, AppColors.dark.surface);
    expect(outdoor.colorScheme.outline, AppColors.outdoor.outline);
    expect(light.useMaterial3, isTrue);
  });

  test('outdoor dark flattens surface tints rather than dropping roles', () {
    final ThemeData outdoorDark = buildOutdoorTheme(Brightness.dark);
    final AppColors colors = outdoorDark.extension<AppColors>()!;

    expect(colors.surface, colors.background);
    expect(colors.surfaceVariant, colors.background);
    expect(colors.primary, AppColors.dark.primary);
  });

  test('outdoor keeps the same padding, radius and control size as light', () {
    final ThemeData light = buildTheme(brightness: Brightness.light);
    final ThemeData outdoor = buildOutdoorTheme(Brightness.light);

    expect(
      light.inputDecorationTheme.contentPadding,
      outdoor.inputDecorationTheme.contentPadding,
    );
    expect(
      _minimumSize(light.filledButtonTheme.style),
      _minimumSize(outdoor.filledButtonTheme.style),
    );
    expect(
      _minimumSize(light.outlinedButtonTheme.style),
      _minimumSize(outdoor.outlinedButtonTheme.style),
    );
    expect(_radius(light.cardTheme.shape), Radii.md);
    expect(_radius(light.cardTheme.shape), _radius(outdoor.cardTheme.shape));
    expect(_radius(light.dialogTheme.shape), Radii.lg);
    expect(
      _radius(light.dialogTheme.shape),
      _radius(outdoor.dialogTheme.shape),
    );
    expect(_styleRadius(light.filledButtonTheme.style), Radii.sm);
    expect(
      _styleRadius(light.filledButtonTheme.style),
      _styleRadius(outdoor.filledButtonTheme.style),
    );
    expect(_styleRadius(light.outlinedButtonTheme.style), Radii.sm);
    expect(_styleRadius(light.textButtonTheme.style), Radii.sm);
    expect(_styleRadius(light.iconButtonTheme.style), Radii.sm);
    expect(
      _sideWidth(outdoor.outlinedButtonTheme.style) >
          _sideWidth(light.outlinedButtonTheme.style),
      isTrue,
    );
    expect(
      _padding(light.filledButtonTheme.style),
      _padding(outdoor.filledButtonTheme.style),
    );
    expect(
      _padding(light.outlinedButtonTheme.style),
      _padding(outdoor.outlinedButtonTheme.style),
    );
    expect(
      _padding(light.textButtonTheme.style),
      _padding(outdoor.textButtonTheme.style),
    );
  });

  test('labelled buttons use Space.x4 between the label and each side', () {
    const EdgeInsetsGeometry expected = EdgeInsets.symmetric(
      horizontal: Space.x4,
      vertical: Space.x0,
    );
    for (final ThemeData theme in <ThemeData>[
      buildTheme(brightness: Brightness.light),
      buildTheme(brightness: Brightness.dark),
      buildOutdoorTheme(Brightness.light),
    ]) {
      expect(_padding(theme.filledButtonTheme.style), expected);
      expect(_padding(theme.outlinedButtonTheme.style), expected);
      expect(_padding(theme.textButtonTheme.style), expected);
    }
  });

  test(
    'hint and resting labels use muted ink; floating and typed stay onSurface',
    () {
      for (final ThemeData theme in <ThemeData>[
        buildTheme(brightness: Brightness.light),
        buildTheme(brightness: Brightness.dark),
        buildOutdoorTheme(Brightness.light),
      ]) {
        final AppColors colors = theme.extension<AppColors>()!;
        expect(
          theme.inputDecorationTheme.hintStyle?.color,
          colors.onSurfaceMuted,
        );
        expect(
          theme.inputDecorationTheme.labelStyle?.color,
          colors.onSurfaceMuted,
        );
        expect(
          theme.inputDecorationTheme.floatingLabelStyle?.color,
          colors.onSurface,
        );
        expect(theme.textTheme.bodyLarge?.color, colors.onSurface);
      }
    },
  );
}

Size? _minimumSize(ButtonStyle? style) {
  return style?.minimumSize?.resolve(<WidgetState>{});
}

double _radius(ShapeBorder? shape) {
  if (shape is RoundedRectangleBorder) {
    return shape.borderRadius.resolve(TextDirection.ltr).topLeft.x;
  }
  return 0;
}

double _styleRadius(ButtonStyle? style) {
  return _radius(style?.shape?.resolve(const <WidgetState>{}));
}

double _sideWidth(ButtonStyle? style) {
  return style?.side?.resolve(<WidgetState>{})?.width ?? 0;
}

EdgeInsetsGeometry? _padding(ButtonStyle? style) {
  return style?.padding?.resolve(const <WidgetState>{});
}

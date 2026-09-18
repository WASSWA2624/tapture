import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/color_tokens.dart';

import 'token_harness.dart';

void main() {
  test('colour roles are the same set in light, dark and outdoor', () {
    expect(_roles(AppColors.light).keys, _roles(AppColors.dark).keys);
    expect(_roles(AppColors.light).keys, _roles(AppColors.outdoor).keys);
  });

  test('outdoor drops surface tints rather than dropping roles', () {
    expect(AppColors.outdoor.surface, AppColors.outdoor.background);
    expect(AppColors.outdoor.surfaceVariant, AppColors.outdoor.background);
  });

  test('body text meets 4.5:1 on every surface in every mode', () {
    for (final AppColors colors in tokenModes) {
      for (final Color ground in _surfaces(colors)) {
        expect(
          _contrast(colors.onSurface, ground),
          greaterThanOrEqualTo(4.5),
          reason: '${tokenModeName(colors)} onSurface on $ground',
        );
      }
    }
  });

  test('muted text meets 4.5:1 on every surface in every mode', () {
    for (final AppColors colors in tokenModes) {
      for (final Color ground in _surfaces(colors)) {
        expect(
          _contrast(colors.onSurfaceMuted, ground),
          greaterThanOrEqualTo(4.5),
          reason: '${tokenModeName(colors)} onSurfaceMuted on $ground',
        );
      }
    }
  });

  test('onPrimary meets 4.5:1 on primary in every mode', () {
    for (final AppColors colors in tokenModes) {
      expect(
        _contrast(colors.onPrimary, colors.primary),
        greaterThanOrEqualTo(4.5),
        reason: tokenModeName(colors),
      );
    }
  });

  test('interactive outlines meet 3:1 on every surface in every mode', () {
    for (final AppColors colors in tokenModes) {
      for (final Color ground in _surfaces(colors)) {
        expect(
          _contrast(colors.outline, ground),
          greaterThanOrEqualTo(3),
          reason: '${tokenModeName(colors)} outline on $ground',
        );
      }
    }
  });

  test('status, accent and confidence text meet 4.5:1 in every mode', () {
    for (final AppColors colors in tokenModes) {
      final List<Color> inks = <Color>[
        colors.primary,
        colors.secondary,
        colors.danger,
        colors.warning,
        colors.success,
        colors.info,
        colors.confidenceHigh,
        colors.confidenceMedium,
        colors.confidenceLow,
      ];
      for (final Color ink in inks) {
        for (final Color ground in _surfaces(colors)) {
          expect(
            _contrast(ink, ground),
            greaterThanOrEqualTo(4.5),
            reason: '${tokenModeName(colors)} $ink on $ground',
          );
        }
      }
    }
  });

  testWidgets('changing the active mode restyles through context.colors', (
    WidgetTester tester,
  ) async {
    Color? latest;
    await pumpTokenTree(
      tester,
      colors: AppColors.light,
      child: Builder(
        builder: (BuildContext context) {
          latest = context.colors.primary;
          return const SizedBox.shrink();
        },
      ),
    );
    final Color lightPrimary = latest!;

    await pumpTokenTree(
      tester,
      colors: AppColors.dark,
      child: Builder(
        builder: (BuildContext context) {
          latest = context.colors.primary;
          return const SizedBox.shrink();
        },
      ),
    );
    expect(latest, AppColors.dark.primary);
    expect(latest, isNot(lightPrimary));
  });

  testWidgets('brightness without an extension still resolves light and dark', (
    WidgetTester tester,
  ) async {
    late AppColors resolved;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
        home: Builder(
          builder: (BuildContext context) {
            resolved = context.colors;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(resolved.primary, AppColors.dark.primary);
  });
}

Map<String, Color> _roles(AppColors colors) {
  return <String, Color>{
    'surface': colors.surface,
    'surfaceVariant': colors.surfaceVariant,
    'background': colors.background,
    'onSurface': colors.onSurface,
    'onSurfaceMuted': colors.onSurfaceMuted,
    'outline': colors.outline,
    'primary': colors.primary,
    'onPrimary': colors.onPrimary,
    'secondary': colors.secondary,
    'danger': colors.danger,
    'warning': colors.warning,
    'success': colors.success,
    'info': colors.info,
    'confidenceHigh': colors.confidenceHigh,
    'confidenceMedium': colors.confidenceMedium,
    'confidenceLow': colors.confidenceLow,
  };
}

List<Color> _surfaces(AppColors colors) {
  return <Color>[colors.background, colors.surface, colors.surfaceVariant];
}

double _contrast(Color a, Color b) {
  final double left = a.computeLuminance();
  final double right = b.computeLuminance();
  final double lighter = left > right ? left : right;
  final double darker = left > right ? right : left;
  return (lighter + 0.05) / (darker + 0.05);
}

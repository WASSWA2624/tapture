import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/app/theme/theme_controller.dart';

const Size _surface = Size(400, 800);

const List<AppThemeMode> _defaultModes = <AppThemeMode>[
  AppThemeMode.light,
  AppThemeMode.dark,
  AppThemeMode.outdoor,
];

const ValueKey<String> _surfaceKey = ValueKey<String>('golden-surface');

/// Pumps [widget] in each of [modes], waits for the next frame, and compares
/// one PNG per mode under `goldens/`.
///
/// The test font is Ahem and animations are disabled so a baseline is the
/// same on any machine. A mismatch names the widget [name] and the mode
/// that moved.
Future<void> expectGolden(
  WidgetTester tester,
  Widget widget,
  String name, {
  List<AppThemeMode> modes = _defaultModes,
}) async {
  _pinHarness(tester);
  final List<String> failures = <String>[];
  for (final AppThemeMode mode in modes) {
    await _pump(tester, widget, mode);
    try {
      await expectLater(
        find.byKey(_surfaceKey),
        matchesGoldenFile('goldens/${name}_${mode.name}.png'),
      );
    } catch (error) {
      failures.add('$name in ${mode.name}: $error');
    }
  }
  if (failures.isNotEmpty) {
    fail(
      'golden moved:\n${failures.join('\n')} '
      '(FE-TEST-02)',
    );
  }
}

void _pinHarness(WidgetTester tester) {
  debugDisableShadows = true;
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = _surface;
  tester.platformDispatcher.textScaleFactorTestValue = 1;
  tester.platformDispatcher.localeTestValue = const Locale('en', 'US');
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(() {
    debugDisableShadows = false;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.platformDispatcher.clearLocaleTestValue();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget widget,
  AppThemeMode mode,
) async {
  final ThemeData theme = _pinnedTheme(_themeFor(mode));
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: Duration.zero,
      locale: const Locale('en', 'US'),
      theme: theme,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.noScaling,
            size: _surface,
          ),
          child: child!,
        );
      },
      home: RepaintBoundary(
        key: _surfaceKey,
        child: Material(color: theme.scaffoldBackgroundColor, child: widget),
      ),
    ),
  );
  await tester.pump();
}

ThemeData _themeFor(AppThemeMode mode) {
  return switch (mode) {
    AppThemeMode.dark => buildTheme(brightness: Brightness.dark),
    AppThemeMode.outdoor => buildOutdoorTheme(Brightness.light),
    AppThemeMode.light ||
    AppThemeMode.system => buildTheme(brightness: Brightness.light),
  };
}

ThemeData _pinnedTheme(ThemeData theme) {
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamily: 'Ahem'),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Ahem'),
  );
}

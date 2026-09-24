import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/theme_controller.dart';
import 'package:tapture/features/settings/presentation/offline_switch.dart';
import 'package:tapture/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('compact Settings index in every theme and at 200 percent text', (
    WidgetTester tester,
  ) async {
    final List<String> failures = <String>[];
    for (final AppThemeMode mode in AppThemeMode.values) {
      for (final double scale in <double>[1, 2]) {
        await _pump(tester, mode: mode, textScale: scale);
        final String suffix = scale == 2 ? '_text2' : '';
        try {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/settings_index${suffix}_${mode.name}.png',
            ),
          );
        } catch (error) {
          failures.add('${mode.name} scale $scale: $error');
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
    if (failures.isNotEmpty) {
      fail('golden moved:\n${failures.join('\n')} (FE-TEST-02)');
    }
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required AppThemeMode mode,
  required double textScale,
}) async {
  debugDisableShadows = true;
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
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
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      retry: (int _, Object _) => null,
      overrides: <Override>[offlineByChoiceOverride(false)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(
          brightness: mode == AppThemeMode.dark
              ? Brightness.dark
              : Brightness.light,
          outdoor: mode == AppThemeMode.outdoor,
        ),
        home: const SettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

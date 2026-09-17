import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/app/theme/theme_controller.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/gallery/widget_gallery_screen.dart';

import '../../support/a11y_matchers.dart';

void main() {
  group('widget gallery', () {
    for (final ({String name, ThemeData theme, AppThemeMode mode}) mode
        in _modes) {
      testWidgets('index in ${mode.name}', (WidgetTester tester) async {
        await _pumpIndex(tester, theme: mode.theme, mode: mode.mode);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile('goldens/widget_gallery_index_${mode.name}.png'),
        );
      });
    }

    testWidgets('stays usable at 200 percent text scale', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpIndex(
        tester,
        theme: buildTheme(brightness: Brightness.light),
        mode: AppThemeMode.light,
      );
      expect(tester.takeException(), isNull);
      await expectNoA11yIssues(tester);
    });
  });
}

List<({String name, ThemeData theme, AppThemeMode mode})> get _modes {
  return <({String name, ThemeData theme, AppThemeMode mode})>[
    (
      name: 'light',
      theme: buildTheme(brightness: Brightness.light),
      mode: AppThemeMode.light,
    ),
    (
      name: 'dark',
      theme: buildTheme(brightness: Brightness.dark),
      mode: AppThemeMode.dark,
    ),
    (
      name: 'outdoor',
      theme: buildOutdoorTheme(Brightness.light),
      mode: AppThemeMode.outdoor,
    ),
  ];
}

Future<void> _pumpIndex(
  WidgetTester tester, {
  required ThemeData theme,
  required AppThemeMode mode,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: Duration.zero,
      theme: theme,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        );
      },
      home: WidgetGalleryScreen(initialTheme: mode),
    ),
  );
}

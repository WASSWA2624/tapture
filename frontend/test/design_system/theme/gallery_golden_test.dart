import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/app/theme/theme_preview.dart';

import '../../support/a11y_matchers.dart';

void main() {
  group('theme preview', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('gallery in ${mode.name}', (WidgetTester tester) async {
        await _pumpPreview(tester, mode.theme);
        await tester.pump();
        await expectLater(
          find.byType(ThemePreview),
          matchesGoldenFile('goldens/theme_preview_${mode.name}.png'),
        );
        await expectNoA11yIssues(tester);
      });
    }
  });
}

List<({String name, ThemeData theme})> get _modes {
  return <({String name, ThemeData theme})>[
    (name: 'light', theme: buildTheme(brightness: Brightness.light)),
    (name: 'dark', theme: buildTheme(brightness: Brightness.dark)),
    (name: 'outdoor', theme: buildOutdoorTheme(Brightness.light)),
  ];
}

Future<void> _pumpPreview(WidgetTester tester, ThemeData theme) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 900);
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
      home: const ThemePreview(),
    ),
  );
}

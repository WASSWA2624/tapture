import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_page.dart';

void main() {
  group('app icon button, toggle', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('off and on in ${mode.name}', (WidgetTester tester) async {
        await _pumpGallery(tester, mode.theme);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile('goldens/app_icon_button_toggle_${mode.name}.png'),
        );
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

Future<void> _pumpGallery(WidgetTester tester, ThemeData theme) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 200);
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
      home: const AppPage(
        title: 'Toggles',
        body: Wrap(
          spacing: Space.x2,
          children: <Widget>[
            AppIconButton(
              icon: Icons.mic_none,
              semanticLabel: 'Speak',
              tooltip: 'Speak',
              selected: false,
              onPressed: _ignorePress,
            ),
            AppIconButton(
              icon: Icons.mic,
              semanticLabel: 'Stop speaking',
              tooltip: 'Stop speaking',
              selected: true,
              onPressed: _ignorePress,
            ),
          ],
        ),
      ),
    ),
  );
}

void _ignorePress() {}

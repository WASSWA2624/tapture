import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';

void main() {
  group('app switch tile, dense', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('on, off and disabled in ${mode.name}', (
        WidgetTester tester,
      ) async {
        await _pumpGallery(tester, mode.theme);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile('goldens/app_switch_tile_dense_${mode.name}.png'),
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
  tester.view.physicalSize = const Size(400, 300);
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
        title: 'Dense switches',
        body: Column(
          children: <Widget>[
            AppSwitchTile(
              title: 'Attach screenshot',
              description: 'Announced, not drawn',
              value: true,
              dense: true,
              onChanged: _ignore,
            ),
            AppSwitchTile(
              title: 'Off',
              value: false,
              dense: true,
              onChanged: _ignore,
            ),
            AppSwitchTile(
              title: 'Disabled',
              value: true,
              enabled: false,
              dense: true,
              onChanged: _ignore,
            ),
          ],
        ),
      ),
    ),
  );
}

void _ignore(bool _) {}

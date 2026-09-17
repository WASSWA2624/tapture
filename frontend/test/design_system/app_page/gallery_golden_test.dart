import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/widgets/app_page.dart';

import '../../support/a11y_matchers.dart';

void main() {
  group('app page', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      for (final ({String name, Size size}) width in _widths) {
        testWidgets('gallery in ${mode.name} ${width.name}', (
          WidgetTester tester,
        ) async {
          await _pumpGallery(tester, theme: mode.theme, size: width.size);
          await tester.pump();
          await expectLater(
            find.byType(AppPage),
            matchesGoldenFile(
              'goldens/app_page_${mode.name}_${width.name}.png',
            ),
          );
          await expectNoA11yIssues(tester);
        });
      }
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

const List<({String name, Size size})> _widths = <({String name, Size size})>[
  (name: 'compact', size: Size(400, 800)),
  (name: 'medium', size: Size(800, 800)),
  (name: 'expanded', size: Size(1200, 800)),
];

Future<void> _pumpGallery(
  WidgetTester tester, {
  required ThemeData theme,
  required Size size,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
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
        title: 'Records',
        subtitle: 'Today',
        actions: <Widget>[
          IconButton(
            tooltip: 'Search',
            onPressed: _ignorePress,
            icon: Icon(Icons.search),
          ),
        ],
        body: Text('A record list would sit here.'),
        footer: FilledButton(onPressed: _ignorePress, child: Text('Save')),
      ),
    ),
  );
}

void _ignorePress() {}

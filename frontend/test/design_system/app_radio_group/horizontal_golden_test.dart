import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

void main() {
  group('app radio group, horizontal', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('one line and even columns in ${mode.name}', (
        WidgetTester tester,
      ) async {
        await _pumpGallery(tester, mode.theme);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile(
            'goldens/app_radio_group_horizontal_${mode.name}.png',
          ),
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

const List<Choice<String>> _types = <Choice<String>>[
  Choice<String>('g', 'General'),
  Choice<String>('e', 'Error'),
  Choice<String>('s', 'Suggestion'),
  Choice<String>('o', 'Other'),
];

const List<Choice<String>> _grades = <Choice<String>>[
  Choice<String>('a', 'A'),
  Choice<String>('b', 'B'),
  Choice<String>('c', 'C'),
];

Future<void> _pumpGallery(WidgetTester tester, ThemeData theme) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 360);
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
        title: 'Radio groups',
        body: Column(
          children: <Widget>[
            AppRadioGroup<String>(
              label: 'Grade',
              options: _grades,
              value: 'b',
              direction: Axis.horizontal,
              onChanged: _ignore,
            ),
            SizedBox(height: Space.x4),
            AppRadioGroup<String>(
              label: 'Type',
              options: _types,
              value: 'g',
              direction: Axis.horizontal,
              onChanged: _ignore,
            ),
          ],
        ),
      ),
    ),
  );
}

void _ignore(String _) {}

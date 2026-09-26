import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

void main() {
  group('app choice field', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('gallery in ${mode.name}', (WidgetTester tester) async {
        await _pumpGallery(tester, mode.theme);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile('goldens/app_choice_field_${mode.name}.png'),
        );
      });
      testWidgets('no-match sheet in ${mode.name}', (
        WidgetTester tester,
      ) async {
        await _pumpGallery(tester, mode.theme);
        await tester.tap(find.text('Sheet empty'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Zulu');
        await tester.pump();
        await expectLater(
          find.byType(AppBottomSheet),
          matchesGoldenFile(
            'goldens/app_choice_field_no_match_${mode.name}.png',
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

Future<void> _pumpGallery(WidgetTester tester, ThemeData theme) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 920);
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
      home: AppPage(
        title: 'Choice fields',
        body: Column(
          children: <Widget>[
            AppChoiceField<String>(
              label: 'Segmented empty',
              options: _three,
              onChanged: (_) {},
            ),
            const SizedBox(height: Space.x4),
            AppChoiceField<String>(
              label: 'Segmented filled',
              options: _three,
              value: 'b',
              onChanged: (_) {},
            ),
            const SizedBox(height: Space.x4),
            AppChoiceField<String>(
              label: 'Sheet empty',
              options: _five,
              onChanged: (_) {},
            ),
            const SizedBox(height: Space.x4),
            AppChoiceField<String>(
              label: 'Sheet filled',
              options: _five,
              value: 'b',
              onChanged: (_) {},
            ),
            const SizedBox(height: Space.x4),
            AppChoiceField<String>(
              label: 'One option, always a sheet',
              options: _three.take(1).toList(),
              value: 'a',
              alwaysSheet: true,
              onChanged: (_) {},
            ),
            const SizedBox(height: Space.x4),
            AppChoiceField<String>(
              label: 'Disabled',
              options: _three,
              value: 'a',
              enabled: false,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    ),
  );
}

const List<Choice<String>> _three = <Choice<String>>[
  Choice<String>('a', 'Low'),
  Choice<String>('b', 'Med'),
  Choice<String>('c', 'High'),
];

const List<Choice<String>> _five = <Choice<String>>[
  Choice<String>('a', 'Alpha'),
  Choice<String>('b', 'Bravo'),
  Choice<String>('c', 'Charlie'),
  Choice<String>('d', 'Delta'),
  Choice<String>('e', 'Echo'),
];

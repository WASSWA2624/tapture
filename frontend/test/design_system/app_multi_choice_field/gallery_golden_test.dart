import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_multi_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

void main() {
  group('app multi choice field', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('gallery in ${mode.name}', (WidgetTester tester) async {
        await _pumpGallery(tester, mode.theme);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile('goldens/app_multi_choice_field_${mode.name}.png'),
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
  tester.view.physicalSize = const Size(400, 720);
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
        title: 'Multi-choice fields',
        body: Column(
          children: <Widget>[
            AppMultiChoiceField<String>(
              label: 'Empty',
              options: _options,
              value: const <String>{},
              onChanged: (_) {},
            ),
            const SizedBox(height: Space.x4),
            AppMultiChoiceField<String>(
              label: 'Partial',
              options: _options,
              value: const <String>{'a', 'c'},
              onChanged: (_) {},
            ),
            const SizedBox(height: Space.x4),
            AppMultiChoiceField<String>(
              label: 'Full',
              options: _options,
              value: const <String>{'a', 'b', 'c'},
              onChanged: (_) {},
            ),
            const SizedBox(height: Space.x4),
            AppMultiChoiceField<String>(
              label: 'Disabled',
              options: _options,
              value: const <String>{'b'},
              enabled: false,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    ),
  );
}

const List<Choice<String>> _options = <Choice<String>>[
  Choice<String>('a', 'Alpha'),
  Choice<String>('b', 'Bravo'),
  Choice<String>('c', 'Charlie'),
];

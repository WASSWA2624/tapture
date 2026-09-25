import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

void main() {
  group('app radio group, unframed', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('no outline, label in line with the radios, ${mode.name}', (
        WidgetTester tester,
      ) async {
        await _pumpGallery(tester, mode.theme);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile(
            'goldens/app_radio_group_unframed_${mode.name}.png',
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

const List<Choice<String>> _templates = <Choice<String>>[
  Choice<String>('b', 'Building / Facility'),
  Choice<String>('d', 'Document / Archive'),
  Choice<String>('e', 'Equipment / Asset'),
];

Future<void> _pumpGallery(WidgetTester tester, ThemeData theme) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 320);
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
        title: 'Templates',
        body: AppRadioGroup<String>(
          label: 'Templates',
          options: _templates,
          value: 'b',
          framed: false,
          onChanged: (_) {},
        ),
      ),
    ),
  );
}

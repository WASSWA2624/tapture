import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_number_field.dart';

void main() {
  group('app number field', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('gallery in ${mode.name}', (WidgetTester tester) async {
        await _pumpGallery(tester, mode.theme);
        await tester.enterText(find.byType(TextField).at(1), '12');
        await tester.pump();
        await tester.enterText(find.byType(TextField).at(2), '99');
        await tester.pump();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();
        expect(find.text('Out of range'), findsOneWidget);
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile('goldens/app_number_field_${mode.name}.png'),
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
        title: 'Number fields',
        body: Column(
          children: <Widget>[
            AppNumberField(label: 'Empty', onChanged: (_) {}),
            const SizedBox(height: Space.x4),
            AppNumberField(label: 'Filled', unit: 'kg', onChanged: (_) {}),
            const SizedBox(height: Space.x4),
            AppNumberField(label: 'Range', min: 0, max: 10, onChanged: (_) {}),
            const SizedBox(height: Space.x4),
            const AppNumberField(
              label: 'Disabled',
              enabled: false,
              onChanged: _ignore,
            ),
          ],
        ),
      ),
    ),
  );
}

void _ignore(num? _) {}

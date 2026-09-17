import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_date_field.dart';

void main() {
  group('app date field', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('gallery in ${mode.name}', (WidgetTester tester) async {
        await _pumpGallery(tester, mode.theme);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile('goldens/app_date_field_${mode.name}.png'),
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

final FixedClock _clock = FixedClock(DateTime.utc(2026, 9, 17, 8, 15));
final DateTime _stamp = DateTime.utc(2026, 9, 17, 8, 15);

Future<void> _pumpGallery(WidgetTester tester, ThemeData theme) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 820);
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
        title: 'Date fields',
        body: Column(
          children: <Widget>[
            AppDateField(label: 'Empty', clock: _clock, onChanged: (_) {}),
            const SizedBox(height: Space.x4),
            AppDateField(
              label: 'Date',
              mode: DateFieldMode.date,
              value: _stamp,
              clock: _clock,
              onChanged: (_) {},
            ),
            const SizedBox(height: Space.x4),
            AppDateField(
              label: 'Time',
              mode: DateFieldMode.time,
              value: _stamp,
              clock: _clock,
              onChanged: (_) {},
            ),
            const SizedBox(height: Space.x4),
            AppDateField(
              label: 'Date and time',
              mode: DateFieldMode.dateTime,
              value: _stamp,
              clock: _clock,
              onChanged: (_) {},
            ),
            const SizedBox(height: Space.x4),
            AppDateField(
              label: 'Auto-filled',
              value: _stamp,
              autoFilled: true,
              clock: _clock,
              onChanged: (_) {},
            ),
            const SizedBox(height: Space.x4),
            AppDateField(
              label: 'Disabled',
              value: _stamp,
              enabled: false,
              clock: _clock,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    ),
  );
}

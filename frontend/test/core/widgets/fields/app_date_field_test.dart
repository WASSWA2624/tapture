import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/fields/app_date_field.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  final Clock clock = FixedClock(DateTime.utc(2026, 9, 17, 8, 15));
  final DateTime stamp = DateTime.utc(2026, 9, 17, 8, 15);

  testWidgets('a frozen clock formats every DateFieldMode', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AppDateField(
        label: 'When',
        mode: DateFieldMode.date,
        value: stamp,
        clock: clock,
        onChanged: (_) {},
      ),
    );
    expect(find.text('Sep 17, 2026'), findsOneWidget);

    await _pump(
      tester,
      AppDateField(
        label: 'When',
        mode: DateFieldMode.time,
        value: stamp,
        clock: clock,
        onChanged: (_) {},
      ),
    );
    expect(_fieldText(tester), contains('8:15'));

    await _pump(
      tester,
      AppDateField(
        label: 'When',
        mode: DateFieldMode.dateTime,
        value: stamp,
        clock: clock,
        onChanged: (_) {},
      ),
    );
    expect(_fieldText(tester), contains('Sep 17, 2026'));
    expect(_fieldText(tester), contains('8:15'));
    expect(find.byType(AppDateField), meetsTapTarget());
    expect(find.byType(AppDateField), hasSemanticLabel('When'));
  });

  testWidgets('an auto-filled value is named with icon and copy', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AppDateField(
        label: 'When',
        value: stamp,
        autoFilled: true,
        clock: clock,
        onChanged: (_) {},
      ),
    );
    expect(find.text('Auto-filled'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), hasSemanticLabel('Auto-filled'));
  });

  testWidgets('clearing reports null', (WidgetTester tester) async {
    DateTime? latest = stamp;
    await _pump(
      tester,
      AppDateField(
        label: 'When',
        value: stamp,
        clock: clock,
        onChanged: (DateTime? value) => latest = value,
      ),
    );
    await tester.tap(find.byTooltip('Clear When'));
    await tester.pump();
    expect(latest, isNull);
  });

  testWidgets('an empty date field opens the picker on the frozen day', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AppDateField(label: 'When', clock: clock, onChanged: (_) {}),
      size: const Size(800, 800),
    );
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(find.text('17'), findsWidgets);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(400, 800),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: Scaffold(body: child),
    ),
  );
}

String _fieldText(WidgetTester tester) {
  return tester.widget<TextField>(find.byType(TextField)).controller?.text ??
      '';
}

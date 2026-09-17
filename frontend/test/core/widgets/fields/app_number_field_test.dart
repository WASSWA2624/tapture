import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/widgets/fields/app_number_field.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  testWidgets('letters are rejected as they are typed', (
    WidgetTester tester,
  ) async {
    final List<num?> values = <num?>[];
    await _pump(tester, AppNumberField(label: 'Count', onChanged: values.add));

    await tester.enterText(find.byType(TextField), '12a');
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      '12',
    );
    expect(values, <num?>[12]);
  });

  testWidgets('an out-of-range value uses the shared error style', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AppNumberField(label: 'Count', min: 0, max: 10, onChanged: (_) {}),
    );

    await tester.enterText(find.byType(TextField), '99');
    await tester.pump();
    expect(find.text('Out of range'), findsOneWidget);
    expect(find.byType(AppNumberField), meetsTapTarget());
    expect(find.byType(AppNumberField), hasSemanticLabel('Count'));
  });

  testWidgets('a decimal field accepts a point and rejects a second one', (
    WidgetTester tester,
  ) async {
    final List<num?> values = <num?>[];
    await _pump(
      tester,
      AppNumberField(label: 'Mass', decimal: true, onChanged: values.add),
    );

    await tester.enterText(find.byType(TextField), '1.5');
    await tester.pump();
    expect(values.last, 1.5);

    await tester.enterText(find.byType(TextField), '1.5.2');
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      '1.5',
    );
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
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

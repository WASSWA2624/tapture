import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/fields/app_multi_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  final List<Choice<String>> options = <Choice<String>>[
    const Choice<String>('a', 'Alpha'),
    const Choice<String>('b', 'Bravo'),
    const Choice<String>('c', 'Charlie'),
  ];

  testWidgets('closed field shows selected values as chips', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AppMultiChoiceField<String>(
        label: 'Tags',
        options: options,
        value: const <String>{'a', 'c'},
        onChanged: (_) {},
      ),
    );

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Charlie'), findsOneWidget);
    expect(find.text('Bravo'), findsNothing);
    expect(find.byType(AppChip), findsNWidgets(2));
    expect(find.byType(AppMultiChoiceField<String>), meetsTapTarget());
    expect(find.byType(AppMultiChoiceField<String>), hasSemanticLabel('Tags'));
  });

  testWidgets('select-all and clear update the selection', (
    WidgetTester tester,
  ) async {
    Set<String> latest = const <String>{};
    await _pump(
      tester,
      AppMultiChoiceField<String>(
        label: 'Tags',
        options: options,
        value: latest,
        onChanged: (Set<String> value) => latest = value,
      ),
      size: const Size(400, 800),
    );

    await tester.tap(find.byType(AppMultiChoiceField<String>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select all'));
    await tester.pump();
    expect(latest, <String>{'a', 'b', 'c'});

    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(latest, isEmpty);
  });

  testWidgets('a 200-option list can be searched on a compact screen', (
    WidgetTester tester,
  ) async {
    final List<Choice<int>> many = <Choice<int>>[
      for (int i = 0; i < 200; i++) Choice<int>(i, 'Option $i'),
    ];
    Set<int> latest = const <int>{};
    await _pump(
      tester,
      AppMultiChoiceField<int>(
        label: 'Items',
        options: many,
        value: latest,
        onChanged: (Set<int> value) => latest = value,
      ),
      size: const Size(400, 800),
    );

    await tester.tap(find.byType(AppMultiChoiceField<int>));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '199');
    await tester.pump();
    expect(find.text('Option 199'), findsOneWidget);
    expect(find.text('Option 0'), findsNothing);

    await tester.tap(find.text('Option 199'));
    await tester.pump();
    expect(latest, <int>{199});
    expect(find.byIcon(Icons.check), findsWidgets);
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
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(Space.x4), child: child),
      ),
    ),
  );
}

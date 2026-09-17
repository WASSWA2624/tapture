import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_chip.dart';

void main() {
  final List<AppChip> chips = <AppChip>[
    for (int i = 0; i < 8; i++) AppChip(label: 'Filter $i', onTap: () {}),
  ];

  testWidgets('a wrapping row keeps every label without overflowing', (
    WidgetTester tester,
  ) async {
    await _pump(tester, AppChipRow(chips: chips), size: const Size(200, 400));

    expect(find.byType(Wrap), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);
    expect(find.text('Filter 0'), findsOneWidget);
    expect(find.text('Filter 7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a scrollable row keeps labels in the scroll extent', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AppChipRow(chips: chips, scrollable: true),
      size: const Size(200, 400),
    );

    expect(find.byType(Wrap), findsNothing);
    expect(find.byType(Scrollable), findsOneWidget);
    expect(find.text('Filter 0'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Filter 7'), 80);
    expect(find.text('Filter 7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
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
      theme: buildTheme(brightness: Brightness.light),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(Space.x4), child: child),
      ),
    ),
  );
}

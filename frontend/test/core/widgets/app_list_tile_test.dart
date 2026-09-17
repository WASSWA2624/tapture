import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';

import '../../support/a11y_matchers.dart';

void main() {
  testWidgets('tap opens and long-press selects', (WidgetTester tester) async {
    bool opened = false;
    bool selected = false;
    await _pump(
      tester,
      AppListTile(
        title: 'Boiler A',
        subtitle: 'Plant 3',
        onTap: () => opened = true,
        onLongPress: () => selected = true,
      ),
    );

    expect(find.byType(AppListTile), meetsTapTarget());
    expect(find.byType(AppListTile), hasSemanticLabel('Boiler A'));

    await tester.tap(find.byType(AppListTile));
    await tester.pump();
    expect(opened, isTrue);
    expect(selected, isFalse);

    await tester.longPress(find.byType(AppListTile));
    await tester.pump();
    expect(selected, isTrue);
  });

  testWidgets('selection and status are named, not colour alone', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const AppListTile(
        title: 'Boiler A',
        selected: true,
        status: AppChip(label: 'Draft', icon: Icons.edit_note),
      ),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.byIcon(Icons.edit_note), findsOneWidget);
  });

  testWidgets('a dense row stays usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: AppPage(
          title: 'Row',
          body: AppListTile(
            dense: true,
            title: 'A very long record title that must wrap rather than clip',
            subtitle: 'Plant 3 · captured this morning',
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await expectNoA11yIssues(tester);
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
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(Space.x4), child: child),
      ),
    ),
  );
}

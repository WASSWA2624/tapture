import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';

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
        status: AppStatusPill.badge(status: RecordStatus.draft),
      ),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.byIcon(Icons.edit_note), findsOneWidget);
  });

  testWidgets('the current row is marked by a start bar and announced', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _pump(
      tester,
      Column(
        children: <Widget>[
          AppListTile(title: 'Open', current: true, onTap: () {}),
          AppListTile(title: 'Other', onTap: () {}),
        ],
      ),
    );

    final Finder mark = find.byKey(AppListTile.currentMarkKey);
    expect(mark, findsOneWidget);
    final DecoratedBox bar = tester.widget<DecoratedBox>(mark);
    expect(bar.position, DecorationPosition.foreground);
    // A start-edge border follows the reading direction, so the bar sits
    // on the right under a right-to-left locale (FE-L10N-05).
    final BorderDirectional border =
        (bar.decoration as BoxDecoration).border! as BorderDirectional;
    expect(border.start.width, Space.x1);
    expect(border.end, BorderSide.none);
    expect(
      tester.getSemantics(find.byType(AppListTile).first),
      matchesSemantics(
        label: 'Open',
        isSelected: true,
        hasSelectedState: true,
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    expect(find.byIcon(Icons.check), findsNothing);
    semantics.dispose();
  });

  testWidgets('a current row can also be ticked for multi-select', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const AppListTile(title: 'Open', current: true, selected: true),
    );
    expect(find.byKey(AppListTile.currentMarkKey), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
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

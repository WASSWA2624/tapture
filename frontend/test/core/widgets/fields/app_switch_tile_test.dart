import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  _denseCases();

  testWidgets('tapping anywhere on the tile toggles the value', (
    WidgetTester tester,
  ) async {
    bool value = false;
    await _pump(
      tester,
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AppSwitchTile(
            title: 'GPS',
            description: 'Include a location stamp.',
            value: value,
            onChanged: (bool next) => setState(() => value = next),
          );
        },
      ),
    );

    expect(find.byType(AppSwitchTile), meetsTapTarget());
    expect(find.byType(AppSwitchTile), hasSemanticLabel('GPS'));
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await tester.tap(find.text('GPS'));
    await tester.pump();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await tester.tap(find.text('Include a location stamp.'));
    await tester.pump();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    final Rect tile = tester.getRect(find.byType(AppSwitchTile));
    await tester.tapAt(Offset(tile.right - Space.x6, tile.center.dy));
    await tester.pump();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('the checkbox variant shares the layout and toggles', (
    WidgetTester tester,
  ) async {
    bool value = false;
    await _pump(
      tester,
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AppSwitchTile.checkbox(
            title: 'Required',
            value: value,
            onChanged: (bool next) => setState(() => value = next),
          );
        },
      ),
    );

    expect(find.byType(Switch), findsNothing);
    expect(find.byType(Checkbox), findsOneWidget);
    await tester.tap(find.byType(AppSwitchTile));
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  testWidgets('the tile stays usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: AppPage(
          title: 'Switch',
          body: AppSwitchTile(
            title: 'GPS',
            description: 'Include a location stamp on every capture.',
            value: true,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await expectNoA11yIssues(tester);
  });
}

void _denseCases() {
  testWidgets('a dense tile is one 48dp line that announces its description', (
    WidgetTester tester,
  ) async {
    bool value = true;
    await _pump(
      tester,
      // In a form it sits in a scrolling column, so its height is its own.
      SingleChildScrollView(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AppSwitchTile(
              title: 'Attach screenshot',
              description: 'Of Projects',
              value: value,
              dense: true,
              onChanged: (bool next) => setState(() => value = next),
            );
          },
        ),
      ),
    );
    expect(tester.getSize(find.byType(AppSwitchTile)).height, 48);
    expect(find.text('Of Projects'), findsNothing);
    expect(
      tester.getSemantics(find.byType(AppSwitchTile)),
      isSemantics(
        label: 'Attach screenshot',
        hint: 'Of Projects',
        isToggled: true,
      ),
    );
    expect(find.byType(AppSwitchTile), meetsTapTarget());
    await tester.tap(find.text('Attach screenshot'));
    await tester.pump();
    expect(value, isFalse);
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

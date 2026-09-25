import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';

import '../../support/a11y_matchers.dart';

void main() {
  testWidgets('every status shows an icon and a label, not colour alone', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      Column(
        children: <Widget>[
          for (final RecordStatus status in RecordStatus.values)
            AppStatusPill(status: status),
        ],
      ),
    );

    const AppColors colors = AppColors.light;
    for (final RecordStatus status in RecordStatus.values) {
      final (_, IconData icon, String label) = StatusStyle.of(status, colors);
      expect(find.text(label), findsOneWidget);
      expect(find.byIcon(icon), findsOneWidget);
    }
  });

  testWidgets('the badge form fits a list tile and stays labelled', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const AppListTile(
        title: 'Boiler A',
        status: AppStatusPill.badge(status: RecordStatus.needsReview),
      ),
    );

    expect(find.text('Needs review'), findsOneWidget);
    expect(find.byIcon(AppIcons.review), findsOneWidget);
    expect(find.byType(AppStatusPill), hasSemanticLabel('Needs review'));
  });

  testWidgets('pills stay usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: AppPage(
          title: 'Status',
          body: Column(
            children: <Widget>[
              for (final RecordStatus status in RecordStatus.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.x2),
                  child: AppStatusPill(status: status),
                ),
            ],
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
  tester.view.physicalSize = const Size(400, 1200);
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

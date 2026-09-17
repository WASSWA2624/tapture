import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';

import '../../support/a11y_matchers.dart';

void main() {
  testWidgets('the heading and optional action both render', (
    WidgetTester tester,
  ) async {
    bool pressed = false;
    await _pump(
      tester,
      AppSectionHeader(
        title: 'Records',
        action: AppIconButton(
          icon: Icons.filter_list,
          semanticLabel: 'Filter records',
          tooltip: 'Filter records',
          onPressed: () => pressed = true,
        ),
      ),
    );

    expect(find.text('Records'), findsOneWidget);
    expect(find.byType(AppSectionHeader), hasSemanticLabel('Records'));
    await tester.tap(find.byTooltip('Filter records'));
    await tester.pump();
    expect(pressed, isTrue);
  });

  testWidgets('the heading stays usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const AppPage(
          title: 'Header',
          body: AppSectionHeader(
            title: 'A long section name that must wrap rather than clip',
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

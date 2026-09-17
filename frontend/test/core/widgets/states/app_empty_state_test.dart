import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  testWidgets('shows the icon, headline, message and fires the action', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    await _pump(
      tester,
      AppEmptyState(
        icon: Icons.folder_open,
        headline: 'No projects yet',
        message: 'Create a project to start capturing.',
        actionLabel: 'Create a project',
        onAction: () => tapped = true,
      ),
    );

    expect(find.byIcon(Icons.folder_open), findsOneWidget);
    expect(find.text('No projects yet'), findsOneWidget);
    expect(find.text('Create a project to start capturing.'), findsOneWidget);
    expect(find.byType(AppEmptyState), hasSemanticLabel('No projects yet'));
    expect(find.byType(AppButton), meetsTapTarget());

    await tester.tap(find.text('Create a project'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('stays usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: AppPage(
          title: 'Empty',
          body: AppEmptyState(
            icon: Icons.folder_open,
            headline: 'No projects yet',
            message: 'Create a project to start capturing.',
            actionLabel: 'Create a project',
            onAction: () {},
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

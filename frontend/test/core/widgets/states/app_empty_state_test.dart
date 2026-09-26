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

  testWidgets('with onIconTap the icon is a named 48dp button', (
    WidgetTester tester,
  ) async {
    var tapped = 0;
    await _pump(
      tester,
      AppEmptyState(
        icon: Icons.add_a_photo_outlined,
        headline: 'No photos yet',
        message: 'Add a photo to start this record.',
        onIconTap: () => tapped++,
        iconLabel: 'Add photo',
      ),
    );

    final Finder action = find.byKey(
      const ValueKey<String>('empty-state-icon-action'),
    );
    expect(action, findsOneWidget);
    expect(find.byType(AppButton), findsNothing);
    expect(find.byTooltip('Add photo'), findsOneWidget);
    expect(
      tester.getSemantics(action),
      matchesSemantics(
        label: 'Add photo',
        isButton: true,
        hasTapAction: true,
        isFocusable: false,
      ),
    );
    expect(tester.getSize(action).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
    expect(action, meetsTapTarget());
    expect(find.byType(AppEmptyState), hasSemanticLabel('No photos yet'));

    await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('without onIconTap the icon is plain', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const AppEmptyState(
        icon: Icons.add_a_photo_outlined,
        headline: 'No photos yet',
        message: 'Add a photo to start this record.',
        iconLabel: 'Add photo',
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('empty-state-icon-action')),
      findsNothing,
    );
    expect(find.byType(InkWell), findsNothing);
    expect(find.byTooltip('Add photo'), findsNothing);
    expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
  });

  test('the icon and a button cannot both be the action', () {
    expect(
      () => AppEmptyState(
        icon: Icons.add_a_photo_outlined,
        headline: 'No photos yet',
        message: 'Add a photo to start this record.',
        actionLabel: 'Add photo',
        onAction: () {},
        onIconTap: () {},
        iconLabel: 'Add photo',
      ),
      throwsAssertionError,
    );
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

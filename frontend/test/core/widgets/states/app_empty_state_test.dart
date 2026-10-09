import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  group('compact empty state', () {
    testWidgets('is opt-in and retains the full headline and explanation', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const Column(
          children: <Widget>[
            AppEmptyState(
              key: ValueKey<String>('default-empty'),
              icon: Icons.folder_open,
              headline: 'No records yet',
              message: 'Capture a record to start reviewing.',
            ),
            AppEmptyState(
              key: ValueKey<String>('compact-empty'),
              icon: Icons.folder_open,
              headline: 'No records yet',
              message: 'Capture a record to start reviewing.',
              compact: true,
            ),
          ],
        ),
      );
      final Finder standard = find.byKey(
        const ValueKey<String>('default-empty'),
      );
      final Finder compact = find.byKey(
        const ValueKey<String>('compact-empty'),
      );
      expect(
        find.descendant(of: standard, matching: find.byType(AppListTile)),
        findsNothing,
      );
      final AppListTile row = tester.widget<AppListTile>(
        find.descendant(of: compact, matching: find.byType(AppListTile)),
      );
      expect(row.title, 'No records yet');
      expect(row.subtitle, 'Capture a record to start reviewing.');
      expect(row.wrapText, isTrue);
      expect(
        tester.getSize(compact).height,
        lessThan(tester.getSize(standard).height),
      );
      expect(compact, hasSemanticLabel('No records yet'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('offers one named icon action with a 48dp target', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await _pump(
        tester,
        AppEmptyState(
          icon: Icons.add_a_photo_outlined,
          headline: 'No photos yet',
          message: 'Add a photo to start this record.',
          compact: true,
          onIconTap: () => taps++,
          iconLabel: 'Add photo',
        ),
      );
      final Finder action = find.byType(AppIconButton);
      expect(action, findsOneWidget);
      expect(find.byType(AppButton), findsNothing);
      expect(action, meetsTapTarget());
      expect(action, hasSemanticLabel('Add photo'));
      expect(find.byTooltip('Add photo'), findsOneWidget);
      await tester.tap(action);
      await tester.pump();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('retains the action callback and mutual exclusion', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await _pump(
        tester,
        AppEmptyState(
          icon: Icons.folder_open,
          headline: 'No records yet',
          message: 'Capture a record to start reviewing.',
          compact: true,
          actionLabel: 'Capture',
          onAction: () => taps++,
        ),
      );
      expect(find.byType(AppButton), findsNothing);
      final Finder action = find.byType(AppIconButton);
      expect(action, meetsTapTarget());
      expect(action, hasSemanticLabel('Capture'));
      await tester.tap(action);
      await tester.pump();
      expect(taps, 1);
      expect(
        () => AppEmptyState(
          icon: Icons.folder_open,
          headline: 'No records yet',
          message: 'Capture a record.',
          compact: true,
          actionLabel: 'Capture',
          onAction: () {},
          onIconTap: () {},
          iconLabel: 'Capture',
        ),
        throwsAssertionError,
      );
    });

    testWidgets('complete text grows naturally at 200 percent on 320dp', (
      WidgetTester tester,
    ) async {
      const String headline = 'No captured photos are available yet';
      const String message =
          'Add a photo to keep the original evidence for this record.';
      final List<double> heights = <double>[];
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final double scale in <double>[1, 2]) {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await _pump(
          tester,
          AppEmptyState(
            icon: Icons.add_a_photo_outlined,
            headline: headline,
            message: message,
            compact: true,
            onIconTap: () {},
            iconLabel: 'Add photo',
          ),
          size: const Size(320, 740),
        );
        final Rect bounds = tester.getRect(find.byType(AppEmptyState));
        heights.add(bounds.height);
        for (final String text in <String>[headline, message]) {
          final RenderParagraph paragraph = tester
              .renderObject<RenderParagraph>(
                find.descendant(
                  of: find.text(text),
                  matching: find.byType(RichText),
                ),
              );
          expect(paragraph.didExceedMaxLines, isFalse, reason: text);
          final Rect painted = MatrixUtils.transformRect(
            paragraph.getTransformTo(null),
            paragraph.paintBounds,
          );
          expect(painted.left, greaterThanOrEqualTo(bounds.left));
          expect(painted.right, lessThanOrEqualTo(bounds.right));
          expect(painted.top, greaterThanOrEqualTo(bounds.top));
          expect(painted.bottom, lessThanOrEqualTo(bounds.bottom));
        }
        expect(find.byType(AppIconButton), meetsTapTarget());
        expect(find.byType(AppIconButton), hasSemanticLabel('Add photo'));
        expect(tester.takeException(), isNull);
      }
      expect(heights.last, greaterThan(heights.first));
    });

    testWidgets('a short panel scrolls to its working action at 200 percent', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      int taps = 0;
      await _pump(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 320,
            height: 120,
            child: AppEmptyState(
              icon: Icons.folder_open,
              headline: 'No records yet',
              message: 'Capture a record to start reviewing.',
              compact: true,
              actionLabel: 'Capture',
              onAction: () => taps++,
            ),
          ),
        ),
      );
      final Finder action = find.byType(AppIconButton);
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(action.hitTestable(), findsOneWidget);
      expect(action, meetsTapTarget());
      await tester.tap(action);
      await tester.pump();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unavailable icon action is named and disabled', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const AppEmptyState(
          icon: Icons.add_a_photo_outlined,
          headline: 'No photos yet',
          message: 'Add a photo to start this record.',
          compact: true,
          iconLabel: 'Add photo',
        ),
      );
      final Finder action = find.byType(AppIconButton);
      expect(action, findsOneWidget);
      expect(action, meetsTapTarget());
      expect(action, hasSemanticLabel('Add photo'));
      expect(tester.widget<AppIconButton>(action).onPressed, isNull);
      expect(
        tester
            .getSemantics(action)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
      await tester.tap(action);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

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

  testWidgets('a short bounded empty panel scrolls to its working action', (
    WidgetTester tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 320,
          height: 120,
          child: AppEmptyState(
            icon: Icons.folder_open,
            headline: 'No records yet',
            message: 'Capture a record to start reviewing.',
            actionLabel: 'Capture',
            onAction: () => taps++,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final Finder action = find.widgetWithText(AppButton, 'Capture');
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    expect(action.hitTestable(), findsOneWidget);
    await tester.tap(action);
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unbounded panel leaves scrolling with its page', (
    WidgetTester tester,
  ) async {
    final ScrollController page = ScrollController();
    addTearDown(page.dispose);
    await _pump(
      tester,
      SingleChildScrollView(
        controller: page,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 800),
            AppEmptyState(
              icon: Icons.folder_open,
              headline: 'No records yet',
              message: 'Capture a record to start reviewing.',
              actionLabel: 'Capture',
              onAction: () {},
            ),
          ],
        ),
      ),
    );
    final Finder panelScroll = find.descendant(
      of: find.byType(AppEmptyState),
      matching: find.byType(Scrollable),
    );
    expect(
      tester.state<ScrollableState>(panelScroll).position.maxScrollExtent,
      0,
    );
    await tester.ensureVisible(find.widgetWithText(AppButton, 'Capture'));
    await tester.pumpAndSettle();
    expect(page.offset, greaterThan(0));
    expect(
      find.widgetWithText(AppButton, 'Capture').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty panels retain intrinsic measurement for dialogs', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      Center(
        child: IntrinsicWidth(
          child: IntrinsicHeight(
            child: AppEmptyState(
              icon: Icons.folder_open,
              headline: 'No records yet',
              message: 'Capture a record.',
              actionLabel: 'Capture',
              onAction: () {},
            ),
          ),
        ),
      ),
    );
    expect(
      find.widgetWithText(AppButton, 'Capture').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
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

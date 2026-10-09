import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';

import '../../support/a11y_matchers.dart';

void main() {
  testWidgets('a tap on a selectable chip fires onTap', (
    WidgetTester tester,
  ) async {
    bool tapped = false;
    await _pump(
      tester,
      AppChip(label: 'Water', selected: true, onTap: () => tapped = true),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byType(AppChip), meetsTapTarget());
    expect(find.byType(AppChip), hasSemanticLabel('Water'));

    await tester.tap(find.text('Water'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('dismiss removes by firing onDismiss', (
    WidgetTester tester,
  ) async {
    bool dismissed = false;
    await _pump(
      tester,
      AppChip(label: 'Water', onDismiss: () => dismissed = true),
    );

    await tester.tap(find.byTooltip('Dismiss Water'));
    await tester.pump();
    expect(dismissed, isTrue);
  });

  testWidgets('a plain chip is not a 48dp target', (WidgetTester tester) async {
    await _pump(tester, const AppChip(label: 'Water'));

    expect(find.byType(InkWell), findsNothing);
    final Size size = tester.getSize(find.byType(AppChip));
    expect(size.height, lessThan(Sizes.minTapTarget));
  });

  testWidgets('a long label ellipsizes at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const AppPage(
          title: 'Chip',
          body: AppChip(
            label:
                'A very long facility name that must not clip the page at '
                'two hundred percent text scale',
            selected: true,
            onTap: _ignore,
            onDismiss: _ignore,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await expectNoA11yIssues(tester);
  });

  for (final double scale in <double>[1, 2]) {
    testWidgets('comfortable chips paint their full target at $scale scale', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(
        tester,
        const AppChip(
          label: 'A complete facility value that wraps in its bounded body',
          comfortable: true,
          wrapLabel: true,
          maxLabelWidth: 180,
          onTap: _ignore,
        ),
      );
      final Finder body = find.descendant(
        of: find.byType(AppChip),
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is Material && widget.type == MaterialType.canvas,
        ),
      );
      expect(
        tester.getSize(body).height,
        greaterThanOrEqualTo(Sizes.minTapTarget),
      );
      expect(tester.getSize(body).width, lessThanOrEqualTo(180));
      expect(tester.takeException(), isNull);
      await expectNoA11yIssues(tester);
    });
  }

  testWidgets('a preview announces its full value and retains dismissal', (
    WidgetTester tester,
  ) async {
    bool dismissed = false;
    const String full = 'Facility: Complete original facility value';
    await _pump(
      tester,
      AppChip(
        label: 'Facility: Preview',
        semanticLabel: full,
        comfortable: true,
        wrapLabel: true,
        maxLabelWidth: 280,
        onTap: _ignore,
        onDismiss: () => dismissed = true,
      ),
    );
    expect(find.byType(AppChip), hasSemanticLabel(full));
    await tester.tap(find.byTooltip('Dismiss Facility: Preview'));
    await tester.pump();
    expect(dismissed, isTrue);
  });

  testWidgets('comfortable selected pins retain their pin and selection cues', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const AppChip(
        label: 'Pinned value',
        icon: AppIcons.pin,
        selected: true,
        comfortable: true,
        onTap: _ignore,
      ),
    );
    expect(find.byIcon(AppIcons.pin), findsOneWidget);
    expect(find.byIcon(AppIcons.check), findsOneWidget);
    expect(find.byType(AppChip), meetsTapTarget());
  });
}

void _ignore() {}

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

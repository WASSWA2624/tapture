import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/markup_ink.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_ink_picker.dart';

import '../../support/a11y_matchers.dart';

void main() {
  test('every ink has its own name', () {
    final Set<String> names = <String>{
      for (final MarkupInk ink in MarkupInk.values) Copy.markupInk(ink),
    };
    expect(names, hasLength(MarkupInk.values.length));
    expect(names, everyElement(isNotEmpty));
  });

  test('each size has a stroke width and a text height', () {
    expect(AppConstants.markup.strokeFractions, hasLength(3));
    expect(AppConstants.markup.textFractions, hasLength(3));
    for (final List<double> steps in <List<double>>[
      AppConstants.markup.strokeFractions,
      AppConstants.markup.textFractions,
    ]) {
      expect(steps[0], lessThan(steps[1]));
      expect(steps[1], lessThan(steps[2]));
    }
  });

  testWidgets('a tapped swatch is reported and the chosen one is ticked', (
    WidgetTester tester,
  ) async {
    final List<MarkupInk> picked = <MarkupInk>[];
    await _pump(
      tester,
      AppInkPicker(
        ink: MarkupInk.red,
        size: 1,
        onInk: picked.add,
        onSize: (int _) {},
      ),
    );

    for (final MarkupInk ink in MarkupInk.values) {
      expect(find.byTooltip(Copy.markupInk(ink)), findsOneWidget);
    }
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('ink-red')),
        matching: find.byIcon(AppIcons.check),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('ink-yellow')));
    await tester.tap(find.byKey(const ValueKey<String>('ink-green')));
    expect(picked, <MarkupInk>[MarkupInk.yellow, MarkupInk.green]);
  });

  testWidgets('sizes report 0, 1 and 2', (WidgetTester tester) async {
    final List<int> sizes = <int>[];
    for (final int shown in <int>[1, 0]) {
      await _pump(
        tester,
        AppInkPicker(
          ink: MarkupInk.red,
          size: shown,
          onInk: (MarkupInk _) {},
          onSize: sizes.add,
        ),
      );
      if (shown == 1) {
        await tester.tap(find.text(Copy.markupSizeSmall));
        await tester.tap(find.text(Copy.markupSizeLarge));
      } else {
        await tester.tap(find.text(Copy.markupSizeMedium));
      }
    }
    expect(sizes, <int>[0, 2, 1]);
  });

  for (final double scale in <double>[1, 2]) {
    testWidgets('at ${scale}x text every swatch is a 48dp named target', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(
        tester,
        AppInkPicker(
          ink: MarkupInk.blue,
          size: 2,
          onInk: (MarkupInk _) {},
          onSize: (int _) {},
        ),
      );

      expect(tester.takeException(), isNull);
      for (final MarkupInk ink in MarkupInk.values) {
        final Finder swatch = find.byKey(ValueKey<String>('ink-${ink.name}'));
        expect(tester.getSize(swatch), const Size.square(48));
        expect(swatch, hasSemanticLabel(Copy.markupInk(ink)));
      }
      await expectNoA11yIssues(tester);
    });
  }
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(393, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

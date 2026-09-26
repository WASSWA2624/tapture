import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  testWidgets('compact width presents a bottom sheet', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const Size(400, 800),
      Builder(
        builder: (BuildContext context) {
          return AppButton(
            label: 'Open',
            onPressed: () {
              showAppSheet<void>(
                context,
                title: 'Pick a grade',
                builder: (BuildContext context) => const Text('Sheet body'),
              );
            },
          );
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomSheet), findsOneWidget);
    expect(find.text('Pick a grade'), findsOneWidget);
    expect(find.text('Sheet body'), findsOneWidget);

    final Rect sheet = tester.getRect(find.byType(AppBottomSheet));
    expect(sheet.bottom, closeTo(800, 1));
    expect(sheet.width, closeTo(400, 1));
  });

  for (final bool contentSized in <bool>[true, false]) {
    testWidgets(
      'a ${contentSized ? 'short' : 'full'} sheet draws one handle and is '
      'only as tall as its content',
      (WidgetTester tester) async {
        await _pump(
          tester,
          const Size(393, 886),
          Builder(
            builder: (BuildContext context) {
              return AppButton(
                label: 'Open',
                onPressed: () {
                  showAppSheet<void>(
                    context,
                    title: 'Edit',
                    contentSized: contentSized,
                    builder: (BuildContext context) => const Text('Body'),
                  );
                },
              );
            },
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final BottomSheet modal = tester.widget<BottomSheet>(
          find.byType(BottomSheet),
        );
        expect(modal.showDragHandle, isFalse);
        final double modalHeight = tester
            .getSize(find.byType(BottomSheet))
            .height;
        final double sheetHeight = tester
            .getSize(find.byType(AppBottomSheet))
            .height;
        expect(modalHeight, closeTo(sheetHeight, 1));
        if (contentSized) {
          expect(sheetHeight, lessThan(886 / 2));
        } else {
          final double available = tester
              .getSize(find.byType(Scaffold).first)
              .height;
          expect(sheetHeight, lessThanOrEqualTo(available * 0.75 + 1));
        }
      },
    );
  }

  testWidgets('the filter sheet shows the facets and clears and closes', (
    WidgetTester tester,
  ) async {
    var cleared = 0;
    await _pump(
      tester,
      const Size(400, 800),
      Builder(
        builder: (BuildContext context) {
          return AppButton(
            label: 'Open',
            onPressed: () {
              showAppFilterSheet(
                context,
                title: 'Record filters',
                facets: (BuildContext _) => const Text('Status facet'),
                onClear: () => cleared++,
              );
            },
          );
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Record filters'), findsOneWidget);
    expect(find.text('Status facet'), findsOneWidget);
    final Finder clear = find.byKey(
      const ValueKey<String>('filter-sheet-clear'),
    );
    expect(find.text(Copy.searchClearFilters), findsOneWidget);
    expect(clear, meetsTapTarget());

    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(cleared, 1);
    expect(find.byType(AppBottomSheet), findsNothing);
  });

  testWidgets('expanded width presents a side panel', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const Size(1100, 800),
      Builder(
        builder: (BuildContext context) {
          return AppButton(
            label: 'Open',
            onPressed: () {
              showAppSheet<void>(
                context,
                title: 'Pick a grade',
                builder: (BuildContext context) => const Text('Sheet body'),
              );
            },
          );
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomSheet), findsOneWidget);
    final Rect sheet = tester.getRect(find.byType(AppBottomSheet));
    expect(sheet.width, Space.x12 * 8);
    expect(sheet.right, closeTo(1100, 1));
    expect(sheet.height, closeTo(800, 1));
  });

  testWidgets('stays usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const AppPage(
          title: 'Sheet',
          body: SizedBox(
            height: Space.x12 * 5,
            child: AppBottomSheet(title: 'Pick a grade', child: Text('Body')),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await expectNoA11yIssues(tester);
  });
}

Future<void> _pump(WidgetTester tester, Size size, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

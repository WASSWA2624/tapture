import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/feedback/app_panel_dialog.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  testWidgets('the panel shows its title and close pops it', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Builder(
          builder: (BuildContext context) {
            return AppButton(
              label: 'Open',
              onPressed: () {
                showAppPanelDialog<void>(
                  context,
                  title: Copy.feedbackGive,
                  builder: (BuildContext _) => const Text('Write it here'),
                );
              },
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text(Copy.feedbackGive), findsOneWidget);
    expect(find.text('Write it here'), findsOneWidget);
    expect(find.byType(AppPanelDialog), meetsTapTarget());

    await tester.tap(find.byTooltip(Copy.close));
    await tester.pumpAndSettle();
    expect(find.text('Write it here'), findsNothing);
  });

  testWidgets('the title bar moves the panel', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Builder(
          builder: (BuildContext context) {
            return AppButton(
              label: 'Open',
              onPressed: () {
                showAppPanelDialog<void>(
                  context,
                  title: Copy.feedbackGive,
                  builder: (BuildContext _) => const Text('Write it here'),
                );
              },
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final Offset before = tester.getTopLeft(find.text('Write it here'));
    await tester.drag(find.text(Copy.feedbackGive), const Offset(80, 120));
    await tester.pump();
    final Offset after = tester.getTopLeft(find.text('Write it here'));
    expect(after.dx, closeTo(before.dx + 80, 1));
    expect(after.dy, closeTo(before.dy + 120, 1));
  });
}

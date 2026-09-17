import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  testWidgets('undo invokes its callback', (WidgetTester tester) async {
    var undone = false;
    await _pump(
      tester,
      Builder(
        builder: (BuildContext context) {
          return AppButton(
            label: 'Notify',
            onPressed: () {
              showAppSnack(
                context,
                'Record deleted',
                undoLabel: 'Undo',
                onUndo: () => undone = true,
              );
            },
          );
        },
      ),
    );

    await tester.tap(find.text('Notify'));
    await tester.pump();
    await tester.pump(AppConstants.motion.medium);

    expect(find.text('Record deleted'), findsOneWidget);
    expect(find.byType(AppButton), meetsTapTarget());

    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(undone, isTrue);
  });

  testWidgets('two snacks queue rather than overlap', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      Builder(
        builder: (BuildContext context) {
          return AppButton(
            label: 'Notify',
            onPressed: () {
              showAppSnack(context, 'First');
              showAppSnack(context, 'Second');
            },
          );
        },
      ),
    );

    await tester.tap(find.text('Notify'));
    await tester.pump();
    await tester.pump(AppConstants.motion.medium);

    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsNothing);

    await tester.pump(AppConstants.feedback.snack);
    await tester.pump(AppConstants.motion.medium);

    expect(find.text('Second'), findsOneWidget);
    expect(find.text('First'), findsNothing);

    await tester.pump(AppConstants.feedback.snack);
    await tester.pump(AppConstants.motion.medium);
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
          title: 'Snack',
          body: AppSnackbar(
            message: 'Record deleted',
            undoLabel: 'Undo',
            onUndo: () {},
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
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

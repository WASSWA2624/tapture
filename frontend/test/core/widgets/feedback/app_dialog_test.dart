import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  testWidgets('confirm returns true and cancel returns false', (
    WidgetTester tester,
  ) async {
    bool? latest;
    await _pump(
      tester,
      Builder(
        builder: (BuildContext context) {
          return AppButton(
            label: 'Open',
            onPressed: () async {
              latest = await showAppConfirm(
                context,
                title: 'Delete record',
                message: 'This hides the record. You can undo.',
                confirmLabel: 'Delete',
                destructive: true,
              );
            },
          );
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Delete record'), findsOneWidget);
    expect(find.byType(AppButton), meetsTapTarget());

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(latest, isFalse);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(latest, isTrue);
  });

  testWidgets('an alert closes on OK', (WidgetTester tester) async {
    await _pump(
      tester,
      Builder(
        builder: (BuildContext context) {
          return AppButton(
            label: 'Open',
            onPressed: () {
              showAppAlert(
                context,
                title: 'Saved',
                message: 'The project is on this device.',
              );
            },
          );
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
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
          title: 'Dialog',
          body: AppDialog.confirm(
            title: 'Delete record',
            message: 'This hides the record. You can undo.',
            confirmLabel: 'Delete',
            destructive: true,
            onConfirm: () {},
            onCancel: () {},
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

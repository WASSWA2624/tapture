import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
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

  testWidgets(
    'at 1280 the confirm is at most the dialog max width and centred',
    (WidgetTester tester) async {
      await _openConfirm(tester, const Size(1280, 800));
      final Rect surface = tester.getRect(
        find.byKey(const ValueKey<String>('app-dialog-surface')),
      );
      expect(surface.width, lessThanOrEqualTo(Sizes.dialogMaxWidth));
      expect(surface.center.dx, closeTo(640, 0.5));
    },
  );

  testWidgets('at 360 the confirm fills the width less the inset', (
    WidgetTester tester,
  ) async {
    await _openConfirm(tester, const Size(360, 800));
    expect(
      tester
          .getSize(find.byKey(const ValueKey<String>('app-dialog-surface')))
          .width,
      360 - Space.x6 * 2,
    );
  });

  testWidgets('a destructive confirm shows the warning icon', (
    WidgetTester tester,
  ) async {
    await _openConfirm(tester, const Size(400, 800));
    final Icon icon = tester.widget<Icon>(
      find.byIcon(Icons.warning_amber_outlined),
    );
    expect(icon.color, tester.element(find.byType(AppDialog)).colors.danger);
  });

  testWidgets('a non-destructive confirm has no warning icon', (
    WidgetTester tester,
  ) async {
    await _openConfirm(tester, const Size(400, 800), destructive: false);
    expect(find.byIcon(Icons.warning_amber_outlined), findsNothing);
  });

  testWidgets('an alert has no warning icon', (WidgetTester tester) async {
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
    expect(find.byIcon(Icons.warning_amber_outlined), findsNothing);
  });
}

Future<void> _openConfirm(
  WidgetTester tester,
  Size size, {
  bool destructive = true,
}) async {
  await _pump(
    tester,
    Builder(
      builder: (BuildContext context) {
        return AppButton(
          label: 'Open',
          onPressed: () {
            showAppConfirm(
              context,
              title: 'Delete record',
              message: 'This hides the record. You can undo.',
              confirmLabel: 'Delete',
              destructive: destructive,
            );
          },
        );
      },
    ),
    size: size,
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
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
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

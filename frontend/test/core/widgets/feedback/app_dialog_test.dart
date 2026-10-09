import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/screen_fonts.dart';
import '../../../support/screen_probe.dart';

void main() {
  setUpAll(ScreenFonts.load);

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

  testWidgets('a short confirm keeps its natural height without scrolling', (
    WidgetTester tester,
  ) async {
    await _openConfirm(tester, const Size(400, 800));
    final ScrollableState scroll = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(AppDialog),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scroll.position.maxScrollExtent, 0);
    expect(
      tester
          .getSize(find.byKey(const ValueKey<String>('app-dialog-surface')))
          .height,
      lessThan(800 - Space.x6 * 2),
    );
  });

  for (final Locale locale in const <Locale>[
    Locale('en'),
    Locale('en', 'XA'),
  ]) {
    testWidgets(
      'photo removal scrolls complete text and both actions at short200 ${locale.toLanguageTag()}',
      (WidgetTester tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(393, 320);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        bool? latest;
        await tester.pumpWidget(
          MaterialApp(
            theme: ScreenFonts.theme(buildTheme(brightness: Brightness.light)),
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (BuildContext context, Widget? child) => Directionality(
              textDirection: locale.countryCode == 'XA'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: child!,
            ),
            home: Builder(
              builder: (BuildContext context) => Directionality(
                textDirection: locale.countryCode == 'XA'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Scaffold(
                  body: Builder(
                    builder: (BuildContext context) {
                      final LocalizedCopy copy = Copy.of(context);
                      return AppButton(
                        label: 'Open',
                        onPressed: () async {
                          latest = await showAppConfirm(
                            context,
                            title: copy.captureDeletePhotoTitle,
                            message: copy.captureDeletePhotoMessage,
                            confirmLabel: copy.captureDeletePhotoTitle,
                            destructive: true,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        final SemanticsHandle semantics = tester.ensureSemantics();
        try {
          for (final bool confirm in <bool>[false, true]) {
            await tester.tap(find.text('Open'));
            await tester.pumpAndSettle();
            expect(ScreenProbe.layoutIssues(tester), isEmpty);
            expect(
              Directionality.of(tester.element(find.byType(AppDialog))),
              locale.countryCode == 'XA'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
            );
            final LocalizedCopy copy = Copy.of(
              tester.element(find.byType(AppDialog)),
            );
            final ScrollableState scroll = tester.state<ScrollableState>(
              find.descendant(
                of: find.byType(AppDialog),
                matching: find.byType(Scrollable),
              ),
            );
            expect(scroll.position.maxScrollExtent, greaterThan(0));
            for (final String text in <String>[
              copy.captureDeletePhotoTitle,
              copy.captureDeletePhotoMessage,
            ]) {
              final Finder label = find
                  .descendant(
                    of: find.byType(AppDialog),
                    matching: find.text(text),
                  )
                  .first;
              await tester.ensureVisible(label);
              await tester.pumpAndSettle();
              final Rect bounds = tester.getRect(label);
              final Rect viewport = ScreenProbe.targetViewport(tester, label);
              expect(viewport.contains(bounds.topLeft), isTrue);
              expect(viewport.contains(bounds.bottomRight), isTrue);
            }
            for (final String label in <String>[
              copy.cancel,
              copy.captureDeletePhotoTitle,
            ]) {
              final Finder action = find.widgetWithText(AppButton, label);
              await tester.ensureVisible(action);
              await tester.pumpAndSettle();
              expect(action, meetsTapTarget());
              expect(
                await ScreenProbe.accessibilityIssues(
                  tester,
                  targets: <Finder>[action],
                  within: find.byType(AppDialog),
                ),
                isEmpty,
              );
            }
            final Finder selected = find.widgetWithText(
              AppButton,
              confirm ? copy.captureDeletePhotoTitle : copy.cancel,
            );
            await tester.ensureVisible(selected);
            await tester.pumpAndSettle();
            await tester.tap(selected);
            await tester.pumpAndSettle();
            expect(latest, confirm);
            expect(find.byType(AppDialog), findsNothing);
            expect(ScreenProbe.layoutIssues(tester), isEmpty);
          }
        } finally {
          semantics.dispose();
        }
      },
    );
  }
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

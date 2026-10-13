import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/features/account/presentation/sign_in_screen.dart';
import '../../../support/pump_app.dart';
import '../../../support/screen_matrix.dart';
import '../../../support/screen_probe.dart';

void main() {
  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets(
      'compact sign-in keeps credentials and submit reachable ${cell.description}',
      (WidgetTester tester) async {
        tester.view.physicalSize = cell.size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = cell.textScale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        int calls = 0;
        await pumpApp(
          tester,
          SignInScreen(
            onSubmit: (String email, String password) async {
              calls++;
              throw const PermissionFailure(
                message: 'Check your account',
                recoveryAction: 'Try again.',
              );
            },
          ),
          brightness: cell.brightness,
          outdoor: cell.outdoor,
        );
        await tester.enterText(
          find.byType(TextField).first,
          'person@example.test',
        );
        await tester.enterText(find.byType(TextField).last, 'entered password');
        final Finder submit = find.widgetWithText(
          AppPrimaryAction,
          Copy.signInAction,
        );
        await tester.ensureVisible(submit);
        await tester.pumpAndSettle();
        expect(
          await ScreenProbe.accessibilityIssues(
            tester,
            reachableTargets: <Finder>[submit],
          ),
          isEmpty,
        );
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(calls, 1);
        expect(
          tester.widget<AppPage>(find.byType(AppPage)).layout,
          AppPageLayout.compact,
        );
        expect(find.text('Check your account'), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.byType(TextField).last)
              .controller!
              .text,
          'entered password',
        );
        expect(ScreenProbe.layoutIssues(tester), isEmpty);
      },
    );
  }
  testWidgets(
    'busy sign-in ignores double submit; failure preserves entered credentials',
    (WidgetTester tester) async {
      final Completer<void> pending = Completer<void>();
      int calls = 0;
      await pumpApp(
        tester,
        SignInScreen(
          onSubmit: (String email, String password) async {
            calls++;
            await pending.future;
            throw const PermissionFailure(
              message: 'Check your account',
              recoveryAction: 'Try again.',
            );
          },
        ),
      );
      await tester.enterText(
        find.byType(TextField).first,
        'person@example.test',
      );
      await tester.enterText(find.byType(TextField).last, 'entered password');
      // The page title reads the same as the action, so tap the button.
      final Finder submit = find.widgetWithText(
        AppPrimaryAction,
        Copy.signInAction,
      );
      await tester.tap(submit);
      await tester.pump();
      await tester.tap(submit, warnIfMissed: false);
      expect(calls, 1);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Check your account'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'person@example.test',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        'entered password',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isTrue,
      );
    },
  );
}

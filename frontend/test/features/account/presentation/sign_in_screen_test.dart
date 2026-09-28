import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/features/account/presentation/sign_in_screen.dart';
import '../../../support/pump_app.dart';

void main() {
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
      final Finder submit = find.widgetWithText(AppButton, Copy.signInAction);
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

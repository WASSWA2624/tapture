import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/nav_shell.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/features/settings/data/pin_lock.dart';
import 'package:tapture/features/settings/domain/app_lock.dart';
import 'package:tapture/features/settings/presentation/app_lock_screen.dart';

void main() {
  testWidgets('set, change and remove a PIN without offering a wipe', (
    WidgetTester tester,
  ) async {
    final Map<SecretKey, String> backing = <SecretKey, String>{};
    final PinLock lock = PinLock.fake(backing: backing);
    await _pump(tester, lock);

    expect(find.text(Copy.appLockRecovery), findsOneWidget);
    expect(find.textContaining('wipe'), findsNothing);
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .every((TextField field) => field.obscureText),
      isTrue,
    );

    await tester.enterText(find.byType(TextField).at(0), '1234');
    await tester.enterText(find.byType(TextField).at(1), '1234');
    await tester.pump();
    await _tapAction(tester, find.byType(AppPrimaryAction));

    expect(lock.isEnabled, isTrue);
    expect(backing.containsKey(SecretKey.pinHash), isTrue);
    expect(backing.values, isNot(contains('1234')));
    expect(find.text(Copy.appLockChange), findsWidgets);
    expect(find.text(Copy.appLockRemove), findsOneWidget);
    expect(find.text(Copy.appLockRecovery), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '1234');
    await tester.enterText(find.byType(TextField).at(1), '5678');
    await tester.enterText(find.byType(TextField).at(2), '5678');
    await tester.pump();
    await _tapAction(tester, find.byType(AppPrimaryAction));

    expect(await lock.unlockWithPin('5678'), LockAttempt.unlocked);

    await tester.enterText(find.byType(TextField).at(0), '5678');
    await tester.pump();
    await _tapAction(tester, find.text(Copy.appLockRemove));

    expect(lock.isEnabled, isFalse);
    expect(backing.containsKey(SecretKey.pinHash), isFalse);
    expect(backing.containsKey(SecretKey.pinBackoff), isFalse);
    expect(find.text(Copy.appLockSet), findsWidgets);
    expect(find.text(Copy.appLockRecovery), findsOneWidget);
    expect(find.textContaining('wipe'), findsNothing);
  });

  testWidgets('after a wrong PIN the right PIN still opens the app', (
    WidgetTester tester,
  ) async {
    final _StepClock clock = _StepClock(DateTime.utc(2026, 9, 18, 8));
    final Map<SecretKey, String> backing = <SecretKey, String>{};
    await PinLock.fake(backing: backing, clock: clock).setPin('1234');
    final PinLock lock = PinLock.fake(backing: backing, clock: clock);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[networkOnlineOverride(), appLockOverride(lock)],
        child: const TaptureApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppLockScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField), '9999');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final Duration backoff = AppConstants.lock.backoff.first;
    expect(find.text(Copy.appLockWrongPin), findsOneWidget);
    expect(find.text(Copy.appLockWait(backoff)), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    expect(find.byType(AppLockScreen), findsOneWidget);

    // Let the backoff run out on both clocks; the wait line clears itself.
    clock.now = clock.now.add(backoff);
    await tester.pump(backoff);
    expect(find.text(Copy.appLockWait(backoff)), findsNothing);

    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text(Copy.appLockUnlock));
    await tester.pumpAndSettle();

    expect(find.byType(AppLockScreen), findsNothing);
    expect(find.byType(NavShell), findsOneWidget);
  });

  testWidgets('mismatched confirm PINs are not stored', (
    WidgetTester tester,
  ) async {
    final PinLock lock = PinLock.fake(backing: <SecretKey, String>{});
    await _pump(tester, lock);

    await tester.enterText(find.byType(TextField).at(0), '1234');
    await tester.enterText(find.byType(TextField).at(1), '9999');
    await tester.pump();
    await _tapAction(tester, find.byType(AppPrimaryAction));

    expect(find.text(Copy.appLockPinMismatch), findsWidgets);
    expect(lock.isEnabled, isFalse);
  });
}

/// A clock the test moves by hand, so a backoff can run out.
final class _StepClock implements Clock {
  _StepClock(this.now);

  DateTime now;

  @override
  DateTime nowUtc() => now.toUtc();

  @override
  DateTime today() => DateTime.utc(now.year, now.month, now.day);

  @override
  Duration get offset => Duration.zero;
}

Future<void> _tapAction(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pump(WidgetTester tester, AppLock lock) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 1400);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[appLockOverride(lock)],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const AppLockScreen.manage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byType(AppPage), findsOneWidget);
}

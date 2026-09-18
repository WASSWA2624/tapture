import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/security/secure_storage.dart';
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

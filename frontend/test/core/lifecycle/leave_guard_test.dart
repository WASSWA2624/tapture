import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/lifecycle/leave_guard.dart';

void main() {
  test('the fake holds while any owner holds', () {
    final LeaveGuard guard = LeaveGuard.fake();
    expect(guard.isHeld, isFalse);
    guard.hold(1);
    expect(guard.isHeld, isTrue);
    guard.release(1);
    expect(guard.isHeld, isFalse);
  });

  test('releasing one of two owners keeps the fake held', () {
    final LeaveGuard guard = LeaveGuard.fake();
    guard
      ..hold(1)
      ..hold(2);
    guard.release(1);
    expect(guard.isHeld, isTrue);
    guard.release(2);
    expect(guard.isHeld, isFalse);
  });

  test('the web leave prompt is wired through a conditional import', () {
    final String source = File(
      'lib/core/lifecycle/leave_guard.dart',
    ).readAsStringSync();
    expect(
      source.contains("if (dart.library.js_interop) 'leave_guard_web.dart'"),
      isTrue,
    );
    expect(
      File('lib/core/lifecycle/leave_guard_stub.dart').existsSync(),
      isTrue,
    );
    final String web = File(
      'lib/core/lifecycle/leave_guard_web.dart',
    ).readAsStringSync();
    expect(web.contains('beforeunload'), isTrue);
    expect(
      File('lib/main.dart').readAsStringSync().contains(
        'leaveGuardProvider.overrideWith((Ref _) => LeaveGuard())',
      ),
      isTrue,
    );
  });
}

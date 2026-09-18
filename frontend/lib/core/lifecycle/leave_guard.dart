import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'leave_guard_stub.dart'
    if (dart.library.io) 'leave_guard_stub.dart'
    if (dart.library.js_interop) 'leave_guard_web.dart'
    as platform;

/// The browser leave prompt, armed while any owner holds unsaved work.
///
/// Features never touch `window` (FE-STR-11); tests use [LeaveGuard.fake].
abstract interface class LeaveGuard {
  /// The service for this platform.
  factory LeaveGuard() => platform.platformLeaveGuard();

  /// A stand-in that records owners without touching the browser
  /// (FE-TEST-03).
  factory LeaveGuard.fake() = _FakeLeaveGuard;

  /// Starts showing the leave prompt for [owner].
  void hold(Object owner);

  /// Stops showing it when [owner] was the last holder.
  void release(Object owner);

  /// Whether any owner still needs the prompt.
  bool get isHeld;
}

final class _FakeLeaveGuard implements LeaveGuard {
  _FakeLeaveGuard();

  final Set<Object> _owners = <Object>{};

  @override
  void hold(Object owner) => _owners.add(owner);

  @override
  void release(Object owner) => _owners.remove(owner);

  @override
  bool get isHeld => _owners.isNotEmpty;
}

/// The process-wide leave guard. [main] replaces this with [LeaveGuard] so
/// the web listener is installed (FE-STR-11).
final Provider<LeaveGuard> leaveGuardProvider = Provider<LeaveGuard>((Ref _) {
  return LeaveGuard.fake();
});

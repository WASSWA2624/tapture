import 'leave_guard.dart';

/// Records owners only; native builds do not prompt on tab close.
LeaveGuard platformLeaveGuard() => LeaveGuard.fake();

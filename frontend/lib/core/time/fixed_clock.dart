part of 'clock.dart';

/// A clock frozen at one instant, for tests (FE-TEST-03).
final class FixedClock implements Clock {
  /// Freezes the clock at [now].
  const FixedClock(this._now, {this.offset = Duration.zero});

  final DateTime _now;

  @override
  final Duration offset;

  @override
  DateTime nowUtc() => _now.toUtc();

  @override
  DateTime today() => _today(nowUtc(), offset);
}

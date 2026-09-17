part of 'clock.dart';

/// The platform clock. The only type that may call [DateTime.now].
final class SystemClock implements Clock {
  /// Creates the platform clock.
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();

  @override
  DateTime today() => _today(nowUtc(), offset);

  @override
  Duration get offset => DateTime.now().timeZoneOffset;
}

DateTime _today(DateTime utc, Duration offset) {
  final DateTime local = utc.add(offset);
  return DateTime.utc(local.year, local.month, local.day);
}

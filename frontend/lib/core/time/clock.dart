part 'fixed_clock.dart';
part 'system_clock.dart';

/// The injectable clock every stamp and identifier is built on.
///
/// [DateTime.now] is called only inside [SystemClock]. Every other type
/// takes a [Clock] (FE-STR-11).
abstract interface class Clock {
  /// The current instant in UTC.
  DateTime nowUtc();

  /// The calendar date on this device (midnight UTC of that date).
  DateTime today();

  /// How far the device's zone is ahead of UTC.
  Duration get offset;
}

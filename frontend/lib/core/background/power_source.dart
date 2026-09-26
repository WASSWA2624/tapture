import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';

/// Whether the device is on mains power, for opportunistic on-device work.
///
/// The battery plugin is reached only here. Tests pass [PowerSource.fake] so
/// they never touch the platform (FE-STR-11, FE-TEST-03).
abstract interface class PowerSource {
  /// The platform battery. Where the platform cannot say, the device is
  /// treated as not charging, so nothing opportunistic runs.
  factory PowerSource() = _BatteryPowerSource;

  /// A stand-in that reports [charging].
  factory PowerSource.fake({required Stream<bool> charging}) = _FakePowerSource;

  /// Charging now, then each change, never the same value twice in a row.
  /// A full battery on the charger counts as charging.
  Stream<bool> watchCharging();
}

final class _BatteryPowerSource implements PowerSource {
  _BatteryPowerSource();

  final Battery _battery = Battery();

  @override
  Stream<bool> watchCharging() => _states().distinct();

  /// The state now, then every change the platform reports.
  Stream<bool> _states() async* {
    if (kIsWeb) {
      yield false;
      return;
    }
    try {
      yield _charging(await _battery.batteryState);
    } on Object {
      yield false;
      return;
    }
    try {
      yield* _battery.onBatteryStateChanged
          .map(_charging)
          .transform(_unknownIsOff);
    } on Object {
      return;
    }
  }
}

/// A change the platform could not report reads as not charging.
final StreamTransformer<bool, bool> _unknownIsOff =
    StreamTransformer<bool, bool>.fromHandlers(
      handleError: (Object _, StackTrace _, EventSink<bool> sink) {
        sink.add(false);
      },
    );

bool _charging(BatteryState state) {
  return state == BatteryState.charging || state == BatteryState.full;
}

final class _FakePowerSource implements PowerSource {
  _FakePowerSource({required this.charging});

  final Stream<bool> charging;

  @override
  Stream<bool> watchCharging() => charging;
}

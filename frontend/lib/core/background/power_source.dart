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

  /// A stand-in that reports [charging] as it changes, and [reading] when
  /// asked once: by default not charging, with no level and no saver.
  factory PowerSource.fake({
    required Stream<bool> charging,
    ({bool charging, int? percent, bool saver}) reading,
  }) = _FakePowerSource;

  /// Charging now, then each change, never the same value twice in a row.
  /// A full battery on the charger counts as charging.
  Stream<bool> watchCharging();

  /// The power state once: whether the device charges, its battery level in
  /// percent (null where the platform cannot say, as on a desktop without a
  /// battery or in a browser) and whether battery saver is on. Never fails:
  /// what the platform cannot report reads as not charging, no level and no
  /// saver.
  Future<({bool charging, int? percent, bool saver})> read();
}

/// What a platform that reports nothing reads as.
const ({bool charging, int? percent, bool saver}) _unknownPower = (
  charging: false,
  percent: null,
  saver: false,
);

final class _BatteryPowerSource implements PowerSource {
  _BatteryPowerSource();

  final Battery _battery = Battery();

  @override
  Stream<bool> watchCharging() => _states().distinct();

  @override
  Future<({bool charging, int? percent, bool saver})> read() async {
    if (kIsWeb) {
      return _unknownPower;
    }
    final bool charging = await _guard(
      () async => _charging(await _battery.batteryState),
      false,
    );
    final int? percent = await _guard<int?>(() async {
      final int level = await _battery.batteryLevel;
      return level >= 0 && level <= _fullPercent ? level : null;
    }, null);
    final bool saver = await _guard(() => _battery.isInBatterySaveMode, false);
    return (charging: charging, percent: percent, saver: saver);
  }

  /// [read]'s value, or [fallback] when the platform cannot say.
  static Future<T> _guard<T>(Future<T> Function() read, T fallback) async {
    try {
      return await read();
    } on Object {
      return fallback;
    }
  }

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

/// The highest battery level a platform reports.
const int _fullPercent = 100;

final class _FakePowerSource implements PowerSource {
  _FakePowerSource({required this.charging, this.reading = _unknownPower});

  final Stream<bool> charging;
  final ({bool charging, int? percent, bool saver}) reading;

  @override
  Stream<bool> watchCharging() => charging;

  @override
  Future<({bool charging, int? percent, bool saver})> read() async => reading;
}

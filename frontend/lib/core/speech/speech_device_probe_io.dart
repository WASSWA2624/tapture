import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:tapture/core/background/power_source.dart';
import 'package:tapture/core/errors/result.dart';

import 'speech_device_probe.dart';
import 'speech_device_profile.dart';
import 'speech_engine.dart';
import 'speech_runtime_facts.dart';
import 'speech_unavailable_reason.dart';

/// The probe of a device: the native runtime's facts, read by a one-shot
/// isolate inside [SpeechEngine.probe], and the battery.
SpeechDeviceProbe createSpeechDeviceProbe({
  required SpeechEngine engine,
  required PowerSource power,
}) => _NativeDeviceProbe(engine, power);

final class _NativeDeviceProbe implements SpeechDeviceProbe {
  _NativeDeviceProbe(this._engine, this._power);

  final SpeechEngine _engine;
  final PowerSource _power;

  @override
  Future<SpeechDeviceProfile> read() async {
    final (
      Result<SpeechRuntimeFacts> probed,
      ({bool charging, int? percent, bool saver}) power,
    ) = await (
      _engine.probe(),
      _power.read(),
    ).wait;
    return SpeechDeviceProfile(
      runtime: switch (probed) {
        Success<SpeechRuntimeFacts>(:final SpeechRuntimeFacts value) => value,
        // A runtime that cannot even be asked has no usable library.
        FailureResult<SpeechRuntimeFacts>() => const SpeechRuntimeFacts(
          available: false,
          unavailableReason: SpeechUnavailableReason.library,
          is64Bit: false,
          logicalCores: 0,
        ),
      },
      platform: defaultTargetPlatform,
      isWeb: false,
      charging: power.charging,
      batteryPercent: power.percent,
      batterySaver: power.saver,
    );
  }
}

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:tapture/core/background/power_source.dart';
import 'package:tapture/core/errors/result.dart';

import 'speech_device_probe.dart';
import 'speech_device_profile.dart';
import 'speech_engine.dart';
import 'speech_runtime_facts.dart';
import 'speech_unavailable_reason.dart';

/// The probe of a browser: what the page offers (memory, cores, isolation
/// for threads, SIMD), read on the page without starting a worker. A
/// browser's battery reading is unreliable and is not asked: power reads as
/// unknown, which never steps the model down.
SpeechDeviceProbe createSpeechDeviceProbe({
  required SpeechEngine engine,
  required PowerSource power,
}) => _BrowserDeviceProbe(engine);

final class _BrowserDeviceProbe implements SpeechDeviceProbe {
  _BrowserDeviceProbe(this._engine);

  final SpeechEngine _engine;

  @override
  Future<SpeechDeviceProfile> read() async {
    final Result<SpeechRuntimeFacts> probed = await _engine.probe();
    return SpeechDeviceProfile(
      runtime: switch (probed) {
        Success<SpeechRuntimeFacts>(:final SpeechRuntimeFacts value) => value,
        FailureResult<SpeechRuntimeFacts>() => const SpeechRuntimeFacts(
          available: false,
          unavailableReason: SpeechUnavailableReason.library,
          is64Bit: false,
          logicalCores: 0,
        ),
      },
      platform: defaultTargetPlatform,
      isWeb: true,
    );
  }
}

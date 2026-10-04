import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/background/power_source.dart';

import 'speech_device_probe_stub.dart'
    if (dart.library.io) 'speech_device_probe_io.dart'
    if (dart.library.js_interop) 'speech_device_probe_web.dart'
    as platform;
import 'speech_device_profile.dart';
import 'speech_engine.dart';

/// Reads what model selection needs to know about this device, without
/// loading a model or starting a speech worker (spec §30.4.2).
abstract interface class SpeechDeviceProbe {
  /// The probe of this platform: [engine]'s runtime facts and [power]'s
  /// reading on a device; the browser's facts and no battery in a browser.
  factory SpeechDeviceProbe.platform({
    required SpeechEngine engine,
    required PowerSource power,
  }) => platform.createSpeechDeviceProbe(engine: engine, power: power);

  /// A stand-in that always reads [profile] (FE-TEST-03).
  const factory SpeechDeviceProbe.fake(SpeechDeviceProfile profile) =
      _FakeSpeechDeviceProbe;

  /// The device now. Never fails: a runtime that cannot be asked reads as
  /// unavailable, and power the platform cannot report reads as unknown.
  Future<SpeechDeviceProfile> read();
}

/// The app's device probe: over [speechEngineProvider] with no battery
/// until `main` overrides it with the platform's [PowerSource], so a suite
/// never reaches the battery plugin (FE-TEST-03).
final Provider<SpeechDeviceProbe> speechDeviceProbeProvider =
    Provider<SpeechDeviceProbe>(
      (Ref ref) => SpeechDeviceProbe.platform(
        engine: ref.watch(speechEngineProvider),
        power: PowerSource.fake(charging: const Stream<bool>.empty()),
      ),
    );

final class _FakeSpeechDeviceProbe implements SpeechDeviceProbe {
  const _FakeSpeechDeviceProbe(this._profile);

  final SpeechDeviceProfile _profile;

  @override
  Future<SpeechDeviceProfile> read() async => _profile;
}

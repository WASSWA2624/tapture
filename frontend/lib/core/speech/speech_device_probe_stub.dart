import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:tapture/core/background/power_source.dart';

import 'speech_device_probe.dart';
import 'speech_device_profile.dart';
import 'speech_engine.dart';
import 'speech_runtime_facts.dart';
import 'speech_unavailable_reason.dart';

/// A platform with neither files nor a browser has no speech engine: the
/// probe says so without asking anything.
SpeechDeviceProbe createSpeechDeviceProbe({
  required SpeechEngine engine,
  required PowerSource power,
}) => SpeechDeviceProbe.fake(
  SpeechDeviceProfile(
    runtime: const SpeechRuntimeFacts(
      available: false,
      unavailableReason: SpeechUnavailableReason.platform,
      is64Bit: false,
      logicalCores: 0,
    ),
    platform: defaultTargetPlatform,
    isWeb: false,
  ),
);

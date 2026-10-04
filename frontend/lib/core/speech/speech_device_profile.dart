import 'package:flutter/foundation.dart' show TargetPlatform;

import 'speech_runtime_facts.dart';

/// Everything model selection weighs about this device at one moment: what
/// the speech runtime offers, which platform it is and how it is powered.
final class SpeechDeviceProfile {
  /// Describes the device. [batteryPercent] is null where the platform cannot
  /// say, as on a desktop without a battery or in a browser.
  const SpeechDeviceProfile({
    required this.runtime,
    required this.platform,
    required this.isWeb,
    this.charging = false,
    this.batteryPercent,
    this.batterySaver = false,
  });

  /// Processor, memory, versions, browser threads and SIMD.
  final SpeechRuntimeFacts runtime;

  /// The operating system the app runs on, in a browser too.
  final TargetPlatform platform;

  /// Whether the app runs in a browser.
  final bool isWeb;

  /// Whether the device is on mains power; a full battery on the charger
  /// counts.
  final bool charging;

  /// Battery level in percent, or null when unknown.
  final int? batteryPercent;

  /// Whether the operating system's battery saver is on.
  final bool batterySaver;

  /// Whether this is a phone or tablet app rather than a desktop or a
  /// browser: Android and iOS outside a browser.
  bool get isMobile =>
      !isWeb &&
      (platform == TargetPlatform.android || platform == TargetPlatform.iOS);

  /// Whether this is a desktop app: neither a phone nor a browser.
  bool get isDesktop => !isWeb && !isMobile;
}

/// How the operator trades speed for accuracy in on-device speech: the only
/// speech choice the settings expose (spec §30.4.2). The device decides the
/// rest, so no model or thread count is ever picked by hand.
enum SpeechQuality {
  /// The device's best fit: the balanced model where memory, cores and
  /// power allow, otherwise the fast one.
  auto,

  /// Always the fast model, kindest to the battery.
  fast,

  /// The largest model the device can hold, while power allows.
  accurate;

  /// The quality stored as [wire]; anything unknown is [auto].
  static SpeechQuality parse(String wire) {
    for (final SpeechQuality quality in values) {
      if (quality.name == wire) {
        return quality;
      }
    }
    return auto;
  }
}

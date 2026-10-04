/// One voice-activity detector opened for one lease, so the detector's
/// running state never crosses from one session into another.
final class SpeechVadHandle {
  /// Names the detector [id] that reads [frameSamples] samples per frame.
  const SpeechVadHandle({required this.id, required this.frameSamples});

  /// The engine's identifier for this detector.
  final int id;

  /// Samples per frame; every batch must hold a whole number of frames.
  final int frameSamples;

  @override
  bool operator ==(Object other) =>
      other is SpeechVadHandle &&
      other.id == id &&
      other.frameSamples == frameSamples;

  @override
  int get hashCode => Object.hash(id, frameSamples);
}

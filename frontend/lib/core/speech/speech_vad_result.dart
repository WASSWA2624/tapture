import 'dart:typed_data';

/// Speech probabilities for one batch of whole frames.
final class SpeechVadResult {
  /// Holds one probability per frame of [frameSamples] samples.
  const SpeechVadResult({
    required this.probabilities,
    required this.frameSamples,
  });

  /// The probability, from 0 to 1, that each frame holds speech.
  final Float32List probabilities;

  /// Samples per frame.
  final int frameSamples;
}

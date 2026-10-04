import 'dart:typed_data';

/// A run of 16 kHz mono samples at its place on the take's timeline.
///
/// The timeline counts samples, so paused time does not exist on it.
final class PcmChunk {
  /// [samples] starting at sample [startSample] of the take.
  const PcmChunk(this.startSample, this.samples);

  /// Index of the first sample on the take's timeline.
  final int startSample;

  /// The samples, 16-bit signed.
  final Int16List samples;

  /// Index one past the last sample.
  int get endSample => startSample + samples.length;
}

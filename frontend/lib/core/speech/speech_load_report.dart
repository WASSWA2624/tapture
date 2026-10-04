import 'speech_model_entry.dart';
import 'speech_model_shape.dart';

/// What a successful model load produced.
final class SpeechLoadReport {
  /// Reports that [model] loaded with [shape] on [threads] threads.
  const SpeechLoadReport({
    required this.model,
    required this.shape,
    required this.threads,
    required this.loadTime,
  });

  /// The catalogue entry that was loaded.
  final SpeechModelEntry model;

  /// The hyperparameters the engine read.
  final SpeechModelShape shape;

  /// Threads each decode uses.
  final int threads;

  /// Wall time of the load, including the in-engine SHA-256 check.
  final Duration loadTime;
}

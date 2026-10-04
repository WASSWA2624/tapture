import 'speech_model_entry.dart';

/// What this device holds of one catalogue model, found without hashing.
final class SpeechModelStatus {
  /// Describes [entry] on this device.
  const SpeechModelStatus({
    required this.entry,
    required this.present,
    this.imported = false,
    this.damaged = false,
  });

  /// The catalogue model this status describes.
  final SpeechModelEntry entry;

  /// Whether a file for [entry] is in this build or was imported.
  final bool present;

  /// Whether the file is an imported copy, which the operator may remove.
  final bool imported;

  /// Whether the file failed a check this session, or has the wrong size.
  final bool damaged;
}

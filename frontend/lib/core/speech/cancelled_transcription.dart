/// What a cancelled live transcription session leaves behind (spec
/// §30.4.5): no transcript, and its audio kept unpublished (§8.1 rule 1).
final class CancelledTranscription {
  /// A session cancelled after [captured] of audio, whose staged take is
  /// kept at [keptStagingPath].
  const CancelledTranscription({
    required this.keptStagingPath,
    required this.captured,
  });

  /// The staged take kept byte-for-byte, or null when nothing was staged
  /// (memory-only dictation, or a take already published).
  final String? keptStagingPath;

  /// How much audio was captured before the cancel.
  final Duration captured;
}

/// How many native objects of each kind are alive in this process
/// (`tw_live_objects`), counted across every isolate.
final class WhisperLiveObjects {
  /// Describes the counters.
  const WhisperLiveObjects({
    required this.contexts,
    required this.results,
    required this.vads,
    required this.spans,
    required this.cells,
    required this.hashers,
  });

  /// Open whisper models.
  final int contexts;

  /// Transcription results not yet freed.
  final int results;

  /// Open VAD handles.
  final int vads;

  /// Span lists not yet freed.
  final int spans;

  /// Abort cells with a reference left.
  final int cells;

  /// Streaming SHA-256 hashers not yet finished.
  final int hashers;

  /// Every counter added up; 0 when nothing native is alive.
  int get total => contexts + results + vads + spans + cells + hashers;

  @override
  String toString() =>
      'WhisperLiveObjects(contexts: $contexts, results: $results, '
      'vads: $vads, spans: $spans, cells: $cells, hashers: $hashers)';
}

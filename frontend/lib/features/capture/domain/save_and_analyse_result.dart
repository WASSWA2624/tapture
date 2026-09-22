part of 'save_and_analyse.dart';

/// Outcome of capture-and-analyse.
final class SaveAndAnalyseResult {
  /// Creates a result.
  const SaveAndAnalyseResult({
    required this.recordId,
    this.enqueueFailed = false,
  });

  /// Durable record id.
  final String recordId;

  /// True when the record is saved but the job needs a retry.
  final bool enqueueFailed;
}

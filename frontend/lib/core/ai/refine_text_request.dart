part of 'ai_service.dart';

/// Raw text to reword, and the kind of text it is.
final class RefineTextRequest {
  /// Creates a refine request. [raw] is quoted data, never an instruction.
  const RefineTextRequest({
    required this.raw,
    required this.style,
    this.cancellationToken,
    this.projectRevision = '',
    this.recordId = '',
    this.idempotencyKey = '',
    this.approvedMaxCost,
  });

  /// The original caption or minutes, quoted as data.
  final String raw;

  /// Whether [raw] is a caption or meeting minutes.
  final RefineStyle style;

  /// Stops additional refinement calls after cancellation.
  final CancellationToken? cancellationToken;

  /// Content and account snapshot used by durable processing calls.
  final String projectRevision;

  /// Local record identity sent for permission and usage attribution.
  final String recordId;

  /// Stable dispatch identity retained across a crashed attempt.
  final String idempotencyKey;

  /// Frozen spending ceiling; zero uses the server's configured default limit.
  final double? approvedMaxCost;
}

/// The kind of text [RefineTextRequest] carries.
enum RefineStyle {
  /// A captured photo or record caption.
  caption,

  /// Meeting minutes or a long spoken note.
  minutes,
}

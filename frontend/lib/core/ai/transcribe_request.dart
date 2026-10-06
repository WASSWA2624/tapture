part of 'ai_service.dart';

/// A spoken clip to turn into text.
final class TranscribeRequest {
  /// Creates a transcribe request.
  const TranscribeRequest({
    required this.clipPath,
    required this.languageCode,
    this.cancellationToken,
    this.projectRevision = '',
    this.recordId = '',
    this.idempotencyKey = '',
    this.approvedMaxCost,
  });

  /// Path of the saved audio file. The file is not rewritten here.
  final String clipPath;

  /// BCP-47 language the clip is expected to be in.
  final String languageCode;

  /// Stops preparation before any further audio leaves the device.
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

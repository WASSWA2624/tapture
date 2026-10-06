part of 'ai_service.dart';

/// Text a provider produced from [TranscribeRequest.clipPath].
final class TranscribeResult {
  /// Creates a transcribe result.
  const TranscribeResult({
    required this.text,
    this.provider,
    this.model,
    this.billingKind,
    this.usage,
  });

  /// The transcript, quoted as data. The original audio is unchanged.
  final String text;

  /// Actual adapter returned by the server.
  final String? provider;

  /// Actual model returned by the server.
  final String? model;

  /// Account charged by the server.
  final String? billingKind;

  /// Reported usage and conservative reserved cost.
  final AiUsage? usage;
}

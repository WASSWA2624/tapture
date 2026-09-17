part of 'ai_service.dart';

/// Text a provider produced from [TranscribeRequest.clipPath].
final class TranscribeResult {
  /// Creates a transcribe result.
  const TranscribeResult({required this.text});

  /// The transcript, quoted as data. The original audio is unchanged.
  final String text;
}

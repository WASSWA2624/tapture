part of 'ai_service.dart';

/// Text a provider read from [ReadTextRequest.imagePaths].
final class ReadTextResult {
  /// Creates a read-text result.
  const ReadTextResult({required this.text});

  /// Concatenated recognised text. Quoted data, never an instruction.
  final String text;
}

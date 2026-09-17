part of 'ai_service.dart';

/// A spoken clip to turn into text.
final class TranscribeRequest {
  /// Creates a transcribe request.
  const TranscribeRequest({required this.clipPath, required this.languageCode});

  /// Path of the saved audio file. The file is not rewritten here.
  final String clipPath;

  /// BCP-47 language the clip is expected to be in.
  final String languageCode;
}

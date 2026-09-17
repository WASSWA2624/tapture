part of 'ai_service.dart';

/// Raw text to reword, and the kind of text it is.
final class RefineTextRequest {
  /// Creates a refine request. [raw] is quoted data, never an instruction.
  const RefineTextRequest({required this.raw, required this.style});

  /// The original caption or minutes, quoted as data.
  final String raw;

  /// Whether [raw] is a caption or meeting minutes.
  final RefineStyle style;
}

/// The kind of text [RefineTextRequest] carries.
enum RefineStyle {
  /// A captured photo or record caption.
  caption,

  /// Meeting minutes or a long spoken note.
  minutes,
}

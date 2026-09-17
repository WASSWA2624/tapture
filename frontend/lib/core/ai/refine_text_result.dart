part of 'ai_service.dart';

/// A rewording of [RefineTextRequest.raw] that adds no new fact.
final class RefineTextResult {
  /// Creates a refine result.
  const RefineTextResult({required this.text});

  /// The cleaned text. The original stays where it was written.
  final String text;
}

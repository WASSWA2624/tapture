part of 'ai_service.dart';

/// A rewording of [RefineTextRequest.raw] that adds no new fact.
final class RefineTextResult {
  /// Creates a refine result.
  const RefineTextResult({
    required this.text,
    this.rawResponse,
    this.provider,
    this.model,
    this.promptVersion,
  });

  /// The cleaned text. The original stays where it was written.
  final String text;

  /// Provider response exactly as received, before validation.
  final String? rawResponse;

  /// Provider id used for provenance.
  final String? provider;

  /// Model id used for provenance.
  final String? model;

  /// Prompt contract version used for provenance.
  final String? promptVersion;
}

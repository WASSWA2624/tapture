part of 'ai_service.dart';

/// Proposed field values from one extraction call.
///
/// Values here are proposals. A caller never writes them as approved.
final class ExtractFieldsResult {
  /// Creates an extraction result.
  const ExtractFieldsResult({
    required this.fields,
    this.rawResponse,
    this.provider,
    this.model,
    this.promptVersion,
  });

  /// Field key to proposed value. Absent or unknown fields are omitted or
  /// null; an implementation never guesses.
  final Map<String, String?> fields;

  /// Provider response exactly as received, before parsing or repair.
  final String? rawResponse;

  /// Provider id used for provenance.
  final String? provider;

  /// Model id used for provenance.
  final String? model;

  /// Prompt contract version used for provenance.
  final String? promptVersion;
}

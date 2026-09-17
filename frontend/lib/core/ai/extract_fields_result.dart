part of 'ai_service.dart';

/// Proposed field values from one extraction call.
///
/// Values here are proposals. A caller never writes them as approved.
final class ExtractFieldsResult {
  /// Creates an extraction result.
  const ExtractFieldsResult({required this.fields});

  /// Field key to proposed value. Absent or unknown fields are omitted or
  /// null; an implementation never guesses.
  final Map<String, String?> fields;
}

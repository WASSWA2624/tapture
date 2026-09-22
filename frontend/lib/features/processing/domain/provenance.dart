/// Where a proposed value came from, and how it was made.
final class Provenance {
  /// Builds the stamp stored on the value and copied to the audit row.
  static ProvenanceStamp stamp({
    required String source,
    required String method,
    required String provider,
    required String model,
    required String promptVersion,
  }) {
    return (
      source: source,
      method: method,
      provider: provider,
      model: model,
      promptVersion: promptVersion,
    );
  }

  /// The same stamp as audit columns.
  static Map<String, String> asAudit(ProvenanceStamp stamp) {
    return <String, String>{
      'source': stamp.source,
      'method': stamp.method,
      'provider': stamp.provider,
      'model': stamp.model,
      'promptVersion': stamp.promptVersion,
    };
  }
}

/// Source, method, provider, model and prompt version.
typedef ProvenanceStamp = ({
  String source,
  String method,
  String provider,
  String model,
  String promptVersion,
});

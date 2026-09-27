/// One record detection compares against. Pure data, nothing written.
final class DuplicateSubject {
  /// Creates a subject.
  const DuplicateSubject({
    required this.recordId,
    required this.identityHash,
    this.photoHashes = const <String>{},
    this.perceptualHashes = const <String>{},
    this.templateRowId,
    this.context = const <String, String>{},
    this.name = '',
    this.capturedAt,
  });

  /// The record.
  final String recordId;

  /// Stored identity hash.
  final String identityHash;

  /// Content hashes of its photos.
  final Set<String> photoHashes;

  /// Perceptual hashes of its photos.
  final Set<String> perceptualHashes;

  /// Predefined template row, when the record was captured from one.
  final String? templateRowId;

  /// Context snapshot.
  final Map<String, String> context;

  /// Display name.
  final String name;

  /// When it was captured.
  final DateTime? capturedAt;
}

part of 'orphan_scanner.dart';

/// A photo or attachment row whose file is not on disk.
final class MissingFile {
  /// Creates a missing-file finding.
  const MissingFile({
    required this.entityType,
    required this.id,
    required this.expectedPath,
  });

  /// `photos` or `attachments`.
  final String entityType;

  /// Merge id of the row.
  final String id;

  /// Project-relative path the row still names.
  final String expectedPath;
}

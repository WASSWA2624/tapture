part of 'orphan_scanner.dart';

/// Both directions of a project-folder scan: files with no row, and rows
/// with no file.
final class OrphanReport {
  /// Creates a report. The scan never deletes or moves anything.
  const OrphanReport({
    required this.filesWithoutRows,
    required this.rowsWithoutFiles,
    required this.reclaimableBytes,
  });

  /// Disk files that no photo or attachment row names.
  final List<OrphanFile> filesWithoutRows;

  /// Rows whose expected file is absent.
  final List<MissingFile> rowsWithoutFiles;

  /// Sum of [filesWithoutRows] byte sizes.
  final int reclaimableBytes;
}

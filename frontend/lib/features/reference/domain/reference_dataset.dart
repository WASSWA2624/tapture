/// An imported table used to prefill a record.
final class ReferenceDataset {
  /// Creates a dataset. [columns] stay in import order for a later export.
  const ReferenceDataset({
    required this.id,
    required this.name,
    required this.keyColumn,
    required this.columns,
    required this.source,
    required this.importedAt,
    required this.rowCount,
    this.duplicatesAllowed = false,
    this.projectId,
    this.sourceFile = '',
  });

  /// Stable merge id.
  final String id;

  /// Operator-facing name.
  final String name;

  /// Column used as the lookup key.
  final String keyColumn;

  /// Column names in import order.
  final List<String> columns;

  /// How the dataset arrived on the device.
  final DatasetSource source;

  /// When this import was written.
  final DateTime importedAt;

  /// Number of rows currently stored.
  final int rowCount;

  /// Whether a non-unique key was confirmed at import.
  final bool duplicatesAllowed;

  /// Owning project when scoped; null for a global dataset.
  final String? projectId;

  /// Source path or name used for re-import matching.
  final String sourceFile;

  /// Returns a copy with the provided fields replaced.
  ReferenceDataset copyWith({
    String? id,
    String? name,
    String? keyColumn,
    List<String>? columns,
    DatasetSource? source,
    DateTime? importedAt,
    int? rowCount,
    bool? duplicatesAllowed,
    String? projectId,
    String? sourceFile,
    bool clearProjectId = false,
  }) {
    return ReferenceDataset(
      id: id ?? this.id,
      name: name ?? this.name,
      keyColumn: keyColumn ?? this.keyColumn,
      columns: columns ?? this.columns,
      source: source ?? this.source,
      importedAt: importedAt ?? this.importedAt,
      rowCount: rowCount ?? this.rowCount,
      duplicatesAllowed: duplicatesAllowed ?? this.duplicatesAllowed,
      projectId: clearProjectId ? null : (projectId ?? this.projectId),
      sourceFile: sourceFile ?? this.sourceFile,
    );
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    keyColumn,
    Object.hashAll(columns),
    source,
    importedAt,
    rowCount,
    duplicatesAllowed,
    projectId,
    sourceFile,
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ReferenceDataset &&
            other.id == id &&
            other.name == name &&
            other.keyColumn == keyColumn &&
            _listEquals(other.columns, columns) &&
            other.source == source &&
            other.importedAt == importedAt &&
            other.rowCount == rowCount &&
            other.duplicatesAllowed == duplicatesAllowed &&
            other.projectId == projectId &&
            other.sourceFile == sourceFile);
  }
}

/// How a [ReferenceDataset] arrived on the device.
enum DatasetSource {
  /// Parsed from a comma- or semicolon-delimited file.
  csv,

  /// Parsed from a spreadsheet workbook.
  xlsx,

  /// Parsed from a JSON array of objects.
  json,

  /// Created or extended on this device without a file.
  device,
}

bool _listEquals(List<String> left, List<String> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (int i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

/// A predefined checklist row on a template, with aliases for local names.
final class TemplateRow {
  /// Creates a checklist row. [outputRowNumber] is the original spreadsheet
  /// line, kept for write-back.
  const TemplateRow({
    required this.identifier,
    required this.label,
    required this.outputRowNumber,
    this.aliases = const <String>[],
    this.metadata = const <String, Object?>{},
    this.foundStatus = 'missing',
  });

  /// Stable identifier within the template.
  final String identifier;

  /// Operator-facing label, stored as data.
  final String label;

  /// Original spreadsheet row number, kept for write-back.
  final int outputRowNumber;

  /// Local names that should match this row.
  final List<String> aliases;

  /// Extra row attributes imported with the sheet.
  final Map<String, Object?> metadata;

  /// Found / missing status for the capture checklist.
  final String foundStatus;

  /// Returns a copy with the provided fields replaced.
  TemplateRow copyWith({
    String? identifier,
    String? label,
    int? outputRowNumber,
    List<String>? aliases,
    Map<String, Object?>? metadata,
    String? foundStatus,
  }) {
    return TemplateRow(
      identifier: identifier ?? this.identifier,
      label: label ?? this.label,
      outputRowNumber: outputRowNumber ?? this.outputRowNumber,
      aliases: aliases ?? this.aliases,
      metadata: metadata ?? this.metadata,
      foundStatus: foundStatus ?? this.foundStatus,
    );
  }

  @override
  int get hashCode => Object.hash(
    identifier,
    label,
    outputRowNumber,
    Object.hashAll(aliases),
    Object.hashAll(
      metadata.entries.map(
        (MapEntry<String, Object?> e) => Object.hash(e.key, e.value),
      ),
    ),
    foundStatus,
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TemplateRow &&
            other.identifier == identifier &&
            other.label == label &&
            other.outputRowNumber == outputRowNumber &&
            _listEquals(other.aliases, aliases) &&
            _mapEquals(other.metadata, metadata) &&
            other.foundStatus == foundStatus);
  }
}

bool _listEquals(List<String> left, List<String> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (int index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

bool _mapEquals(Map<String, Object?> left, Map<String, Object?> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (final MapEntry<String, Object?> entry in left.entries) {
    if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

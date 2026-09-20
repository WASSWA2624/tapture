import 'field_def.dart';
import 'template_row.dart';

/// Shape of a record: identity, fields, predefined rows and version.
///
/// Presentation reaches templates only through this type and
/// [TemplateRepository]; never a DAO or Drift row (FE-STATE-05).
final class TemplateDef {
  /// Creates a template. [id] is empty until the first save.
  const TemplateDef({
    required this.id,
    required this.templateKey,
    required this.name,
    required this.version,
    required this.fields,
    required this.identityFieldKeys,
    required this.rows,
    this.projectId,
    this.kind = '',
    this.source = 'built',
    this.sourceFilePath,
    this.sheetName,
    this.headerRow,
    this.detection = const <String, Object?>{},
  });

  /// Merge identity. Stable across a rename.
  final String id;

  /// Stable key, for example `equipment_asset`. Distinct from [kind].
  final String templateKey;

  /// Operator-facing name.
  final String name;

  /// Structural version. Captured records keep the value they were taken at.
  final int version;

  /// Columns, in list order.
  final List<FieldDef> fields;

  /// Field keys that identify a record for duplicate detection.
  final List<String> identityFieldKeys;

  /// Predefined checklist rows, with aliases.
  final List<TemplateRow> rows;

  /// Owning project, or null when this is a shipped template.
  final String? projectId;

  /// Kind of thing this template captures, stored as data.
  final String kind;

  /// Where the template came from: shipped, imported or built.
  final String source;

  /// Imported workbook path, when [source] is an import.
  final String? sourceFilePath;

  /// Imported sheet name, stored as data.
  final String? sheetName;

  /// 1-based header row in the imported sheet, when known.
  final int? headerRow;

  /// Detection profile. [templateKey] is stored beside this, not inside it.
  final Map<String, Object?> detection;

  /// Returns a copy with the provided fields replaced.
  TemplateDef copyWith({
    String? id,
    String? templateKey,
    String? name,
    int? version,
    List<FieldDef>? fields,
    List<String>? identityFieldKeys,
    List<TemplateRow>? rows,
    String? projectId,
    String? kind,
    String? source,
    String? sourceFilePath,
    String? sheetName,
    int? headerRow,
    Map<String, Object?>? detection,
  }) {
    return TemplateDef(
      id: id ?? this.id,
      templateKey: templateKey ?? this.templateKey,
      name: name ?? this.name,
      version: version ?? this.version,
      fields: fields ?? this.fields,
      identityFieldKeys: identityFieldKeys ?? this.identityFieldKeys,
      rows: rows ?? this.rows,
      projectId: projectId ?? this.projectId,
      kind: kind ?? this.kind,
      source: source ?? this.source,
      sourceFilePath: sourceFilePath ?? this.sourceFilePath,
      sheetName: sheetName ?? this.sheetName,
      headerRow: headerRow ?? this.headerRow,
      detection: detection ?? this.detection,
    );
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateKey,
    name,
    version,
    Object.hashAll(fields),
    Object.hashAll(identityFieldKeys),
    Object.hashAll(rows),
    projectId,
    kind,
    source,
    sourceFilePath,
    sheetName,
    headerRow,
    Object.hashAll(
      detection.entries.map(
        (MapEntry<String, Object?> e) => Object.hash(e.key, e.value),
      ),
    ),
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TemplateDef &&
            other.id == id &&
            other.templateKey == templateKey &&
            other.name == name &&
            other.version == version &&
            _listEquals(other.fields, fields) &&
            _listEquals(other.identityFieldKeys, identityFieldKeys) &&
            _listEquals(other.rows, rows) &&
            other.projectId == projectId &&
            other.kind == kind &&
            other.source == source &&
            other.sourceFilePath == sourceFilePath &&
            other.sheetName == sheetName &&
            other.headerRow == headerRow &&
            _mapEquals(other.detection, detection));
  }
}

bool _listEquals<T>(List<T> left, List<T> right) {
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

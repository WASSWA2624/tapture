/// Captured output mapping kept with a replayable export, independently of edits.
final class ExportOutputTemplate {
  /// Creates one immutable source document and its confirmed field/row mapping.
  const ExportOutputTemplate({
    required this.templateId,
    required this.templateVersion,
    required this.sourcePath,
    required this.kind,
    this.sourceHash = '',
    this.sheetName,
    this.headerRow = 1,
    this.columns = const <String, String>{},
    this.rows = const <String, int>{},
  });

  /// Restores a stored output contract without querying the current template.
  factory ExportOutputTemplate.fromJson(Map<String, Object?> json) =>
      ExportOutputTemplate(
        templateId: json['templateId'] as String,
        templateVersion: json['templateVersion'] as String,
        sourcePath: json['sourcePath'] as String,
        kind: json['kind'] as String,
        sourceHash: json['sourceHash'] as String? ?? '',
        sheetName: json['sheetName'] as String?,
        headerRow: json['headerRow'] as int? ?? 1,
        columns: json['columns'] is Map
            ? Map<String, String>.from(json['columns']! as Map)
            : const <String, String>{},
        rows: json['rows'] is Map
            ? Map<String, int>.from(json['rows']! as Map)
            : const <String, int>{},
      );

  /// Record shape this source belongs to.
  final String templateId;

  /// Captured version of that shape.
  final String templateVersion;

  /// Immutable copied source, relative to local storage.
  final String sourcePath;

  /// Source SHA-256, when recorded by the importer.
  final String sourceHash;

  /// Source document type: `xlsx`, `docx` or `txt`.
  final String kind;

  /// Confirmed workbook tab, including its original spelling.
  final String? sheetName;

  /// First row is one; data follows the original header.
  final int headerRow;

  /// Field keys to original Excel column letters.
  final Map<String, String> columns;

  /// Predefined row IDs to original workbook row numbers.
  final Map<String, int> rows;

  /// Stable identity used by sources and file naming.
  String get key => '$templateId@$templateVersion';

  /// Every source and mapping field, for exact request replay.
  Map<String, Object?> toJson() => <String, Object?>{
    'templateId': templateId,
    'templateVersion': templateVersion,
    'sourcePath': sourcePath,
    'sourceHash': sourceHash,
    'kind': kind,
    'sheetName': sheetName,
    'headerRow': headerRow,
    'columns': columns,
    'rows': rows,
  };
}

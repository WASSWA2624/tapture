import 'export_record.dart';
import 'value_formatter.dart';

/// One serialisable export. A stored request replays the same files.
final class ExportRequest {
  /// Creates a request. [files] is the resolved output list.
  const ExportRequest({
    required this.projectId,
    required this.formats,
    required this.scope,
    required this.columns,
    required this.extras,
    this.markedIncomplete = false,
    this.files = const <ExportFile>[],
    this.records = const <ExportRecord>[],
  });

  /// Rebuilds a request written by [toJson].
  factory ExportRequest.fromJson(Map<String, Object?> json) {
    return ExportRequest(
      projectId: json['projectId'] as String? ?? '',
      formats: <ExportFormat>{
        for (final Object? name in _list(json['formats']))
          if (name is String)
            ExportFormat.values.firstWhere(
              (ExportFormat format) => format.name == name,
              orElse: () => ExportFormat.xlsx,
            ),
      },
      scope: _scope(json['scope']),
      columns: _columns(json['columns']),
      extras: _extras(json['extras']),
      markedIncomplete: json['markedIncomplete'] == true,
      files: <ExportFile>[
        for (final Object? row in _list(json['files']))
          if (row is Map)
            (
              path: Map<String, Object?>.from(row)['path'] as String? ?? '',
              role: Map<String, Object?>.from(row)['role'] as String? ?? '',
            ),
      ],
      records: <ExportRecord>[
        for (final Object? row in _list(json['records']))
          if (row is Map) ExportRecord.fromJson(Map<String, Object?>.from(row)),
      ],
    );
  }

  /// Project being exported.
  final String projectId;

  /// Formats to write.
  final Set<ExportFormat> formats;

  /// Which records are in scope.
  final ExportScope scope;

  /// Column choices. Refined defaults on.
  final ExportColumns columns;

  /// Extras, photo mode and delimiter.
  final ExportExtras extras;

  /// Set when the operator exported despite incomplete records.
  final bool markedIncomplete;

  /// Output files this request resolved to.
  final List<ExportFile> files;

  /// Records the writers emit. Stored so a replay needs no new query.
  final List<ExportRecord> records;

  /// JSON covering every field, including [files] and [records].
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'projectId': projectId,
      'formats': <String>[
        for (final ExportFormat format in ExportFormat.values)
          if (formats.contains(format)) format.name,
      ],
      'scope': <String, Object?>{
        'kind': scope.kind.name,
        'context': scope.context,
        'from': scope.from,
        'to': scope.to,
        'filter': scope.filter,
      },
      'columns': <String, Object?>{
        'raw': columns.raw,
        'refined': columns.refined,
        'confidence': columns.confidence,
        'evidence': columns.evidence,
      },
      'extras': <String, Object?>{
        'dictionary': extras.dictionary,
        'photoIndex': extras.photoIndex,
        'photoMode': extras.photoMode,
        'delimiter': extras.delimiter,
      },
      'markedIncomplete': markedIncomplete,
      'files': <Map<String, Object?>>[
        for (final ExportFile file in files)
          <String, Object?>{'path': file.path, 'role': file.role},
      ],
      'records': <Map<String, Object?>>[
        for (final ExportRecord record in records) record.toJson(),
      ],
    };
  }

  /// The same request with [markedIncomplete] set.
  ExportRequest copyWith({
    List<ExportRecord>? records,
    List<ExportFile>? files,
  }) {
    return ExportRequest(
      projectId: projectId,
      formats: formats,
      scope: scope,
      columns: columns,
      extras: extras,
      markedIncomplete: markedIncomplete,
      records: records ?? this.records,
      files: files ?? this.files,
    );
  }

  /// The same request with [markedIncomplete] set.
  ExportRequest markIncomplete() {
    return ExportRequest(
      projectId: projectId,
      formats: formats,
      scope: scope,
      columns: columns,
      extras: extras,
      markedIncomplete: true,
      files: files,
      records: records,
    );
  }

  /// Drops records whose ids are in [excluded].
  ExportRequest without(Set<String> excluded) {
    return ExportRequest(
      projectId: projectId,
      formats: formats,
      scope: scope,
      columns: columns,
      extras: extras,
      markedIncomplete: markedIncomplete,
      files: files,
      records: <ExportRecord>[
        for (final ExportRecord record in records)
          if (!excluded.contains(record.id)) record,
      ],
    );
  }
}

/// Which records an export selects.
enum ExportScopeKind {
  /// Approved records only.
  approved,

  /// Every record.
  all,

  /// The current context subtree.
  context,

  /// A date range.
  dateRange,

  /// The current records filter.
  filter,
}

/// Scope of an [ExportRequest]. Dates are already normalised strings.
typedef ExportScope = ({
  ExportScopeKind kind,
  String? context,
  String? from,
  String? to,
  Map<String, Object?>? filter,
});

/// Column switches. Refined defaults on.
typedef ExportColumns = ({
  bool raw,
  bool refined,
  bool confidence,
  bool evidence,
});

/// Extras under the advanced group.
typedef ExportExtras = ({
  bool dictionary,
  bool photoIndex,
  String photoMode,
  String delimiter,
});

/// One resolved output path.
typedef ExportFile = ({String path, String role});

ExportScope _scope(Object? raw) {
  final Map<String, Object?> json = raw is Map
      ? Map<String, Object?>.from(raw)
      : <String, Object?>{};
  final Object? filter = json['filter'];
  return (
    kind: ExportScopeKind.values.firstWhere(
      (ExportScopeKind kind) => kind.name == json['kind'],
      orElse: () => ExportScopeKind.approved,
    ),
    context: json['context'] as String?,
    from: json['from'] as String?,
    to: json['to'] as String?,
    filter: filter is Map ? Map<String, Object?>.from(filter) : null,
  );
}

ExportColumns _columns(Object? raw) {
  final Map<String, Object?> json = raw is Map
      ? Map<String, Object?>.from(raw)
      : <String, Object?>{};
  return (
    raw: json['raw'] == true,
    refined: json['refined'] != false,
    confidence: json['confidence'] == true,
    evidence: json['evidence'] == true,
  );
}

ExportExtras _extras(Object? raw) {
  final Map<String, Object?> json = raw is Map
      ? Map<String, Object?>.from(raw)
      : <String, Object?>{};
  return (
    dictionary: json['dictionary'] == true,
    photoIndex: json['photoIndex'] != false,
    photoMode: json['photoMode'] as String? ?? 'filename',
    delimiter: json['delimiter'] as String? ?? ',',
  );
}

List<Object?> _list(Object? raw) =>
    raw is List<Object?> ? raw : const <Object?>[];

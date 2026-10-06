import 'dart:convert';

import 'export_output_template.dart';
import 'export_record.dart';
import 'pdf_photo_layout.dart';
import 'value_formatter.dart';

export 'pdf_photo_layout.dart';

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
    this.omittedRecordIds = const <String>[],
    this.photoFaceCounts = const <String, int>{},
    this.privacyFingerprint = '',
    this.outputTemplates = const <ExportOutputTemplate>[],
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
      omittedRecordIds: _list(
        json['omittedRecordIds'],
      ).whereType<String>().toList(),
      photoFaceCounts: json['photoFaceCounts'] is Map
          ? Map<String, int>.from(json['photoFaceCounts']! as Map)
          : const <String, int>{},
      privacyFingerprint: json['privacyFingerprint'] as String? ?? '',
      outputTemplates: <ExportOutputTemplate>[
        for (final Object? value in _list(json['outputTemplates']))
          if (value is Map)
            ExportOutputTemplate.fromJson(Map<String, Object?>.from(value)),
      ],
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

  /// Records excluded because required consent was not confirmed.
  final List<String> omittedRecordIds;

  /// Detected face counts for every photo processed under face protection.
  final Map<String, int> photoFaceCounts;

  /// Current protection state, checked again before sharing an old artifact.
  final String privacyFingerprint;

  /// Captured source documents and mappings; later template edits cannot change replay.
  final List<ExportOutputTemplate> outputTemplates;

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
        'pdfPhotos': extras.pdfPhotos,
        'delimiter': extras.delimiter,
      },
      'markedIncomplete': markedIncomplete,
      'omittedRecordIds': omittedRecordIds,
      'photoFaceCounts': photoFaceCounts,
      'privacyFingerprint': privacyFingerprint,
      'outputTemplates': <Map<String, Object?>>[
        for (final ExportOutputTemplate template in outputTemplates)
          template.toJson(),
      ],
      'files': <Map<String, Object?>>[
        for (final ExportFile file in files)
          <String, Object?>{'path': file.path, 'role': file.role},
      ],
      'records': <Map<String, Object?>>[
        for (final ExportRecord record in records) record.toJson(),
      ],
    };
  }

  /// Serializes a replayable snapshot one record at a time.
  Iterable<String> chunks() sync* {
    final Map<String, Object?> metadata = copyWith(
      records: const <ExportRecord>[],
    ).toJson()..remove('records');
    final String header = jsonEncode(metadata);
    yield '${header.substring(0, header.length - 1)},"records":[';
    for (int index = 0; index < records.length; index++) {
      if (index > 0) yield ',';
      yield jsonEncode(records[index].toJson());
    }
    yield ']}';
  }

  /// Whether this asks for the whole project package rather than chosen
  /// files: a ZIP with no other format is the full project bundle (§49,
  /// task 076 D13), which the project package writer produces.
  bool get isProjectPackage =>
      formats.length == 1 && formats.contains(ExportFormat.zip);

  /// The same request with the provided fields replaced.
  ExportRequest copyWith({
    Set<ExportFormat>? formats,
    ExportScope? scope,
    ExportColumns? columns,
    ExportExtras? extras,
    List<ExportRecord>? records,
    List<ExportFile>? files,
    List<String>? omittedRecordIds,
    Map<String, int>? photoFaceCounts,
    String? privacyFingerprint,
    List<ExportOutputTemplate>? outputTemplates,
  }) {
    return ExportRequest(
      projectId: projectId,
      formats: formats ?? this.formats,
      scope: scope ?? this.scope,
      columns: columns ?? this.columns,
      extras: extras ?? this.extras,
      markedIncomplete: markedIncomplete,
      records: records ?? this.records,
      files: files ?? this.files,
      omittedRecordIds: omittedRecordIds ?? this.omittedRecordIds,
      photoFaceCounts: photoFaceCounts ?? this.photoFaceCounts,
      privacyFingerprint: privacyFingerprint ?? this.privacyFingerprint,
      outputTemplates: outputTemplates ?? this.outputTemplates,
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
      omittedRecordIds: omittedRecordIds,
      photoFaceCounts: photoFaceCounts,
      privacyFingerprint: privacyFingerprint,
      outputTemplates: outputTemplates,
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
      omittedRecordIds: omittedRecordIds,
      photoFaceCounts: photoFaceCounts,
      privacyFingerprint: privacyFingerprint,
      outputTemplates: outputTemplates,
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

/// Extras under the advanced group. [photoMode] is the workbook's photo
/// reference (`filename`, `relative`, `path` or `embed`); [pdfPhotos] is the
/// reports' photo layout, [PdfPhotoLayout.thumbnail] or [PdfPhotoLayout.full].
typedef ExportExtras = ({
  bool dictionary,
  bool photoIndex,
  String photoMode,
  String pdfPhotos,
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
    pdfPhotos: json['pdfPhotos'] == PdfPhotoLayout.full
        ? PdfPhotoLayout.full
        : PdfPhotoLayout.thumbnail,
    delimiter: json['delimiter'] as String? ?? ',',
  );
}

List<Object?> _list(Object? raw) =>
    raw is List<Object?> ? raw : const <Object?>[];

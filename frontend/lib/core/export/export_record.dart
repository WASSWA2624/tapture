/// One record the writers emit (task 018).
final class ExportRecord {
  /// Creates a record row for an export.
  const ExportRecord({
    required this.id,
    required this.number,
    required this.templateId,
    required this.templateName,
    required this.status,
    this.contextPath = '',
    this.operatorName = '',
    this.templateVersion = '',
    this.values = const <ExportValue>[],
    this.photos = const <ExportPhoto>[],
    this.approved = false,
    this.definitions = const <Map<String, Object?>>[],
    this.provenance = const <String, Object?>{},
    this.photoSources = const <String, String>{},
    this.templateRowId,
    this.capturedAt = '',
  });

  /// Rebuilds a record written by [toJson].
  factory ExportRecord.fromJson(Map<String, Object?> json) {
    return ExportRecord(
      id: json['id'] as String? ?? '',
      number: json['number'] as String? ?? '',
      templateId: json['templateId'] as String? ?? '',
      templateName: json['templateName'] as String? ?? '',
      status: json['status'] as String? ?? '',
      contextPath: json['contextPath'] as String? ?? '',
      operatorName: json['operatorName'] as String? ?? '',
      templateVersion: json['templateVersion'] as String? ?? '',
      approved: json['approved'] == true,
      definitions: <Map<String, Object?>>[
        for (final Object? row in _list(json['definitions']))
          if (row is Map) Map<String, Object?>.from(row),
      ],
      provenance: json['provenance'] is Map
          ? Map<String, Object?>.from(json['provenance']! as Map)
          : const <String, Object?>{},
      photoSources: json['photoSources'] is Map
          ? Map<String, String>.from(json['photoSources']! as Map)
          : const <String, String>{},
      values: <ExportValue>[
        for (final Object? row in _list(json['values']))
          if (row is Map) _value(Map<String, Object?>.from(row)),
      ],
      photos: <ExportPhoto>[
        for (final Object? row in _list(json['photos']))
          if (row is Map) _photo(Map<String, Object?>.from(row)),
      ],
      templateRowId: json['templateRowId'] as String?,
      capturedAt: json['capturedAt'] as String? ?? '',
    );
  }

  /// Record id.
  final String id;

  /// Display number. Kept as text so leading zeros survive.
  final String number;

  /// Template id.
  final String templateId;

  /// Template name, used as the sheet name.
  final String templateName;

  /// Record status.
  final String status;

  /// Context path at capture.
  final String contextPath;

  /// Operator who captured it.
  final String operatorName;

  /// Template version at capture.
  final String templateVersion;

  /// Field values.
  final List<ExportValue> values;

  /// Photos.
  final List<ExportPhoto> photos;

  /// Whether the record is approved.
  final bool approved;

  /// Captured field definitions used by the accompanying dictionary.
  final List<Map<String, Object?>> definitions;

  /// Extraction and review provenance by field key.
  final Map<String, Object?> provenance;

  /// Original storage paths keyed by photo id, retained for request replay.
  final Map<String, String> photoSources;

  /// The predefined checklist row this record answers, when it answers one.
  final String? templateRowId;

  /// When the record was captured, ISO-8601 in UTC, or empty.
  final String capturedAt;

  /// JSON for the request.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'number': number,
      'templateId': templateId,
      'templateName': templateName,
      'status': status,
      'contextPath': contextPath,
      'operatorName': operatorName,
      'templateVersion': templateVersion,
      'approved': approved,
      'definitions': definitions,
      'provenance': provenance,
      'photoSources': photoSources,
      'templateRowId': templateRowId,
      'capturedAt': capturedAt,
      'values': <Map<String, Object?>>[
        for (final ExportValue value in values)
          <String, Object?>{
            'key': value.key,
            'label': value.label,
            'type': value.type,
            'raw': value.raw,
            'refined': value.refined,
            'finalText': value.finalText,
            'unit': value.unit,
            'code': value.code,
            'confidence': value.confidence,
            'evidence': value.evidence,
          },
      ],
      'photos': <Map<String, Object?>>[
        for (final ExportPhoto photo in photos)
          <String, Object?>{
            'id': photo.id,
            'recordId': photo.recordId,
            'type': photo.type,
            'caption': photo.caption,
            'storedPath': photo.storedPath,
            'originalName': photo.originalName,
            'sequence': photo.sequence,
          },
      ],
    };
  }
}

/// One field value carried raw, refined and final.
typedef ExportValue = ({
  String key,
  String label,
  String type,
  String? raw,
  String? refined,
  String? finalText,
  String? unit,
  String? code,
  double? confidence,
  String? evidence,
});

/// One photo an export may name and index.
typedef ExportPhoto = ({
  String id,
  String recordId,
  String type,
  String caption,
  String storedPath,
  String originalName,
  int sequence,
});

ExportValue _value(Map<String, Object?> json) {
  final Object? confidence = json['confidence'];
  return (
    key: json['key'] as String? ?? '',
    label: json['label'] as String? ?? '',
    type: json['type'] as String? ?? 'text',
    raw: json['raw'] as String?,
    refined: json['refined'] as String?,
    finalText: json['finalText'] as String?,
    unit: json['unit'] as String?,
    code: json['code'] as String?,
    confidence: confidence is num ? confidence.toDouble() : null,
    evidence: json['evidence'] as String?,
  );
}

ExportPhoto _photo(Map<String, Object?> json) {
  return (
    id: json['id'] as String? ?? '',
    recordId: json['recordId'] as String? ?? '',
    type: json['type'] as String? ?? '',
    caption: json['caption'] as String? ?? '',
    storedPath: json['storedPath'] as String? ?? '',
    originalName: json['originalName'] as String? ?? '',
    sequence: json['sequence'] is int ? json['sequence']! as int : 0,
  );
}

List<Object?> _list(Object? raw) =>
    raw is List<Object?> ? raw : const <Object?>[];

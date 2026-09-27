import 'package:tapture/core/widgets/record_status.dart';

import 'record_flag.dart';
import 'record_photo.dart';
import 'record_summary.dart';
import 'record_value.dart';

/// One captured record, read whole in one call (task 014 step 1).
///
/// Values, photos, status, flags and the context snapshot arrive together, so
/// no caller assembles a record from several queries. Deleted records are
/// read too; [status] says so.
final class RecordEntry {
  /// Creates a record.
  const RecordEntry({
    required this.id,
    required this.projectId,
    required this.templateId,
    required this.status,
    required this.capturedAt,
    required this.capturedBy,
    required this.updatedAt,
    this.templateRowId,
    this.number,
    this.name = '',
    this.identifier = '',
    this.values = const <RecordValue>[],
    this.photos = const <RecordPhoto>[],
    this.caption = '',
    this.audioClips = 0,
    this.context = const <String, String>{},
    this.flags = const <RecordFlag>{},
    this.approvedAt,
    this.approvedBy,
    this.exportedAt,
    this.processingMode = 'manual',
    this.source = 'capture',
  });

  /// Merge id of the record.
  final String id;

  /// Project the record belongs to.
  final String projectId;

  /// Template the record is filled against.
  final String templateId;

  /// Predefined checklist row the record was captured against, when any.
  final String? templateRowId;

  /// The per-project number shown in lists, when one is allocated.
  final int? number;

  /// The record's name, or empty when nothing names it yet.
  final String name;

  /// The identity field values joined by a space, or empty.
  final String identifier;

  /// Where the record is in its lifecycle.
  final RecordStatus status;

  /// Every value on the record, retired ones included, in field order.
  final List<RecordValue> values;

  /// Live photos, in their sort order.
  final List<RecordPhoto> photos;

  /// The record-level caption (refined, else raw), or empty.
  final String caption;

  /// How many audio clips are attached.
  final int audioClips;

  /// Context values in force at capture, level key to value, outermost first.
  final Map<String, String> context;

  /// Quality flags carried beside the status.
  final Set<RecordFlag> flags;

  /// When the record was captured.
  final DateTime capturedAt;

  /// Who captured it: the capturing device id today (D7).
  final String capturedBy;

  /// When the record last changed.
  final DateTime updatedAt;

  /// When the record was last approved, if it has been.
  final DateTime? approvedAt;

  /// Who approved it, when known.
  final String? approvedBy;

  /// When the record was last exported, if it has been.
  final DateTime? exportedAt;

  /// How the record is processed (manual, on-device, online).
  final String processingMode;

  /// Where the record came from (capture, import, duplicate).
  final String source;

  /// The value filling [fieldKey], or null when there is none.
  RecordValue? valueOf(String fieldKey) {
    for (final RecordValue value in values) {
      if (value.fieldKey == fieldKey) {
        return value;
      }
    }
    return null;
  }

  /// Values the record's template still declares.
  List<RecordValue> get liveValues => <RecordValue>[
    for (final RecordValue value in values)
      if (!value.retired) value,
  ];

  /// Values kept after a template change left them without a field.
  List<RecordValue> get retiredValues => <RecordValue>[
    for (final RecordValue value in values)
      if (value.retired) value,
  ];

  /// Whether the record sits in the recycle bin.
  bool get isDeleted => status == RecordStatus.deleted;

  /// The deepest context value: the last one in [context] that is not empty.
  String get contextLabel {
    String label = '';
    for (final String value in context.values) {
      if (value.trim().isNotEmpty) {
        label = value;
      }
    }
    return label;
  }

  /// This record as a list row.
  RecordSummary toSummary() {
    return RecordSummary(
      id: id,
      projectId: projectId,
      templateId: templateId,
      number: number,
      name: name,
      identifier: identifier,
      contextLabel: contextLabel,
      status: status,
      thumb: photos.isEmpty ? null : photos.first,
      photoCount: photos.length,
      capturedAt: capturedAt,
      flags: flags,
    );
  }

  /// Returns a copy with the provided fields replaced. The `clear…` flags set
  /// the matching nullable field back to null.
  RecordEntry copyWith({
    String? id,
    String? projectId,
    String? templateId,
    String? templateRowId,
    int? number,
    String? name,
    String? identifier,
    RecordStatus? status,
    List<RecordValue>? values,
    List<RecordPhoto>? photos,
    String? caption,
    int? audioClips,
    Map<String, String>? context,
    Set<RecordFlag>? flags,
    DateTime? capturedAt,
    String? capturedBy,
    DateTime? updatedAt,
    DateTime? approvedAt,
    String? approvedBy,
    DateTime? exportedAt,
    String? processingMode,
    String? source,
    bool clearTemplateRowId = false,
    bool clearNumber = false,
    bool clearApproval = false,
    bool clearExportedAt = false,
  }) {
    return RecordEntry(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      templateId: templateId ?? this.templateId,
      templateRowId: clearTemplateRowId
          ? null
          : (templateRowId ?? this.templateRowId),
      number: clearNumber ? null : (number ?? this.number),
      name: name ?? this.name,
      identifier: identifier ?? this.identifier,
      status: status ?? this.status,
      values: values ?? this.values,
      photos: photos ?? this.photos,
      caption: caption ?? this.caption,
      audioClips: audioClips ?? this.audioClips,
      context: context ?? this.context,
      flags: flags ?? this.flags,
      capturedAt: capturedAt ?? this.capturedAt,
      capturedBy: capturedBy ?? this.capturedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: clearApproval ? null : (approvedAt ?? this.approvedAt),
      approvedBy: clearApproval ? null : (approvedBy ?? this.approvedBy),
      exportedAt: clearExportedAt ? null : (exportedAt ?? this.exportedAt),
      processingMode: processingMode ?? this.processingMode,
      source: source ?? this.source,
    );
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    projectId,
    templateId,
    templateRowId,
    number,
    name,
    identifier,
    status,
    Object.hashAll(values),
    Object.hashAll(photos),
    caption,
    audioClips,
    Object.hashAllUnordered(<String>[
      for (final MapEntry<String, String> pair in context.entries)
        '${pair.key}=${pair.value}',
    ]),
    Object.hashAllUnordered(flags),
    capturedAt,
    capturedBy,
    updatedAt,
    approvedAt,
    approvedBy,
    exportedAt,
    processingMode,
    source,
  ]);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RecordEntry &&
            other.id == id &&
            other.projectId == projectId &&
            other.templateId == templateId &&
            other.templateRowId == templateRowId &&
            other.number == number &&
            other.name == name &&
            other.identifier == identifier &&
            other.status == status &&
            _sameList(other.values, values) &&
            _sameList(other.photos, photos) &&
            other.caption == caption &&
            other.audioClips == audioClips &&
            _sameMap(other.context, context) &&
            other.flags.length == flags.length &&
            other.flags.containsAll(flags) &&
            other.capturedAt == capturedAt &&
            other.capturedBy == capturedBy &&
            other.updatedAt == updatedAt &&
            other.approvedAt == approvedAt &&
            other.approvedBy == approvedBy &&
            other.exportedAt == exportedAt &&
            other.processingMode == processingMode &&
            other.source == source);
  }

  /// Names the record only: a value never reaches a log (FE-CODE-08).
  @override
  String toString() => 'RecordEntry($id, ${status.name})';
}

bool _sameList<T>(List<T> left, List<T> right) {
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

bool _sameMap(Map<String, String> left, Map<String, String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (final MapEntry<String, String> pair in left.entries) {
    if (right[pair.key] != pair.value) {
      return false;
    }
  }
  return true;
}

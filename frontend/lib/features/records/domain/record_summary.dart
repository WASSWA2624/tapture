import 'package:tapture/core/widgets/record_status.dart';

import 'record_flag.dart';
import 'record_photo.dart';

/// One row of a records list: number, name, identifier, context and status
/// (spec §55.2), with the thumbnail and the quality flags.
final class RecordSummary {
  /// Creates a list row.
  const RecordSummary({
    required this.id,
    required this.projectId,
    required this.templateId,
    required this.status,
    required this.capturedAt,
    this.number,
    this.name = '',
    this.identifier = '',
    this.contextLabel = '',
    this.thumb,
    this.photoCount = 0,
    this.flags = const <RecordFlag>{},
  });

  /// Merge id of the record.
  final String id;

  /// Project the record belongs to.
  final String projectId;

  /// Template the record is filled against.
  final String templateId;

  /// The per-project number shown in the list, when one is allocated.
  final int? number;

  /// The record's name, or empty when nothing names it yet.
  final String name;

  /// The identity field values joined by a space, or empty.
  final String identifier;

  /// The deepest context value in force at capture, or empty.
  final String contextLabel;

  /// Where the record is in its lifecycle.
  final RecordStatus status;

  /// The first live photo, drawn as the row's thumbnail.
  final RecordPhoto? thumb;

  /// How many live photos the record has.
  final int photoCount;

  /// When the record was captured.
  final DateTime capturedAt;

  /// Quality flags carried beside the status.
  final Set<RecordFlag> flags;

  /// Whether [flag] is set on this row.
  bool has(RecordFlag flag) => flags.contains(flag);

  /// Returns a copy with the provided fields replaced. [clearNumber] and
  /// [clearThumb] set the matching field back to null.
  RecordSummary copyWith({
    String? id,
    String? projectId,
    String? templateId,
    int? number,
    String? name,
    String? identifier,
    String? contextLabel,
    RecordStatus? status,
    RecordPhoto? thumb,
    int? photoCount,
    DateTime? capturedAt,
    Set<RecordFlag>? flags,
    bool clearNumber = false,
    bool clearThumb = false,
  }) {
    return RecordSummary(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      templateId: templateId ?? this.templateId,
      number: clearNumber ? null : (number ?? this.number),
      name: name ?? this.name,
      identifier: identifier ?? this.identifier,
      contextLabel: contextLabel ?? this.contextLabel,
      status: status ?? this.status,
      thumb: clearThumb ? null : (thumb ?? this.thumb),
      photoCount: photoCount ?? this.photoCount,
      capturedAt: capturedAt ?? this.capturedAt,
      flags: flags ?? this.flags,
    );
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    templateId,
    number,
    name,
    identifier,
    contextLabel,
    status,
    thumb,
    photoCount,
    capturedAt,
    Object.hashAllUnordered(flags),
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RecordSummary &&
            other.id == id &&
            other.projectId == projectId &&
            other.templateId == templateId &&
            other.number == number &&
            other.name == name &&
            other.identifier == identifier &&
            other.contextLabel == contextLabel &&
            other.status == status &&
            other.thumb == thumb &&
            other.photoCount == photoCount &&
            other.capturedAt == capturedAt &&
            other.flags.length == flags.length &&
            other.flags.containsAll(flags));
  }

  /// Names the record only: a value never reaches a log (FE-CODE-08).
  @override
  String toString() => 'RecordSummary($id, ${status.name})';
}

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/widgets/record_status.dart';

import '../domain/deleted_record.dart';
import '../domain/record_entry.dart';
import '../domain/record_flag.dart';
import '../domain/record_history_event.dart';
import '../domain/record_photo.dart';
import '../domain/record_summary.dart';
import '../domain/record_value.dart';

/// Turns the rows `RecordQueries` reads into records domain types, so Drift
/// stops at the data boundary (FE-STR-05).
///
/// Every method reads result columns by the alias the query gives them; the
/// alias each one needs is listed on it. Dates are unix seconds in SQL and
/// come back as UTC instants. A value keeps its three stages side by side:
/// the captured column becomes [RecordValue.raw], the refined one
/// [RecordValue.refined] and the final one [RecordValue.approved].
abstract final class RecordMapper {
  /// The status a stored spelling that names no [RecordStatus] reads as:
  /// the state capture leaves a record in. Lists never show such a record
  /// (they filter by the canonical names); a read of it still succeeds.
  static const RecordStatus unknownStatus = RecordStatus.captured;

  /// The result column carrying each quality flag, 1 when it holds.
  static const Map<RecordFlag, String> flagColumns = <RecordFlag, String>{
    RecordFlag.hasPhotos: 'flag_photos',
    RecordFlag.hasDuplicate: 'flag_duplicate',
    RecordFlag.hasConflict: 'flag_conflict',
    RecordFlag.hasVariance: 'flag_variance',
    RecordFlag.evidenceRemoved: 'flag_evidence',
    RecordFlag.mergedFromBundle: 'flag_merged',
  };

  /// The stored status [stored], folding legacy spellings; [unknownStatus]
  /// when it names none.
  static RecordStatus status(String? stored) {
    if (stored == null) {
      return unknownStatus;
    }
    return RecordStatus.fromStored(stored.trim()) ?? unknownStatus;
  }

  /// The context snapshot stored in `records.context_json`, level key to
  /// value in stored order.
  ///
  /// Capture stores a flat object of values; the context writer stores
  /// `{levels, values, pinned}`, whose values and pinned values are read
  /// (a pinned value wins). Only text values are kept. Malformed JSON, or
  /// JSON that is not an object, reads as no context.
  static Map<String, String> context(String? json) {
    if (json == null || json.trim().isEmpty) {
      return const <String, String>{};
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      return const <String, String>{};
    }
    if (decoded is! Map<String, Object?>) {
      return const <String, String>{};
    }
    final Object? values = decoded['values'];
    final Object? pinned = decoded['pinned'];
    if (decoded['levels'] is List<Object?> && values is Map<String, Object?>) {
      return <String, String>{
        ..._texts(values),
        if (pinned is Map<String, Object?>) ..._texts(pinned),
      };
    }
    return _texts(decoded);
  }

  /// Clockwise quarter turns, 0 to 3, for a stored rotation in degrees.
  static int quarterTurns(int? degrees) {
    return ((((degrees ?? 0) % 360) + 360) % 360) ~/ 90;
  }

  /// One value. Reads `field_key`, `value_raw`, `value_refined`,
  /// `value_final`, `source`, `confidence`, `confidence_band`, `verified`,
  /// `evidence_removed_at`, `retired_at`, `provider`, `model` and `method`.
  static RecordValue value(QueryRow row) {
    return RecordValue(
      fieldKey: row.read<String>('field_key'),
      raw: row.read<String?>('value_raw') ?? '',
      refined: row.read<String?>('value_refined'),
      approved: row.read<String?>('value_final'),
      source: row.read<String?>('source') ?? RecordValue.manualSource,
      confidence: row.read<double?>('confidence'),
      band: row.read<String?>('confidence_band'),
      verified: _isSet(row, 'verified'),
      evidenceRemoved: row.data['evidence_removed_at'] != null,
      retired: row.data['retired_at'] != null,
      provider: row.read<String?>('provider'),
      model: row.read<String?>('model'),
      method: row.read<String?>('method'),
    );
  }

  /// One live photo. Reads `id`, `sha256`, `storage_path`,
  /// `rotation_degrees`, `sort_order`, `photo_type` and `caption`, each
  /// after [prefix] (`thumb_` for a list row's thumbnail).
  static RecordPhoto photo(QueryRow row, {String prefix = ''}) {
    return RecordPhoto(
      id: row.read<String>('${prefix}id'),
      sha256: row.read<String>('${prefix}sha256'),
      storagePath: row.read<String>('${prefix}storage_path'),
      quarterTurns: quarterTurns(row.read<int?>('${prefix}rotation_degrees')),
      caption: row.read<String?>('${prefix}caption') ?? '',
      sortOrder: row.read<int?>('${prefix}sort_order') ?? 0,
      photoType: row.read<String?>('${prefix}photo_type') ?? '',
    );
  }

  /// The quality flags whose [flagColumns] hold 1.
  static Set<RecordFlag> flags(QueryRow row) {
    return <RecordFlag>{
      for (final MapEntry<RecordFlag, String> flag in flagColumns.entries)
        if (_isSet(row, flag.value)) flag.key,
    };
  }

  /// One list row. Reads `id`, `project_id`, `template_id`,
  /// `record_number`, `status`, `captured_at`, `name`, `identifier`,
  /// `context_label`, `photo_count`, the [flagColumns] and, when `thumb_id`
  /// is not null, the thumbnail's [photo] columns prefixed `thumb_`.
  static RecordSummary summary(QueryRow row) {
    return RecordSummary(
      id: row.read<String>('id'),
      projectId: row.read<String>('project_id'),
      templateId: row.read<String>('template_id'),
      number: row.read<int?>('record_number'),
      name: row.read<String?>('name') ?? '',
      identifier: row.read<String?>('identifier') ?? '',
      contextLabel: row.read<String?>('context_label') ?? '',
      status: status(row.read<String?>('status')),
      thumb: row.data['thumb_id'] == null ? null : photo(row, prefix: _thumb),
      photoCount: row.read<int?>('photo_count') ?? 0,
      capturedAt: row.read<DateTime>('captured_at').toUtc(),
      flags: flags(row),
    );
  }

  /// A whole record from its row, its [values] in field order and its live
  /// [photos] in sort order.
  ///
  /// [record] carries `id`, `project_id`, `template_id`,
  /// `template_row_id`, `record_number`, `name`, `identifier`, `status`,
  /// `processing_mode`, `source`, `context_json`, `captured_at`,
  /// `captured_by`, `updated_at`, `approved_at`, `approved_by`,
  /// `exported_at`, `caption`, `audio_clips` and the [flagColumns]. Each
  /// of [values] is read by [value] and each of [photos] by [photo].
  static RecordEntry entry(
    QueryRow record, {
    required List<QueryRow> values,
    required List<QueryRow> photos,
  }) {
    return RecordEntry(
      id: record.read<String>('id'),
      projectId: record.read<String>('project_id'),
      templateId: record.read<String>('template_id'),
      templateRowId: record.read<String?>('template_row_id'),
      number: record.read<int?>('record_number'),
      name: record.read<String?>('name') ?? '',
      identifier: record.read<String?>('identifier') ?? '',
      status: status(record.read<String?>('status')),
      values: <RecordValue>[for (final QueryRow row in values) value(row)],
      photos: <RecordPhoto>[for (final QueryRow row in photos) photo(row)],
      caption: record.read<String?>('caption') ?? '',
      audioClips: record.read<int?>('audio_clips') ?? 0,
      context: context(record.read<String?>('context_json')),
      flags: flags(record),
      capturedAt: record.read<DateTime>('captured_at').toUtc(),
      capturedBy: record.read<String>('captured_by'),
      updatedAt: record.read<DateTime>('updated_at').toUtc(),
      approvedAt: record.read<DateTime?>('approved_at')?.toUtc(),
      approvedBy: record.read<String?>('approved_by'),
      exportedAt: record.read<DateTime?>('exported_at')?.toUtc(),
      processingMode: record.read<String?>('processing_mode') ?? 'manual',
      source: record.read<String?>('source') ?? 'capture',
    );
  }

  /// One recycle bin row: the [summary] columns plus `deleted_at`,
  /// `bin_reason` and `project_name`.
  static DeletedRecord deleted(QueryRow row) {
    return DeletedRecord(
      summary: summary(row),
      deletedAt: row.read<DateTime>('deleted_at').toUtc(),
      reason: row.read<String?>('bin_reason') ?? '',
      projectName: row.read<String?>('project_name') ?? '',
    );
  }

  /// One history line from an audit row. Reads `id`, `at`, `entity_type`,
  /// `action` (as stored text), `field_key`, `previous_value`, `new_value`,
  /// `reason`, `operator`, `device`, and the two disambiguation columns
  /// `has_field` and `known_template` (see [historyKind]).
  static RecordHistoryEvent historyEvent(QueryRow row) {
    final String? fieldKey = row.read<String?>('field_key');
    final String? previous = row.read<String?>('previous_value');
    final String? next = row.read<String?>('new_value');
    final String? reason = row.read<String?>('reason');
    return RecordHistoryEvent(
      id: row.read<String>('id'),
      at: row.read<DateTime>('at').toUtc(),
      kind: historyKind(
        entityType: row.read<String>('entity_type'),
        action: row.read<String>('action'),
        fieldKey: fieldKey,
        previous: previous,
        next: next,
        reason: reason,
        hasField: _isSet(row, 'has_field'),
        knownTemplate: _isSet(row, 'known_template'),
      ),
      fieldKey: fieldKey,
      previous: previous,
      next: next,
      operator: row.read<String?>('operator') ?? '',
      device: row.read<String?>('device') ?? '',
      reason: reason,
    );
  }

  /// The kind of one audit row: [RecordHistoryKind.classify], except that a
  /// field whose key is also a record-level marker is told apart from the
  /// marker.
  ///
  /// A template may declare a field keyed `status`, `templateId`, `photo`,
  /// `processing`, `export` or `merge`; its value edits then carry the
  /// marker as their field key. When the record has a value under that key
  /// ([hasField]), a row is read as the marker only when it has the
  /// marker's shape: a status move is `updated` between two stored status
  /// names; a template change is `updated` to a template on this device
  /// ([knownTemplate]); a photo row says `added` or `removed`; a processing
  /// row says `completed` or `failed` with a JSON reason; an export row
  /// says `v<version>`; a merge row is `created`/`inserted` or
  /// `updated`/`updated`. Anything else is a value change (or the value's
  /// flag line). A value edit between two status names on a field keyed
  /// `status` still reads as a status move; the audit row holds nothing
  /// more to tell them apart.
  static RecordHistoryKind historyKind({
    required String entityType,
    required String action,
    String? fieldKey,
    String? previous,
    String? next,
    String? reason,
    bool hasField = false,
    bool knownTemplate = false,
  }) {
    final RecordHistoryKind kind = RecordHistoryKind.classify(
      entityType: entityType,
      action: action,
      fieldKey: fieldKey,
      newValue: next,
      reason: reason,
    );
    if (entityType != _recordsEntity ||
        !hasField ||
        fieldKey == null ||
        kind == RecordHistoryKind.evidenceRemoved ||
        kind == RecordHistoryKind.retired) {
      return kind;
    }
    final bool? marker = switch (fieldKey) {
      _statusKey =>
        action == _updated && _isStatusName(previous) && _isStatusName(next),
      _templateKey => action == _updated && knownTemplate,
      _photoKey => next == _added || next == _removed,
      _processingKey =>
        (next == _completed || next == _failed) &&
            (reason?.trimLeft().startsWith('{') ?? false),
      _exportKey => action == _updated && _exportVersion.hasMatch(next ?? ''),
      _mergeKey =>
        (action == _created && next == _inserted) ||
            (action == _updated && next == _updated),
      _ => null,
    };
    return marker == false ? RecordHistoryKind.valueChanged : kind;
  }
}

const String _thumb = 'thumb_';
const String _recordsEntity = 'records';
const String _created = 'created';
const String _updated = 'updated';
const String _statusKey = 'status';
const String _templateKey = 'templateId';
const String _photoKey = 'photo';
const String _processingKey = 'processing';
const String _exportKey = 'export';
const String _mergeKey = 'merge';
const String _added = 'added';
const String _removed = 'removed';
const String _completed = 'completed';
const String _failed = 'failed';
const String _inserted = 'inserted';
final RegExp _exportVersion = RegExp(r'^v\d+$');

bool _isStatusName(String? value) {
  if (value == null) {
    return false;
  }
  for (final RecordStatus status in RecordStatus.values) {
    if (status.stored == value) {
      return true;
    }
  }
  return false;
}

/// Whether the integer (or boolean) column [name] holds a truthy value.
bool _isSet(QueryRow row, String name) {
  final Object? raw = row.data[name];
  return switch (raw) {
    final int number => number != 0,
    final bool flag => flag,
    _ => false,
  };
}

Map<String, String> _texts(Map<String, Object?> json) {
  return <String, String>{
    for (final MapEntry<String, Object?> pair in json.entries)
      if (pair.value is String) pair.key: pair.value! as String,
  };
}

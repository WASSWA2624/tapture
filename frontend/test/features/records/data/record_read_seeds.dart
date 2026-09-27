import 'dart:convert';

import 'package:tapture/core/db/app_database.dart';

import '../../../core/db/record_rows.dart' show seedRow;

/// Raw-SQL seeds for the records read side (`RecordQueries`), written the
/// way a merge writes rows: the database's triggers still number records,
/// normalise statuses and index them for search. Raw writes do not notify
/// drift's streams; tests that watch a stream refresh write through the core
/// helpers instead.

/// Unix seconds of [at], as drift stores a DateTime.
int secondsOf(DateTime at) => at.millisecondsSinceEpoch ~/ 1000;

/// A project row.
Future<void> seedProjectRow(
  AppDatabase db,
  String id, {
  String name = 'Project',
  String? folder,
}) {
  return seedRow(db, 'projects', <String, Object?>{
    'id': id,
    'name': name,
    'status': 'active',
    'folder_name': folder ?? 'folder-$id',
    'settings': '{}',
  });
}

/// A template with plain visible text [fields] in that order, and
/// [identity] listed as its identity fields.
Future<void> seedTemplateRow(
  AppDatabase db,
  String id, {
  String projectId = 'p1',
  String name = 'Template',
  List<String> fields = const <String>[],
  List<String> identity = const <String>[],
}) async {
  await seedRow(db, 'templates', <String, Object?>{
    'id': id,
    'project_id': projectId,
    'name': name,
    'kind': 'form',
    'source': 'test',
    'identity_fields': jsonEncode(identity),
  });
  for (int index = 0; index < fields.length; index++) {
    await seedRow(db, 'template_fields', <String, Object?>{
      'id': '$id-${fields[index]}',
      'template_id': id,
      'field_key': fields[index],
      'label': fields[index],
      'type': 'text',
      'sort_order': index,
    });
  }
}

/// A record row. [context] is a map encoded as JSON, or a JSON string
/// stored as it is. A null [number] leaves the number to the trigger.
Future<void> seedRecordRow(
  AppDatabase db,
  String id, {
  String projectId = 'p1',
  String templateId = 't1',
  String? templateRowId,
  String status = 'captured',
  DateTime? capturedAt,
  String capturedBy = 'device-a',
  Object context = const <String, String>{},
  int? number,
  String processingMode = 'manual',
  String source = 'capture',
  DateTime? updatedAt,
  DateTime? approvedAt,
  String? approvedBy,
}) {
  final DateTime captured = capturedAt ?? DateTime.utc(2026, 9, 17, 8);
  return seedRow(db, 'records', <String, Object?>{
    'id': id,
    'updated_at': secondsOf(updatedAt ?? captured),
    'project_id': projectId,
    'template_id': templateId,
    'template_row_id': templateRowId,
    'status': status,
    'processing_mode': processingMode,
    'context_json': context is String ? context : jsonEncode(context),
    'identity_hash': 'hash-$id',
    'source': source,
    'captured_at': secondsOf(captured),
    'captured_by': capturedBy,
    'record_number': number,
    'approved_at': approvedAt == null ? null : secondsOf(approvedAt),
    'approved_by': approvedBy,
  });
}

/// A value on [recordId] with every column the read side maps.
Future<void> seedValue(
  AppDatabase db,
  String id, {
  required String recordId,
  required String fieldKey,
  String? raw,
  String? refined,
  String? approved,
  String source = 'ocr',
  double? confidence,
  String? band,
  bool verified = false,
  String? provider,
  String? model,
  String? method,
  DateTime? evidenceRemovedAt,
  DateTime? retiredAt,
  int createdAt = 1,
}) {
  return seedRow(db, 'record_fields', <String, Object?>{
    'id': id,
    'created_at': createdAt,
    'record_id': recordId,
    'field_key': fieldKey,
    'value_raw': raw,
    'value_refined': refined,
    'value_final': approved,
    'source': source,
    'confidence': confidence,
    'confidence_band': band,
    'verified': verified ? 1 : 0,
    'provider': provider,
    'model': model,
    'method': method,
    'evidence_removed_at': evidenceRemovedAt == null
        ? null
        : secondsOf(evidenceRemovedAt),
    'retired_at': retiredAt == null ? null : secondsOf(retiredAt),
  });
}

/// A photo filed on [recordId] (unfiled when null).
Future<void> seedPhotoRow(
  AppDatabase db,
  String id, {
  required String? recordId,
  String projectId = 'p1',
  String? sha256,
  int sortOrder = 0,
  int? rotation,
  String photoType = 'front',
  String? derivedFrom,
  int capturedAt = 1,
}) {
  return seedRow(db, 'photos', <String, Object?>{
    'id': id,
    'project_id': projectId,
    'record_id': recordId,
    'capture_session_id': 'session-1',
    'original_filename': '$id.jpg',
    'stored_filename': '$id.jpg',
    'relative_path': 'photos/$id.jpg',
    'photo_type': photoType,
    'sort_order': sortOrder,
    'width': 2,
    'height': 2,
    'file_size': 4,
    'mime_type': 'image/jpeg',
    'sha256': sha256 ?? 'sha-$id',
    'captured_at': capturedAt,
    'derived_from': derivedFrom,
    'rotation_degrees': rotation,
  });
}

/// A tombstone on [entityType] row [entityId].
Future<void> seedTomb(
  AppDatabase db,
  String entityType,
  String entityId, {
  String reason = 'Deleted',
  DateTime? deletedAt,
}) {
  return seedRow(db, 'tombstones', <String, Object?>{
    'id': 'tomb-$entityType-$entityId',
    'entity_type': entityType,
    'entity_id': entityId,
    'deleted_at': secondsOf(deletedAt ?? DateTime.utc(2026, 9, 18)),
    'deleted_by_device': 'device-a',
    'reason': reason,
  });
}

/// An audit row, as any writer or a merged peer leaves one.
Future<void> seedAudit(
  AppDatabase db,
  String id, {
  required String entityId,
  required DateTime at,
  String entityType = 'records',
  String action = 'updated',
  String? fieldKey,
  String? previous,
  String? next,
  String? reason,
  String operator = '',
  String device = 'device-a',
}) {
  return seedRow(db, 'audit_log', <String, Object?>{
    'id': id,
    'entity_type': entityType,
    'entity_id': entityId,
    'action': action,
    'field_key': fieldKey,
    'previous_value': previous,
    'new_value': next,
    'reason': reason,
    'operator': operator,
    'device': device,
    'at': secondsOf(at),
  });
}

/// Recognised text cached for the photo content [contentHash].
Future<void> seedOcr(AppDatabase db, String contentHash, String text) {
  return seedRow(db, 'ocr_cache', <String, Object?>{
    'id': 'ocr-$contentHash',
    'content_hash': contentHash,
    'perceptual_hash': 'p-$contentHash',
    'recognised_text': text,
    'blocks_json': '[]',
  });
}

/// A finished processing job on [recordId] whose result is a transcript
/// ([kind] `transcript`) or another kind of response.
Future<void> seedTranscript(
  AppDatabase db,
  String id, {
  required String recordId,
  required String text,
  String kind = 'transcript',
}) async {
  await seedRow(db, 'processing_jobs', <String, Object?>{
    'id': 'job-$id',
    'record_id': recordId,
    'stage': 'online',
    'status': 'completed',
    'queued_at': 1,
  });
  await seedRow(db, 'processing_results', <String, Object?>{
    'id': id,
    'job_id': 'job-$id',
    'request_summary': jsonEncode(<String, String>{'kind': kind}),
    'raw_response': text,
    'parsed_ok': 1,
  });
}

/// A duplicate pair between two records.
Future<void> seedDuplicate(
  AppDatabase db,
  String id, {
  required String left,
  required String right,
  String projectId = 'p1',
  String status = 'unresolved',
}) {
  return seedRow(db, 'duplicates', <String, Object?>{
    'id': id,
    'project_id': projectId,
    'left_record_id': left,
    'right_record_id': right,
    'signal': 'photo',
    'score': 0.9,
    'status': status,
  });
}

/// A variance on one of [recordId]'s fields; resolved when [resolvedAt] is
/// set.
Future<void> seedVariance(
  AppDatabase db,
  String id, {
  required String recordId,
  String projectId = 'p1',
  String fieldKey = 'serial',
  DateTime? resolvedAt,
}) {
  return seedRow(db, 'variances', <String, Object?>{
    'id': id,
    'project_id': projectId,
    'record_id': recordId,
    'field_key': fieldKey,
    'register_value': 'A',
    'found_value': 'B',
    'status': 'open',
    'resolved_by': resolvedAt == null ? null : 'Ada',
    'resolved_at': resolvedAt == null ? null : secondsOf(resolvedAt),
  });
}

/// A merge conflict on [entityType] row [entityId]; unresolved unless
/// [resolution] is set.
Future<void> seedConflict(
  AppDatabase db,
  String id, {
  required String entityType,
  required String entityId,
  String? resolution,
}) {
  return seedRow(db, 'merge_conflicts', <String, Object?>{
    'id': id,
    'session_id': 'session-1',
    'entity_type': entityType,
    'entity_id': entityId,
    'field_key': 'serial',
    'mine_value': 'A',
    'theirs_value': 'B',
    'mine_meta': '{}',
    'theirs_meta': '{}',
    'resolution': resolution,
  });
}

/// An audio clip attached to record [recordId].
Future<void> seedAudio(
  AppDatabase db,
  String id, {
  required String recordId,
  String projectId = 'p1',
}) async {
  await seedRow(db, 'attachments', <String, Object?>{
    'id': id,
    'project_id': projectId,
    'relative_path': 'audio/$id.m4a',
    'mime_type': 'audio/mp4',
    'file_size': 10,
    'sha256': 'sha-$id',
    'kind': 'audio',
  });
  await seedRow(db, 'attachment_owners', <String, Object?>{
    'id': 'owner-$id',
    'attachment_id': id,
    'owner_type': 'record',
    'owner_id': recordId,
  });
}

/// A level of [projectId]'s context hierarchy: [level] 0 is the root.
Future<void> seedContextLevel(
  AppDatabase db, {
  required String projectId,
  required int level,
  required String fieldKey,
  required String label,
}) {
  return seedRow(db, 'context_definitions', <String, Object?>{
    'id': 'level-$projectId-$fieldKey',
    'project_id': projectId,
    'level': level,
    'field_key': fieldKey,
    'label': label,
  });
}

/// This device's profile: its id and operator name.
Future<void> seedDeviceProfile(
  AppDatabase db, {
  required String deviceId,
  String operatorName = '',
}) {
  return seedRow(db, 'device_profile', <String, Object?>{
    'id': 'local',
    'device_id': deviceId,
    'operator_name': operatorName,
  });
}

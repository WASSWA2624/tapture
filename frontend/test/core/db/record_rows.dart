import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';

/// Inserts one row into [table] as raw SQL, the way a merge does, with the
/// merge columns filled in unless [values] names them.
Future<void> seedRow(
  AppDatabase db,
  String table,
  Map<String, Object?> values,
) {
  final Map<String, Object?> row = <String, Object?>{
    'created_at': 1,
    'updated_at': 1,
    'updated_by_device': 'device-a',
    'rev': 1,
    ...values,
  };
  final List<String> names = row.keys.toList();
  return db.customStatement(
    'INSERT INTO $table (${names.join(', ')}) '
    'VALUES (${List<String>.filled(names.length, '?').join(', ')})',
    <Object?>[for (final String name in names) row[name]],
  );
}

/// A record row. [number] null leaves the number to the trigger.
Future<void> seedRecord(
  AppDatabase db,
  String id, {
  String projectId = 'p1',
  String templateId = 't1',
  String? templateRowId,
  String status = 'captured',
  int capturedAt = 1,
  int? number,
}) {
  return seedRow(db, 'records', <String, Object?>{
    'id': id,
    'project_id': projectId,
    'template_id': templateId,
    'template_row_id': templateRowId,
    'status': status,
    'processing_mode': 'manual',
    'context_json': '{}',
    'identity_hash': 'hash-$id',
    'source': 'capture',
    'captured_at': capturedAt,
    'captured_by': 'device-a',
    'record_number': number,
  });
}

/// A field value row on [recordId].
Future<void> seedField(
  AppDatabase db,
  String id, {
  required String recordId,
  required String fieldKey,
  String? raw,
  String? refined,
  String? approved,
  String source = 'ocr',
}) {
  return seedRow(db, 'record_fields', <String, Object?>{
    'id': id,
    'record_id': recordId,
    'field_key': fieldKey,
    'value_raw': raw,
    'value_refined': refined,
    'value_final': approved,
    'source': source,
  });
}

/// A photo row, filed on [recordId] unless it is null.
Future<void> seedPhoto(
  AppDatabase db,
  String id, {
  required String? recordId,
  String projectId = 'p1',
  String? sha256,
  String? derivedFrom,
}) {
  return seedRow(db, 'photos', <String, Object?>{
    'id': id,
    'project_id': projectId,
    'record_id': recordId,
    'capture_session_id': 'session-1',
    'original_filename': '$id.jpg',
    'stored_filename': '$id.jpg',
    'relative_path': 'photos/$id.jpg',
    'photo_type': 'front',
    'sort_order': 0,
    'width': 2,
    'height': 2,
    'file_size': 4,
    'mime_type': 'image/jpeg',
    'sha256': sha256 ?? 'sha-$id',
    'captured_at': 1,
    'derived_from': derivedFrom,
  });
}

/// A caption row owned by a record or a photo.
Future<void> seedCaption(
  AppDatabase db,
  String id, {
  required String ownerType,
  required String ownerId,
  required String text,
  String? refined,
  int createdAt = 1,
}) {
  return seedRow(db, 'captions', <String, Object?>{
    'id': id,
    'created_at': createdAt,
    'owner_type': ownerType,
    'owner_id': ownerId,
    'text_raw': text,
    'text_refined': refined,
    'input_mode': 'typed',
  });
}

/// Photo evidence linking value [fieldId] to [photoId].
Future<void> seedEvidence(
  AppDatabase db,
  String id, {
  required String fieldId,
  required String photoId,
}) {
  return seedRow(db, 'field_evidence', <String, Object?>{
    'id': id,
    'record_field_id': fieldId,
    'source_type': 'photo',
    'photo_id': photoId,
  });
}

/// The FTS MATCH text for [words]: each quoted and suffixed with `*`.
String matchOf(String words) {
  return words
      .split(' ')
      .where((String word) => word.isNotEmpty)
      .map((String word) => '"${word.replaceAll('"', '""')}"*')
      .join(' ');
}

/// Ids of the records whose search document matches every word of [words].
Future<List<String>> searchRecords(AppDatabase db, String words) async {
  final List<QueryRow> rows = await db
      .customSelect(
        'SELECT d.record_id AS id FROM record_search s '
        'JOIN record_search_docs d ON d.doc = s.rowid '
        'WHERE record_search MATCH ? ORDER BY d.record_id',
        variables: <Variable<Object>>[Variable<String>(matchOf(words))],
      )
      .get();
  return <String>[for (final QueryRow row in rows) row.read<String>('id')];
}

/// The stored sort keys of [recordId]'s search document, or null.
Future<({String projectId, String name, String identifier})?> searchDoc(
  AppDatabase db,
  String recordId,
) async {
  final QueryRow? row = await db
      .customSelect(
        'SELECT project_id, sort_name, identifier FROM record_search_docs '
        'WHERE record_id = ?',
        variables: <Variable<Object>>[Variable<String>(recordId)],
      )
      .getSingleOrNull();
  if (row == null) {
    return null;
  }
  return (
    projectId: row.read<String>('project_id'),
    name: row.read<String>('sort_name'),
    identifier: row.read<String>('identifier'),
  );
}

/// The stored status of [recordId].
Future<String> statusOf(AppDatabase db, String recordId) async {
  final QueryRow row = await db
      .customSelect(
        'SELECT status FROM records WHERE id = ?',
        variables: <Variable<Object>>[Variable<String>(recordId)],
      )
      .getSingle();
  return row.read<String>('status');
}

/// The stored number of [recordId].
Future<int?> numberOf(AppDatabase db, String recordId) async {
  final QueryRow row = await db
      .customSelect(
        'SELECT record_number FROM records WHERE id = ?',
        variables: <Variable<Object>>[Variable<String>(recordId)],
      )
      .getSingle();
  return row.read<int?>('record_number');
}

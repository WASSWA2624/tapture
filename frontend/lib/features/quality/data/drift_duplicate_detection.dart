import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/record_schema.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/records.dart'
    show RecordEntry, RecordPhoto;

import '../domain/duplicate_candidate.dart';
import '../domain/duplicate_detection.dart';
import '../domain/duplicate_subject.dart';

/// Detection over the local database (task 015).
///
/// Reads the stored identity hashes, the photos' content hashes and the
/// perceptual hashes processing cached beside them, then ranks with
/// [rankDuplicateCandidates]. Only reads: nothing here writes a row.
final class DriftDuplicateDetection implements DuplicateDetection {
  /// Creates detection over [db].
  const DriftDuplicateDetection(this._db);

  final AppDatabase _db;

  @override
  Future<List<DuplicateCandidate>> candidatesFor(RecordEntry record) async {
    final QueryRow? own = await _db
        .customSelect(
          'SELECT identity_hash FROM records WHERE id = ?',
          variables: <Variable<Object>>[Variable<String>(record.id)],
        )
        .getSingleOrNull();
    if (own == null) {
      return const <DuplicateCandidate>[];
    }
    final Map<String, _Photos> photos = await _photosOf(record.projectId);
    final _Photos mine =
        photos[record.id] ??
        _Photos(<String>{
          for (final RecordPhoto photo in record.photos) photo.sha256,
        }, <String>{});
    return rankDuplicateCandidates(
      recordId: record.id,
      identity: own.read<String>('identity_hash'),
      photoHashes: mine.content,
      perceptualHashes: mine.perceptual,
      templateRowId: record.templateRowId,
      context: record.context,
      name: record.name,
      capturedAt: record.capturedAt,
      others: await _subjects(record, photos),
    );
  }

  /// Every other live record of [record]'s project, as detection reads it.
  Future<List<DuplicateSubject>> _subjects(
    RecordEntry record,
    Map<String, _Photos> photos,
  ) async {
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT r.id AS id, r.identity_hash AS identity_hash, '
          'r.template_row_id AS template_row_id, '
          'r.context_json AS context_json, r.captured_at AS captured_at, '
          "COALESCE(sd.sort_name, '') AS name "
          'FROM records r '
          'LEFT JOIN ${RecordSchema.searchDocsTable} sd '
          'ON sd.record_id = r.id '
          'WHERE r.project_id = ? AND r.id <> ? AND r.status <> ? '
          'AND NOT EXISTS (SELECT 1 FROM tombstones t WHERE '
          "t.entity_type = 'records' AND t.entity_id = r.id)",
          variables: <Variable<Object>>[
            Variable<String>(record.projectId),
            Variable<String>(record.id),
            Variable<String>(RecordStatus.deleted.stored),
          ],
        )
        .get();
    return <DuplicateSubject>[
      for (final QueryRow row in rows)
        DuplicateSubject(
          recordId: row.read<String>('id'),
          identityHash: row.read<String>('identity_hash'),
          photoHashes: photos[row.read<String>('id')]?.content ?? <String>{},
          perceptualHashes:
              photos[row.read<String>('id')]?.perceptual ?? <String>{},
          templateRowId: row.read<String?>('template_row_id'),
          context: _context(row.read<String>('context_json')),
          name: row.read<String>('name'),
          capturedAt: row.read<DateTime>('captured_at'),
        ),
    ];
  }

  /// The content and perceptual hashes of every live filed photo in
  /// [projectId], by record.
  Future<Map<String, _Photos>> _photosOf(String projectId) async {
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT p.record_id AS record_id, p.sha256 AS sha256, '
          'oc.perceptual_hash AS perceptual_hash FROM photos p '
          'LEFT JOIN ocr_cache oc ON oc.content_hash = p.sha256 '
          'WHERE p.project_id = ? AND p.record_id IS NOT NULL '
          'AND $activePhotoCondition',
          variables: <Variable<Object>>[Variable<String>(projectId)],
        )
        .get();
    final Map<String, _Photos> byRecord = <String, _Photos>{};
    for (final QueryRow row in rows) {
      final _Photos photos = byRecord.putIfAbsent(
        row.read<String>('record_id'),
        () => _Photos(<String>{}, <String>{}),
      );
      photos.content.add(row.read<String>('sha256'));
      final String? perceptual = row.read<String?>('perceptual_hash');
      if (perceptual != null && perceptual.isNotEmpty) {
        photos.perceptual.add(perceptual);
      }
    }
    return byRecord;
  }
}

/// A record's photo hashes.
final class _Photos {
  _Photos(this.content, this.perceptual);

  final Set<String> content;
  final Set<String> perceptual;
}

/// The frozen context snapshot [json], level key to value.
Map<String, String> _context(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    return const <String, String>{};
  }
  if (decoded is! Map<String, Object?>) {
    return const <String, String>{};
  }
  return <String, String>{
    for (final MapEntry<String, Object?> entry in decoded.entries)
      if (entry.value != null) entry.key: '${entry.value}',
  };
}

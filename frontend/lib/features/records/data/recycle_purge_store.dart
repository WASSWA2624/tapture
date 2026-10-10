import 'package:drift/drift.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/record_schema.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/evidence_purge.dart';
import 'package:tapture/core/files/project_tree_purge_stub.dart'
    if (dart.library.io) 'package:tapture/core/files/project_tree_purge_io.dart'
    if (dart.library.js_interop) 'package:tapture/core/files/project_tree_purge_web.dart'
    as trees;
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/lifecycle/deleted_entity.dart';

import '../domain/purge_candidate.dart';
import 'record_purge_store.dart';

/// Explicit, confirmed permanent removal of the exact deletion shown in the bin.
/// Database ownership is collected before files or rows change. Failed file
/// removal keeps every row available for retry; shared hash caches survive.
final class RecyclePurgeStore {
  RecyclePurgeStore({
    required this._db,
    required this._files,
    required StorageRoot storageRoot,
    Future<Result<void>> Function(String folder)? purgeTree,
  }) : _purgeTree =
           purgeTree ??
           ((String folder) => trees.purgeProjectTree(storageRoot, folder)),
       _purgeMergeTree = ((String id) => trees.purgeMergeTree(storageRoot, id));

  final AppDatabase _db;
  final EvidencePurge _files;
  final Future<Result<void>> Function(String folder) _purgeTree;
  final Future<Result<void>> Function(String id) _purgeMergeTree;

  Future<Result<void>> purge(DeletedEntity entity) async {
    if (entity.kind == DeletedEntityKind.record) {
      final RecordPurgeStore records = RecordPurgeStore(db: _db, files: _files);
      final Result<List<PurgeCandidate>> listed = await records.candidates();
      if (listed case FailureResult<List<PurgeCandidate>>(:final failure)) {
        return FailureResult<void>(failure);
      }
      for (final PurgeCandidate candidate
          in (listed as Success<List<PurgeCandidate>>).value) {
        if (candidate.recordId == entity.id &&
            candidate.deletedAt.isAtSameMomentAs(entity.deletedAt) &&
            (entity.deletionId == null ||
                candidate.deletionId == entity.deletionId)) {
          return (await records.purge(
            candidate,
            explicit: true,
          )).map((int _) {});
        }
      }
      return FailureResult<void>(_staleFailure);
    }
    return runInTransaction<void>(
      _db,
      () => RecordSchema.deferIndexing(_db, () async {
        final String table = switch (entity.kind) {
          DeletedEntityKind.project => 'projects',
          DeletedEntityKind.photo => 'photos',
          _ => 'attachments',
        };
        final QueryRow? deletion = await _db
            .customSelect(
              'SELECT id, deleted_at FROM tombstones WHERE entity_type = ? AND entity_id = ?',
              variables: <Variable<Object>>[
                Variable<String>(table),
                Variable<String>(entity.id),
              ],
            )
            .getSingleOrNull();
        if (deletion == null ||
            (entity.deletionId != null &&
                deletion.read<String>('id') != entity.deletionId) ||
            !deletion
                .read<DateTime>('deleted_at')
                .isAtSameMomentAs(entity.deletedAt)) {
          throw _staleFailure;
        }

        final Map<String, Set<String>> owned = <String, Set<String>>{
          table: <String>{entity.id},
        };
        final List<Variable<Object>> project = <Variable<Object>>[
          Variable<String>(entity.id),
        ];
        if (entity.kind == DeletedEntityKind.project) {
          for (final TableInfo<Table, Object?> child in _db.allTables) {
            if (child.$columns.any(
              (GeneratedColumn<Object> column) => column.$name == 'project_id',
            )) {
              await _collect(
                owned,
                child.actualTableName,
                'project_id = ?',
                project,
              );
            }
          }
          await _collect(
            owned,
            'merge_sessions',
            "CASE WHEN json_valid(counts) THEN json_extract(counts, '\$.project_id') END = ?",
            project,
          );
          // A shared global template is never owned by this cascade. Refuse a
          // malformed cross-project reference rather than destroying its schema.
          final QueryRow external = await _db
              .customSelect(
                'SELECT COUNT(*) AS n FROM records r JOIN templates t ON t.id = r.template_id '
                'WHERE t.project_id = ? AND r.project_id <> ?',
                variables: <Variable<Object>>[...project, ...project],
              )
              .getSingle();
          if (external.read<int>('n') != 0) {
            throw _sharedFailure;
          }
          final QueryRow folder = (await _rows('projects', <String>{
            entity.id,
          })).single;
          final String folderName = folder.read<String>('folder_name');
          final QueryRow sharing = await _db
              .customSelect(
                'SELECT COUNT(*) AS n FROM projects WHERE folder_name = ? AND id <> ?',
                variables: <Variable<Object>>[
                  Variable<String>(folderName),
                  Variable<String>(entity.id),
                ],
              )
              .getSingle();
          if (folderName.isNotEmpty && sharing.read<int>('n') != 0) {
            throw _sharedFailure;
          }
        }
        await _expand(owned);
        if (entity.kind == DeletedEntityKind.project) {
          // Refuse malformed ownership links before any evidence is removed.
          for (final TableInfo<Table, Object?> child in _db.allTables) {
            if (child.$columns.any(
              (GeneratedColumn<Object> column) => column.$name == 'project_id',
            )) {
              for (final QueryRow row in await _rows(
                child.actualTableName,
                owned[child.actualTableName],
              )) {
                if (row.readNullable<String>('project_id') != entity.id) {
                  throw _sharedFailure;
                }
              }
            }
          }
        }
        final List<QueryRow> photos = await _rows('photos', owned['photos']);
        final List<QueryRow> attachments = await _rows(
          'attachments',
          owned['attachments'],
        );
        final List<PurgePhoto> purgingPhotos = <PurgePhoto>[];
        for (final QueryRow photo in photos) {
          final String id = photo.read<String>('id');
          final String hash = photo.read<String>('sha256');
          final List<QueryRow> sharing = await _db
              .customSelect(
                'SELECT id FROM photos WHERE sha256 = ?',
                variables: <Variable<Object>>[Variable<String>(hash)],
              )
              .get();
          final bool keepCache = sharing.any(
            (QueryRow row) =>
                !owned['photos']!.contains(row.read<String>('id')),
          );
          if (!keepCache) {
            await _collect(
              owned,
              'ocr_cache',
              'content_hash = ?',
              <Variable<Object>>[Variable<String>(hash)],
            );
          }
          purgingPhotos.add((
            photoId: id,
            sha256: hash,
            storagePath: await _path(photo),
            keepFile: await _sharedPath(photo, owned),
            keepCache: keepCache,
          ));
        }
        (await _files.removePhotos(purgingPhotos)).getOrThrow();
        final List<String> paths = <String>[];
        for (final QueryRow attachment in attachments) {
          if (!await _sharedPath(attachment, owned)) {
            paths.add(await _path(attachment));
          }
        }
        for (final QueryRow transcript in await _rows(
          'transcripts',
          owned['transcripts'],
        )) {
          final String path = transcript.read<String>('audio_path');
          if (path.startsWith('projects/')) {
            paths.add(path);
          }
        }
        (await _files.removeFiles(paths.toSet().toList())).getOrThrow();
        if (entity.kind == DeletedEntityKind.project) {
          final QueryRow row = (await _rows('projects', <String>{
            entity.id,
          })).single;
          final String folder = row.read<String>('folder_name');
          for (final String id in owned['merge_sessions'] ?? <String>{}) {
            (await _purgeMergeTree(id)).getOrThrow();
          }
          (await _purgeTree(folder)).getOrThrow();
        }
        await _metadata(owned);
        for (final MapEntry<String, Set<String>> entry
            in owned.entries.toList().reversed) {
          for (final List<String> ids in _chunks(entry.value)) {
            await _db.customUpdate(
              'DELETE FROM ${entry.key} WHERE id IN (${_slots(ids.length)})',
              variables: ids.map(Variable<String>.new).toList(),
              updates: _db.allTables
                  .where(
                    (TableInfo<Table, Object?> table) =>
                        table.actualTableName == entry.key,
                  )
                  .toSet(),
            );
          }
        }
      }),
    );
  }

  Future<void> _expand(Map<String, Set<String>> owned) async {
    bool changed;
    do {
      final int before = owned.values.fold(
        0,
        (int n, Set<String> ids) => n + ids.length,
      );
      for (final (String child, String column, String parent, String? condition)
          in _edges) {
        for (final List<String> ids in _chunks(owned[parent] ?? <String>{})) {
          await _collect(
            owned,
            child,
            '$column IN (${_slots(ids.length)})${condition == null ? '' : ' AND $condition'}',
            ids.map(Variable<String>.new).toList(),
          );
        }
      }
      changed =
          before !=
          owned.values.fold(0, (int n, Set<String> ids) => n + ids.length);
    } while (changed);
  }

  Future<void> _metadata(Map<String, Set<String>> owned) async {
    // Metadata can have its own vectors. Traverse only newly discovered ids.
    final Map<String, Set<String>> visited = <String, Set<String>>{};
    while (true) {
      final Map<String, Set<String>> next = <String, Set<String>>{
        for (final MapEntry<String, Set<String>> entry in owned.entries)
          entry.key: entry.value.difference(visited[entry.key] ?? <String>{}),
      }..removeWhere((String _, Set<String> ids) => ids.isEmpty);
      if (next.isEmpty) {
        return;
      }
      for (final MapEntry<String, Set<String>> entry in next.entries) {
        (visited[entry.key] ??= <String>{}).addAll(entry.value);
        for (final String table in <String>[
          'audit_log',
          'tombstones',
          'version_vectors',
          'merge_conflicts',
        ]) {
          for (final List<String> ids in _chunks(entry.value)) {
            await _collect(
              owned,
              table,
              'entity_type = ? AND entity_id IN (${_slots(ids.length)})',
              <Variable<Object>>[
                Variable<String>(entry.key),
                ...ids.map(Variable<String>.new),
              ],
            );
          }
        }
      }
    }
  }

  Future<void> _collect(
    Map<String, Set<String>> owned,
    String table,
    String where,
    List<Variable<Object>> variables,
  ) async {
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT id FROM $table WHERE $where',
          variables: variables,
        )
        .get();
    if (rows.isNotEmpty) {
      (owned[table] ??= <String>{}).addAll(
        rows.map((QueryRow row) => row.read<String>('id')),
      );
    }
  }

  Future<List<QueryRow>> _rows(String table, Set<String>? ids) async =>
      <QueryRow>[
        for (final List<String> chunk in _chunks(ids ?? <String>{}))
          ...await _db
              .customSelect(
                'SELECT * FROM $table WHERE id IN (${_slots(chunk.length)})',
                variables: chunk.map(Variable<String>.new).toList(),
              )
              .get(),
      ];

  Future<String> _path(QueryRow row) async {
    final QueryRow project = await _db
        .customSelect(
          'SELECT folder_name FROM projects WHERE id = ?',
          variables: <Variable<Object>>[
            Variable<String>(row.read<String>('project_id')),
          ],
        )
        .getSingle();
    return 'projects/${project.read<String>('folder_name')}/${row.read<String>('relative_path')}';
  }

  Future<bool> _sharedPath(QueryRow row, Map<String, Set<String>> owned) async {
    final String path = await _path(row);
    for (final String table in <String>['photos', 'attachments']) {
      final List<QueryRow> same = await _db
          .customSelect(
            "SELECT x.id FROM $table x JOIN projects p ON p.id = x.project_id WHERE 'projects/' || p.folder_name || '/' || x.relative_path = ?",
            variables: <Variable<Object>>[Variable<String>(path)],
          )
          .get();
      if (same.any(
        (QueryRow other) =>
            !(owned[table] ?? <String>{}).contains(other.read<String>('id')),
      )) {
        return true;
      }
    }
    return false;
  }
}

Iterable<List<String>> _chunks(Set<String> values) sync* {
  final List<String> ids = values.toList();
  const int size = 400;
  for (int start = 0; start < ids.length; start += size) {
    yield ids.sublist(
      start,
      start + size > ids.length ? ids.length : start + size,
    );
  }
}

String _slots(int count) => List<String>.filled(count, '?').join(',');

const List<(String, String, String, String?)> _edges =
    <(String, String, String, String?)>[
      ('record_fields', 'record_id', 'records', null),
      ('photos', 'record_id', 'records', null),
      ('field_evidence', 'record_field_id', 'record_fields', null),
      ('field_evidence', 'photo_id', 'photos', null),
      ('field_evidence', 'document_id', 'attachments', null),
      ('template_fields', 'template_id', 'templates', null),
      ('template_rows', 'template_id', 'templates', null),
      ('reference_rows', 'dataset_id', 'reference_datasets', null),
      ('captions', 'owner_id', 'records', "owner_type = 'record'"),
      ('captions', 'owner_id', 'photos', "owner_type = 'photo'"),
      ('attachment_owners', 'owner_id', 'records', "owner_type = 'record'"),
      ('attachment_owners', 'owner_id', 'photos', "owner_type = 'photo'"),
      ('attachment_owners', 'attachment_id', 'attachments', null),
      ('processing_jobs', 'record_id', 'records', null),
      ('processing_results', 'job_id', 'processing_jobs', null),
      ('meetings', 'record_id', 'records', null),
      ('attendees', 'meeting_id', 'meetings', null),
      ('meeting_actions', 'meeting_id', 'meetings', null),
      ('transcripts', 'owner_id', 'meetings', "owner_kind = 'meeting'"),
      ('transcripts', 'attachment_id', 'attachments', null),
      ('transcript_segments', 'transcript_id', 'transcripts', null),
      ('merge_conflicts', 'session_id', 'merge_sessions', null),
    ];

final StorageFailure _staleFailure = StorageFailure(
  localizedMessage: Copy.messages.failureThatRecordIsNoLongerInThe,
  localizedRecovery: Copy.messages.failureNothingToRemoveItWasRestoredOr,
);
final StorageFailure _sharedFailure = StorageFailure(
  localizedMessage: Copy.messages.recycleSharedData,
  localizedRecovery: Copy.messages.recycleSharedDataRecovery,
);

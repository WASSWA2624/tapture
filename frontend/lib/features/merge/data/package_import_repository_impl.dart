import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/record_schema.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/duplicates.dart';
import 'package:tapture/core/db/tables/merge.dart';
import 'package:tapture/core/db/tables/projects.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/project_folders.dart';
import 'package:tapture/core/files/storage_guard.dart';
import 'package:tapture/core/files/volume_stats.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/merge/domain/conflict_choice.dart';
import 'package:tapture/features/merge/domain/conflict_kind.dart';
import 'package:tapture/features/merge/domain/field_conflict.dart';
import 'package:tapture/features/merge/domain/merge_plan.dart';
import 'package:tapture/features/merge/domain/package_import_repository.dart';
import 'package:tapture/features/merge/domain/package_presence.dart';
import 'package:tapture/features/quality/quality.dart'
    hide ConflictChoice, FieldConflict;

import 'package_files.dart';

/// Brings project packages onto this device through Drift and
/// [PackageFiles] (task 076, W19 and W21).
///
/// Files are copied first, each checked against its checksum, to paths no
/// other file uses; then every row is written in one transaction. When
/// anything fails the transaction rolls back and the copied files are
/// removed, so the device is exactly as it was (FE-STATE-07).
///
/// The search index is rebuilt once per touched record before that
/// transaction commits, not once per inserted row
/// ([RecordSchema.deferIndexing]). Every record the package inserts or
/// changes gets one history row: entity `records`, field key `merge`, new
/// value `inserted` (action created) or `updated`, and the package name as
/// the reason (task 014 D10).
final class PackageImportRepositoryImpl implements PackageImportRepository {
  /// Opens against [_db] and [_files], stamping writes from [_clock],
  /// [_deviceId] and [_ids]. [_guard] checks headroom before a copy, and
  /// [_folders] lays out a new project's folders where a device has them.
  PackageImportRepositoryImpl({
    required this._db,
    required this._files,
    required this._clock,
    required this._deviceId,
    required this._ids,
    this._guard,
    this._folders,
  });

  final sqlite.AppDatabase _db;
  final PackageFiles _files;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;
  final StorageGuard? _guard;
  final ProjectFolders? _folders;

  @override
  Future<Result<PackagePresence>> presenceOf(String projectId) async {
    try {
      final QueryRow? project = await _db
          .customSelect(
            'SELECT status FROM projects WHERE id = ?',
            variables: <Variable<Object>>[Variable<String>(projectId)],
          )
          .getSingleOrNull();
      final QueryRow? tomb = await _db
          .customSelect(
            "SELECT 1 FROM tombstones WHERE entity_type = 'projects' "
            'AND entity_id = ?',
            variables: <Variable<Object>>[Variable<String>(projectId)],
          )
          .getSingleOrNull();
      if (tomb != null ||
          project?.read<String>('status') == ProjectStatus.deleted.name) {
        return const Success<PackagePresence>(PackagePresence.deleted);
      }
      return Success<PackagePresence>(
        project == null ? PackagePresence.absent : PackagePresence.live,
      );
    } on Object catch (error) {
      return FailureResult<PackagePresence>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<MergeGround>> groundFor({
    required String projectId,
    required Map<String, List<Map<String, Object?>>> incoming,
  }) async {
    try {
      final BundleTables? tables = await BundleTables.read(_db, projectId);
      if (tables == null) {
        return const FailureResult<MergeGround>(
          StorageFailure(
            message: Copy.packageProjectMissing,
            recoveryAction: Copy.importFailedRecovery,
          ),
        );
      }
      final Map<String, List<Map<String, Object?>>> local =
          <String, List<Map<String, Object?>>>{
            for (final MapEntry<String, List<Map<String, Object?>>> table
                in tables.rows.entries)
              table.key: List<Map<String, Object?>>.of(table.value),
          };
      await _addNamedDatasets(local, incoming);
      final Map<String, Set<String>> elsewhere = <String, Set<String>>{};
      for (final String table in BundleFormat.insertOrder) {
        if (table == 'projects') {
          continue;
        }
        final Set<String> here = <String>{
          for (final Map<String, Object?> row
              in local[table] ?? const <Map<String, Object?>>[])
            row['id']! as String,
        };
        final List<String> ids = <String>[
          for (final Map<String, Object?> row
              in incoming[table] ?? const <Map<String, Object?>>[])
            if (!here.contains(row['id'])) row['id']! as String,
        ];
        final Set<String> found = await _existing(table, ids);
        if (found.isNotEmpty) {
          elsewhere[table] = found;
        }
      }
      final List<QueryRow> settled = await _db
          .customSelect(
            'SELECT entity_type, entity_id, theirs_value, mine_meta '
            "FROM merge_conflicts WHERE resolution = 'mine'",
          )
          .get();
      final Set<String> decided = <String>{
        for (final QueryRow row in settled)
          '${_kindOf(row.read<String>('mine_meta'))}:'
              '${row.read<String>('entity_type')}:'
              '${row.read<String>('entity_id')}|'
              '${row.read<String>('theirs_value')}',
      };
      return Success<MergeGround>((
        local: local,
        elsewhere: elsewhere,
        decided: decided,
      ));
    } on Object catch (error) {
      return FailureResult<MergeGround>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<Map<String, List<Map<String, Object?>>>>> templatesOf(
    String projectId,
  ) async {
    try {
      final List<QueryRow> templates = await _db
          .customSelect(
            'SELECT * FROM templates WHERE project_id = ?',
            variables: <Variable<Object>>[Variable<String>(projectId)],
          )
          .get();
      final List<QueryRow> fields = await _db
          .customSelect(
            'SELECT * FROM template_fields WHERE template_id IN '
            '(SELECT id FROM templates WHERE project_id = ?)',
            variables: <Variable<Object>>[Variable<String>(projectId)],
          )
          .get();
      return Success<Map<String, List<Map<String, Object?>>>>(
        <String, List<Map<String, Object?>>>{
          'templates': <Map<String, Object?>>[
            for (final QueryRow row in templates)
              Map<String, Object?>.of(row.data),
          ],
          'template_fields': <Map<String, Object?>>[
            for (final QueryRow row in fields)
              Map<String, Object?>.of(row.data),
          ],
        },
      );
    } on Object catch (error) {
      return FailureResult<Map<String, List<Map<String, Object?>>>>(
        storageFailureFrom(error),
      );
    }
  }

  /// Adds the global reference datasets [incoming] carries that this device
  /// holds but the project does not name, so their rows merge by key.
  Future<void> _addNamedDatasets(
    Map<String, List<Map<String, Object?>>> local,
    Map<String, List<Map<String, Object?>>> incoming,
  ) async {
    final Set<String> here = <String>{
      for (final Map<String, Object?> row
          in local['reference_datasets'] ?? const <Map<String, Object?>>[])
        row['id']! as String,
    };
    final List<String> named = <String>[
      for (final Map<String, Object?> row
          in incoming['reference_datasets'] ?? const <Map<String, Object?>>[])
        if (!here.contains(row['id'])) row['id']! as String,
    ];
    for (final List<String> chunk in _chunks(named)) {
      final String marks = List<String>.filled(chunk.length, '?').join(', ');
      final List<Variable<Object>> ids = <Variable<Object>>[
        for (final String id in chunk) Variable<String>(id),
      ];
      final List<QueryRow> datasets = await _db
          .customSelect(
            'SELECT * FROM reference_datasets WHERE id IN ($marks)',
            variables: ids,
          )
          .get();
      final List<QueryRow> rows = await _db
          .customSelect(
            'SELECT * FROM reference_rows WHERE dataset_id IN ($marks)',
            variables: ids,
          )
          .get();
      local
          .putIfAbsent('reference_datasets', () => <Map<String, Object?>>[])
          .addAll(<Map<String, Object?>>[
            for (final QueryRow row in datasets)
              Map<String, Object?>.of(row.data),
          ]);
      local
          .putIfAbsent('reference_rows', () => <Map<String, Object?>>[])
          .addAll(<Map<String, Object?>>[
            for (final QueryRow row in rows) Map<String, Object?>.of(row.data),
          ]);
    }
  }

  /// Which of [ids] [table] already holds.
  Future<Set<String>> _existing(String table, List<String> ids) async {
    final Set<String> found = <String>{};
    for (final List<String> chunk in _chunks(ids)) {
      final List<QueryRow> rows = await _db
          .customSelect(
            'SELECT id FROM $table WHERE id IN '
            '(${List<String>.filled(chunk.length, '?').join(', ')})',
            variables: <Variable<Object>>[
              for (final String id in chunk) Variable<String>(id),
            ],
          )
          .get();
      found.addAll(<String>[for (final QueryRow row in rows) row.read('id')]);
    }
    return found;
  }

  @override
  Future<Result<ImportedProject>> importAsNew(
    InspectedBundle bundle, {
    void Function(double progress)? onProgress,
  }) async {
    final List<Map<String, Object?>> projects = bundle.rowsOf('projects');
    if (projects.length != 1) {
      return FailureResult<ImportedProject>(
        BundleReader.rejection(BundleRejection.missingEntry),
      );
    }
    final Map<String, Object?> source = projects.single;
    final String projectId = source['id']! as String;
    switch (await presenceOf(projectId)) {
      case FailureResult<PackagePresence>(:final Failure failure):
        return FailureResult<ImportedProject>(failure);
      case Success<PackagePresence>(value: PackagePresence.deleted):
        return const FailureResult<ImportedProject>(
          ValidationFailure(
            message: Copy.importProjectDeletedHere,
            recoveryAction: Copy.importProjectDeletedHereRecovery,
          ),
        );
      case Success<PackagePresence>(value: PackagePresence.live):
        return const FailureResult<ImportedProject>(
          ValidationFailure(
            message: Copy.importProjectAlreadyHere,
            recoveryAction: Copy.importProjectAlreadyHereRecovery,
          ),
        );
      case Success<PackagePresence>(value: PackagePresence.absent):
        break;
    }
    final String oldFolder = source['folder_name']! as String;
    final Set<String> entries = <String>{
      for (final BundleEntry entry in bundle.manifest.entries) entry.path,
    };
    final List<String> files = <String>{
      for (final String table in const <String>['photos', 'attachments'])
        for (final Map<String, Object?> row in bundle.rowsOf(table))
          if (entries.contains(row['relative_path']))
            row['relative_path']! as String,
      if (BundleTables(bundle.tables).coverPath case final String cover
          when entries.contains(cover))
        cover,
    }.toList();
    final Failure? room = await _room(bundle, files);
    if (room != null) {
      return FailureResult<ImportedProject>(room);
    }
    final String folder;
    try {
      folder = await _freeFolder(oldFolder);
    } on Object catch (error) {
      return FailureResult<ImportedProject>(storageFailureFrom(error));
    }
    final Map<String, Object?> project = <String, Object?>{
      ...source,
      'folder_name': folder,
      'settings': _movedCover(source['settings'], oldFolder, folder),
    };
    final List<String> written = <String>[];
    try {
      await _createTree(project);
      for (int index = 0; index < files.length; index++) {
        await _copy(
          bundle,
          entry: files[index],
          target: 'projects/$folder/${files[index]}',
          written: written,
        );
        onProgress?.call((index + 1) / files.length);
      }
      final int records = bundle.rowsOf('records').length;
      final Result<void> stored = await runInTransaction(
        _db,
        () => RecordSchema.deferIndexing(_db, () async {
          for (final String table in BundleFormat.insertOrder) {
            if (BundleFormat.referenceTables.contains(table)) {
              continue;
            }
            final List<Map<String, Object?>> rows = table == 'projects'
                ? <Map<String, Object?>>[project]
                : bundle.rowsOf(table);
            final Set<String> columns = await _columns(table);
            for (final Map<String, Object?> row in rows) {
              await _insert(table, row, columns);
            }
          }
          await _insertReference(bundle.tables);
          await _session(
            bundle,
            status: 'imported',
            counts: <String, Object?>{
              'project_id': projectId,
              'records': records,
              'photos': bundle.rowsOf('photos').length,
              'files': files.length,
            },
          );
          await _auditMerged(
            bundle,
            inserted: <String>[
              for (final Map<String, Object?> row in bundle.rowsOf('records'))
                row['id']! as String,
            ],
          );
        }),
      );
      if (stored case FailureResult<void>(
        failure: final Failure writeFailure,
      )) {
        throw writeFailure;
      }
      return Success<ImportedProject>((projectId: projectId, records: records));
    } on Object catch (error) {
      await _undo(written, folder: 'projects/$folder');
      return FailureResult<ImportedProject>(_failureOf(error));
    }
  }

  @override
  Future<Result<MergeOutcome>> merge({
    required InspectedBundle bundle,
    required String projectId,
    required MergePlan plan,
    required Map<String, ConflictChoice> choices,
    required List<PossibleDuplicate> duplicates,
    required Set<String> skipped,
    required String chooser,
    void Function(double progress)? onProgress,
  }) async {
    for (final FieldConflict conflict in plan.conflicts) {
      if (!choices.containsKey(conflict.id)) {
        return FailureResult<MergeOutcome>(
          ValidationFailure(
            message: Copy.mergeSettleConflicts(plan.conflicts.length),
            recoveryAction: Copy.importFailedRecovery,
          ),
        );
      }
    }
    final QueryRow? target = await _db
        .customSelect(
          'SELECT folder_name FROM projects WHERE id = ?',
          variables: <Variable<Object>>[Variable<String>(projectId)],
        )
        .getSingleOrNull();
    if (target == null) {
      return const FailureResult<MergeOutcome>(
        StorageFailure(
          message: Copy.packageProjectMissing,
          recoveryAction: Copy.importFailedRecovery,
        ),
      );
    }
    final String folder = target.read<String>('folder_name');
    final Failure? room = await _room(
      bundle,
      plan.files.map((({String entry, String target}) file) => file.entry),
    );
    if (room != null) {
      return FailureResult<MergeOutcome>(room);
    }
    final List<String> written = <String>[];
    try {
      final Map<String, String> moved = <String, String>{};
      for (int index = 0; index < plan.files.length; index++) {
        final ({String entry, String target}) file = plan.files[index];
        var landing = file.target;
        if (await _files.exists('projects/$folder/$landing')) {
          landing = _freePath(file.target);
          moved[file.target] = landing;
        }
        await _copy(
          bundle,
          entry: file.entry,
          target: 'projects/$folder/$landing',
          written: written,
        );
        onProgress?.call((index + 1) / plan.files.length);
      }
      final String sessionId = _ids.newId();
      final Result<void> stored = await runInTransaction(
        _db,
        () => RecordSchema.deferIndexing(_db, () async {
          for (final String table in BundleFormat.insertOrder) {
            final List<Map<String, Object?>> rows =
                plan.inserts[table] ?? const <Map<String, Object?>>[];
            if (rows.isEmpty) {
              continue;
            }
            final Set<String> columns = await _columns(table);
            for (final Map<String, Object?> row in rows) {
              final Object? path = row['relative_path'];
              await _insert(
                table,
                path is String && moved.containsKey(path)
                    ? <String, Object?>{...row, 'relative_path': moved[path]}
                    : row,
                columns,
              );
            }
          }
          for (final settled in plan.settled) {
            await _writeValue(
              rowId: settled.rowId,
              previous: settled.previous,
              value: settled.value,
              verified: settled.verified,
              reason: 'merge: ${settled.rule.name}',
              operator: chooser,
            );
          }
          await _session(
            bundle,
            id: sessionId,
            status: 'applied',
            counts: <String, Object?>{
              'project_id': projectId,
              'records': plan.counts.newRecords,
              'updated_records': plan.counts.updatedRecords,
              'photos': plan.counts.newPhotos,
              'photos_here': plan.counts.photosHere,
              'deletions': plan.counts.deletions,
              'conflicts': plan.conflicts.length,
              'kept': plan.counts.kept,
              'elsewhere': plan.counts.elsewhere,
              'duplicates': duplicates.length,
              'skipped': skipped.length,
            },
          );
          for (final FieldConflict conflict in plan.conflicts) {
            await _settle(
              conflict,
              choices[conflict.id]!,
              sessionId: sessionId,
              incoming: bundle.tables,
              chooser: chooser,
            );
          }
          for (final PossibleDuplicate pair in duplicates) {
            await _pair(pair, projectId, skipped: skipped, chooser: chooser);
          }
          await _auditMerged(
            bundle,
            inserted: <String>[
              for (final Map<String, Object?> row
                  in plan.inserts['records'] ?? const <Map<String, Object?>>[])
                row['id']! as String,
            ],
            updated: <String>[
              ...plan.updatedRecords,
              for (final FieldConflict conflict in plan.conflicts)
                if (choices[conflict.id] == ConflictChoice.theirs &&
                    conflict.recordId.isNotEmpty)
                  conflict.recordId,
            ],
            operator: chooser,
          );
        }),
      );
      if (stored case FailureResult<void>(
        failure: final Failure writeFailure,
      )) {
        throw writeFailure;
      }
      return Success<MergeOutcome>((
        sessionId: sessionId,
        records: plan.counts.newRecords,
      ));
    } on Object catch (error) {
      await _undo(written);
      return FailureResult<MergeOutcome>(_failureOf(error));
    }
  }

  /// Settles one conflict as [choice] says, with its stored conflict row and
  /// exactly one audit entry naming both values (FE-SEC-09).
  Future<void> _settle(
    FieldConflict conflict,
    ConflictChoice choice, {
    required String sessionId,
    required Map<String, List<Map<String, Object?>>> incoming,
    required String chooser,
  }) async {
    final bool theirs = choice == ConflictChoice.theirs;
    final String entityType = conflict.table;
    final String entityId = conflict.rowId;
    final Result<sqlite.MergeConflict> inserted = await insertMergeConflict(
      _db,
      row: sqlite.MergeConflictsCompanion.insert(
        sessionId: sessionId,
        entityType: entityType,
        entityId: entityId,
        fieldKey: conflict.fieldKey.isEmpty
            ? conflict.kind.name
            : conflict.fieldKey,
        mineValue: conflict.mine,
        theirsValue: conflict.theirs,
        mineMeta: jsonEncode(<String, Object?>{
          'kind': conflict.kind.name,
          'device': conflict.mineDevice,
          'at': conflict.mineAt,
        }),
        theirsMeta: jsonEncode(<String, Object?>{
          'device': conflict.theirsDevice,
          'at': conflict.theirsAt,
        }),
        createdAt: _clock.nowUtc(),
        updatedAt: _clock.nowUtc(),
        updatedByDevice: _deviceId,
      ),
      clock: _clock,
      deviceId: _deviceId,
      ids: _ids,
    );
    final String conflictId = _valueOf(inserted).id;
    _valueOf(
      await resolveMergeConflict(
        _db,
        id: conflictId,
        resolution: choice.name,
        resolvedBy: chooser,
        clock: _clock,
        deviceId: _deviceId,
        ids: _ids,
      ),
    );
    final String reason = theirs
        ? 'merge conflict: took incoming'
        : "merge conflict: kept this device's";
    switch (conflict.kind) {
      case ConflictKind.value:
        if (theirs) {
          await _writeValue(
            rowId: entityId,
            previous: conflict.mine,
            value: conflict.theirs,
            verified: true,
            verifiedBy: chooser,
            reason: reason,
            operator: chooser,
          );
          return;
        }
      case ConflictKind.caption:
        if (theirs) {
          await _update(
            'UPDATE captions SET text_refined = ?, refined_at = ?, '
            'updated_at = ?, updated_by_device = ?, rev = rev + 1 '
            'WHERE id = ?',
            <Object?>[conflict.theirs, _now, _now, _deviceId, entityId],
          );
        }
      case ConflictKind.status:
        // Merge is an exempt caller of the record lifecycle: the person
        // chose the incoming status, which is stored in its canonical
        // spelling and audited once, below.
        if (theirs) {
          await _update(
            'UPDATE records SET status = ?, updated_at = ?, '
            'updated_by_device = ?, rev = rev + 1 WHERE id = ?',
            <Object?>[
              canonicalRecordStatus(conflict.theirs),
              _now,
              _deviceId,
              entityId,
            ],
          );
        }
      case ConflictKind.deletedThere:
        if (theirs) {
          for (final Map<String, Object?> tomb
              in incoming['tombstones'] ?? const <Map<String, Object?>>[]) {
            if (tomb['entity_type'] == entityType &&
                tomb['entity_id'] == entityId) {
              await _insert('tombstones', tomb, await _columns('tombstones'));
            }
          }
        }
      case ConflictKind.deletedHere:
        if (theirs) {
          await _update(
            'DELETE FROM tombstones WHERE entity_type = ? AND entity_id = ?',
            <Object?>[entityType, entityId],
          );
        }
    }
    await appendAudit(
      _db,
      entityType: conflict.kind == ConflictKind.value ? 'records' : entityType,
      entityId: conflict.kind == ConflictKind.value
          ? conflict.recordId
          : entityId,
      action: switch (conflict.kind) {
        ConflictKind.deletedThere when theirs => AuditAction.deleted,
        ConflictKind.deletedHere when theirs => AuditAction.created,
        _ => AuditAction.updated,
      },
      fieldKey: conflict.fieldKey.isEmpty
          ? conflict.kind.name
          : conflict.fieldKey,
      previousValue: conflict.mine,
      newValue: theirs ? conflict.theirs : conflict.mine,
      reason: '$reason (incoming: ${conflict.theirs})',
      clock: _clock,
      device: _deviceId,
      operator: chooser,
    );
  }

  /// Appends one history row to each record the package [inserted] (action
  /// created) or [updated], inside the caller's transaction; a record in
  /// both is only inserted.
  Future<void> _auditMerged(
    InspectedBundle bundle, {
    required List<String> inserted,
    List<String> updated = const <String>[],
    String? operator,
  }) async {
    final Set<String> added = inserted.toSet();
    final Set<String> changed = <String>{
      for (final String id in updated)
        if (!added.contains(id)) id,
    };
    for (final (Set<String> ids, AuditAction action, String outcome)
        in <(Set<String>, AuditAction, String)>[
          (added, AuditAction.created, _mergeInserted),
          (changed, AuditAction.updated, _mergeUpdated),
        ]) {
      for (final String recordId in ids) {
        await appendAudit(
          _db,
          entityType: 'records',
          entityId: recordId,
          action: action,
          fieldKey: _mergeAuditKey,
          newValue: outcome,
          reason: bundle.name,
          clock: _clock,
          device: _deviceId,
          operator: operator,
        );
      }
    }
  }

  /// Writes a field's final value, leaving the captured one as it was
  /// (FE-SEC-08), with one audit entry naming both values.
  Future<void> _writeValue({
    required String rowId,
    required String previous,
    required String value,
    required bool verified,
    required String reason,
    required String operator,
    String? verifiedBy,
  }) async {
    final QueryRow? row = await _db
        .customSelect(
          'SELECT record_id, field_key FROM record_fields WHERE id = ?',
          variables: <Variable<Object>>[Variable<String>(rowId)],
        )
        .getSingleOrNull();
    if (row == null) {
      throw const StorageFailure(
        message: Copy.importFileChanged,
        recoveryAction: Copy.importFailedRecovery,
      );
    }
    await _update(
      'UPDATE record_fields SET value_final = ?, verified = ?, '
      'verified_by = COALESCE(?, verified_by), '
      'verified_at = CASE WHEN ? = 1 THEN ? ELSE verified_at END, '
      'updated_at = ?, updated_by_device = ?, rev = rev + 1 WHERE id = ?',
      <Object?>[
        value,
        verified ? 1 : 0,
        verifiedBy,
        verified ? 1 : 0,
        _now,
        _now,
        _deviceId,
        rowId,
      ],
    );
    await appendAudit(
      _db,
      entityType: 'records',
      entityId: row.read<String>('record_id'),
      action: AuditAction.updated,
      fieldKey: row.read<String>('field_key'),
      previousValue: previous,
      newValue: value,
      reason: reason,
      clock: _clock,
      device: _deviceId,
      operator: operator,
    );
  }

  /// Stores [pair] for a person's later review; a skipped incoming record
  /// is stored resolved, not imported (task 076, W22).
  Future<void> _pair(
    PossibleDuplicate pair,
    String projectId, {
    required Set<String> skipped,
    required String chooser,
  }) async {
    final sqlite.DuplicatePair stored = _valueOf(
      await upsertDetectedDuplicate(
        _db,
        row: sqlite.DuplicatesCompanion.insert(
          projectId: projectId,
          leftRecordId: pair.localId,
          rightRecordId: pair.incomingId,
          signal: pair.signal.name,
          score: pair.score,
          status: DuplicatePairStatus.unresolved,
          createdAt: _clock.nowUtc(),
          updatedAt: _clock.nowUtc(),
          updatedByDevice: _deviceId,
        ),
        clock: _clock,
        deviceId: _deviceId,
        ids: _ids,
      ),
    );
    if (skipped.contains(pair.incomingId)) {
      _valueOf(
        await resolveDuplicate(
          _db,
          id: stored.id,
          resolution: 'discard_new',
          resolvedBy: chooser,
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
        ),
      );
    }
  }

  Future<void> _session(
    InspectedBundle bundle, {
    required String status,
    required Map<String, Object?> counts,
    String? id,
  }) async {
    _valueOf(
      await insertMergeSession(
        _db,
        row: sqlite.MergeCompanion.insert(
          id: id == null ? const Value<String>.absent() : Value<String>(id),
          bundleName: bundle.name,
          sourceDevice: bundle.manifest.sourceDeviceId,
          importedAt: _clock.nowUtc(),
          counts: jsonEncode(<String, Object?>{
            ...counts,
            'bundle_id': bundle.manifest.bundleId,
          }),
          status: status,
          undoSnapshotPath: '',
          createdAt: _clock.nowUtc(),
          updatedAt: _clock.nowUtc(),
          updatedByDevice: _deviceId,
        ),
        clock: _clock,
        deviceId: _deviceId,
        ids: _ids,
      ),
    );
  }

  /// Reference datasets and rows, by the merge's rule: a dataset or a row
  /// key absent here is added; one present keeps this device's values.
  Future<void> _insertReference(
    Map<String, List<Map<String, Object?>>> tables,
  ) async {
    final Set<String> datasets = await _existing('reference_datasets', <String>[
      for (final Map<String, Object?> row
          in tables['reference_datasets'] ?? const <Map<String, Object?>>[])
        row['id']! as String,
    ]);
    final Set<String> datasetColumns = await _columns('reference_datasets');
    for (final Map<String, Object?> row
        in tables['reference_datasets'] ?? const <Map<String, Object?>>[]) {
      if (!datasets.contains(row['id'])) {
        await _insert('reference_datasets', row, datasetColumns);
      }
    }
    final Set<String> rowColumns = await _columns('reference_rows');
    for (final Map<String, Object?> row
        in tables['reference_rows'] ?? const <Map<String, Object?>>[]) {
      final QueryRow? here = await _db
          .customSelect(
            'SELECT 1 FROM reference_rows WHERE id = ? OR '
            '(dataset_id = ? AND key_value = ?)',
            variables: <Variable<Object>>[
              Variable<String>(row['id']! as String),
              Variable<String>(row['dataset_id']! as String),
              Variable<String>(row['key_value']! as String),
            ],
          )
          .getSingleOrNull();
      if (here == null) {
        await _insert('reference_rows', row, rowColumns);
      }
    }
  }

  /// Inserts [row] as it travelled, keeping only the columns [columns] this
  /// device's schema has.
  Future<void> _insert(
    String table,
    Map<String, Object?> row,
    Set<String> columns,
  ) async {
    final List<String> names = <String>[
      for (final String column in row.keys)
        if (columns.contains(column)) column,
    ];
    await _db.customInsert(
      'INSERT INTO $table (${names.map((String n) => '"$n"').join(', ')}) '
      'VALUES (${List<String>.filled(names.length, '?').join(', ')})',
      variables: <Variable<Object>>[
        for (final String name in names) _variable(row[name]),
      ],
    );
  }

  Future<void> _update(String sql, List<Object?> values) {
    return _db.customStatement(sql, values);
  }

  final Map<String, Set<String>> _columnCache = <String, Set<String>>{};

  Future<Set<String>> _columns(String table) async {
    final Set<String>? cached = _columnCache[table];
    if (cached != null) {
      return cached;
    }
    final List<QueryRow> rows = await _db
        .customSelect('PRAGMA table_info($table)')
        .get();
    return _columnCache[table] = <String>{
      for (final QueryRow row in rows) row.read<String>('name'),
    };
  }

  /// Copies one package entry to [target], checked against the checksum
  /// the package lists for it, so the file lands exactly as it left. The
  /// path joins [written] before the write starts, so an interrupted copy
  /// is removed too.
  Future<void> _copy(
    InspectedBundle bundle, {
    required String entry,
    required String target,
    required List<String> written,
  }) async {
    final Uint8List bytes = _valueOf(await bundle.readEntry(entry));
    written.add(target);
    final WrittenFile file = _valueOf(await _files.write(target, bytes));
    final String? expected = _checksums(bundle)[entry];
    if (expected == null || file.sha256 != expected) {
      throw const CorruptionFailure(
        message: Copy.importFileChanged,
        recoveryAction: Copy.importFailedRecovery,
      );
    }
  }

  final Expando<Map<String, String>> _sums = Expando<Map<String, String>>();

  Map<String, String> _checksums(InspectedBundle bundle) {
    return _sums[bundle] ??= <String, String>{
      for (final BundleEntry entry in bundle.manifest.entries)
        entry.path: entry.sha256,
    };
  }

  Future<void> _undo(List<String> written, {String? folder}) async {
    for (final String path in written) {
      try {
        await _files.remove(path);
      } on Object {
        // The next orphan scan finds anything left (task 067).
      }
    }
    if (folder != null) {
      try {
        await _files.removeFolder(folder);
      } on Object {
        // As above.
      }
    }
  }

  /// A failure when the files would leave less than the critical headroom.
  Future<Failure?> _room(InspectedBundle bundle, Iterable<String> paths) async {
    final StorageGuard? guard = _guard;
    if (guard == null) {
      return null;
    }
    final Map<String, int> sizes = <String, int>{
      for (final BundleEntry entry in bundle.manifest.entries)
        entry.path: entry.byteLength,
    };
    var needed = 0;
    for (final String path in paths) {
      needed += sizes[path] ?? 0;
    }
    final Result<VolumeStats> volume = await guard.volume();
    if (volume case Success<VolumeStats>(
      :final VolumeStats value,
    ) when value.freeBytes - needed < AppConstants.storage.criticalBytes) {
      return const StorageFailure(
        message: Copy.importNoRoom,
        recoveryAction: Copy.importNoRoomRecovery,
      );
    }
    return null;
  }

  /// [folder], or the first of `folder-2`, `folder-3`… no project here uses
  /// and no folder on disk holds.
  Future<String> _freeFolder(String folder) async {
    for (var attempt = 1; ; attempt++) {
      final String name = attempt == 1 ? folder : '$folder-$attempt';
      final QueryRow? taken = await _db
          .customSelect(
            'SELECT 1 FROM projects WHERE folder_name = ?',
            variables: <Variable<Object>>[Variable<String>(name)],
          )
          .getSingleOrNull();
      if (taken == null && !await _files.exists('projects/$name')) {
        return name;
      }
    }
  }

  Future<void> _createTree(Map<String, Object?> project) async {
    final ProjectFolders? folders = _folders;
    if (folders == null) {
      return;
    }
    final DateTime epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    _valueOf(
      await folders.create(
        sqlite.Project(
          id: project['id']! as String,
          createdAt: epoch,
          updatedAt: epoch,
          updatedByDevice: '',
          rev: 1,
          name: '${project['name'] ?? ''}',
          client: '',
          status: ProjectStatus.active,
          folderName: project['folder_name']! as String,
          settings: '{}',
        ),
      ),
    );
  }

  int get _now => _clock.nowUtc().millisecondsSinceEpoch ~/ 1000;
}

/// The project's settings with the cover photo's path moved from [from] to
/// [to]'s folder.
Object? _movedCover(Object? settings, String from, String to) {
  if (settings is! String || from == to) {
    return settings;
  }
  try {
    final Object? decoded = jsonDecode(settings);
    if (decoded is! Map<String, Object?>) {
      return settings;
    }
    final Object? cover = decoded['coverPhoto'];
    if (cover is! Map<String, Object?>) {
      return settings;
    }
    final Object? path = cover['path'];
    final String prefix = 'projects/$from/';
    if (path is! String || !path.startsWith(prefix)) {
      return settings;
    }
    return jsonEncode(<String, Object?>{
      ...decoded,
      'coverPhoto': <String, Object?>{
        ...cover,
        'path': 'projects/$to/${path.substring(prefix.length)}',
      },
    });
  } on FormatException {
    return settings;
  }
}

/// Audit `field_key` of a record a package inserted or changed.
const String _mergeAuditKey = 'merge';

/// New value of the merge audit row of a record the package inserted.
const String _mergeInserted = 'inserted';

/// New value of the merge audit row of a record the package changed.
const String _mergeUpdated = 'updated';

/// A path beside [path] no other file uses: `<folder>/_merged/<n>-<name>`.
String _freePath(String path) {
  final int slash = path.lastIndexOf('/');
  final String folder = slash < 0 ? '' : path.substring(0, slash + 1);
  final String name = slash < 0 ? path : path.substring(slash + 1);
  return '${folder}_merged/${DateTime.now().microsecondsSinceEpoch}-$name';
}

String _kindOf(String meta) {
  try {
    final Object? decoded = jsonDecode(meta);
    if (decoded is Map<String, Object?> && decoded['kind'] is String) {
      return decoded['kind']! as String;
    }
  } on FormatException {
    // Written by an older merge: no kind to match.
  }
  return '';
}

Variable<Object> _variable(Object? value) {
  return switch (value) {
    null => const Variable<Object>(null),
    final bool flag => Variable<int>(flag ? 1 : 0),
    final int number => Variable<int>(number),
    final double number => Variable<double>(number),
    final String text => Variable<String>(text),
    _ => Variable<String>(jsonEncode(value)),
  };
}

Iterable<List<String>> _chunks(List<String> ids) sync* {
  const int size = 500;
  for (var start = 0; start < ids.length; start += size) {
    yield ids.sublist(
      start,
      start + size > ids.length ? ids.length : start + size,
    );
  }
}

T _valueOf<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(failure: final Failure resultFailure) =>
      throw resultFailure,
  };
}

Failure _failureOf(Object error) {
  if (error is CancelledFailure ||
      error is ValidationFailure ||
      error is CorruptionFailure) {
    return error as Failure;
  }
  final StorageFailure failure = storageFailureFrom(error);
  return StorageFailure(
    message: failure.message,
    recoveryAction: Copy.importFailedRecovery,
  );
}

/// The device's package import. Tests leave this empty and pass a fake.
final Provider<PackageImportRepository?> packageImportRepositoryProvider =
    Provider<PackageImportRepository?>((Ref _) => null);

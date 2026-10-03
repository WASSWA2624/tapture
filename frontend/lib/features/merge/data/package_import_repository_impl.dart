import 'dart:async';
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
import 'package:tapture/core/db/version_vector_schema.dart';
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
import 'package:tapture/features/templates/templates.dart'
    show FieldDef, TemplateDef, TemplateMapper, TemplateVersioning;

import 'merge_repository_impl.dart';
import 'merge_snapshot_store.dart';
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

  /// History shares the applying repository's database and evidence store.
  late final MergeRepositoryImpl historyRepository = MergeRepositoryImpl(
    db: _db,
    files: _files,
    clock: _clock,
    deviceId: _deviceId,
  );

  @override
  Future<Result<void>> validateTypedValue(
    FieldConflict conflict,
    String value,
  ) async {
    try {
      await _validateTyped(conflict, value);
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(_failureOf(error));
    }
  }

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
        return FailureResult<MergeGround>(
          StorageFailure(
            localizedMessage: Copy.messages.packageProjectMissing,
            localizedRecovery: Copy.messages.importFailedRecovery,
          ),
        );
      }
      final Map<String, List<Map<String, Object?>>> local =
          <String, List<Map<String, Object?>>>{
            for (final MapEntry<String, List<Map<String, Object?>>> table
                in tables.mergeRows.entries)
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
              '${row.read<String>('entity_id')}'
              '${_referenceIdentity(row.read<String>('mine_meta'))}|'
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
        return FailureResult<ImportedProject>(
          ValidationFailure(
            localizedMessage: Copy.messages.importProjectDeletedHere,
            localizedRecovery: Copy.messages.importProjectDeletedHereRecovery,
          ),
        );
      case Success<PackagePresence>(value: PackagePresence.live):
        return FailureResult<ImportedProject>(
          ValidationFailure(
            localizedMessage: Copy.messages.importProjectAlreadyHere,
            localizedRecovery: Copy.messages.importProjectAlreadyHereRecovery,
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
          await VersionVectorSchema.remoteWrites(_db, () async {
            for (final String table in BundleFormat.insertOrder) {
              if (BundleFormat.referenceTables.contains(table)) {
                continue;
              }
              final List<Map<String, Object?>> rows = switch (table) {
                'projects' => <Map<String, Object?>>[project],
                'records' => _onTemplateVersions(
                  bundle.rowsOf(table),
                  bundle.rowsOf('templates'),
                ),
                _ => bundle.rowsOf(table),
              };
              final Set<String> columns = await _columns(table);
              for (final Map<String, Object?> row in rows) {
                await _insert(table, row, columns);
              }
            }
            await _insertReference(bundle.tables);
            await _mergeVectors(bundle, projectId);
          });
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
    Map<String, String> typedValues = const <String, String>{},
    void Function(double progress)? onProgress,
  }) async {
    for (final FieldConflict conflict in plan.conflicts) {
      if (!choices.containsKey(conflict.id)) {
        return FailureResult<MergeOutcome>(
          ValidationFailure(
            localizedMessage: Copy.messages.mergeSettleConflicts(
              plan.conflicts.length,
            ),
            localizedRecovery: Copy.messages.importFailedRecovery,
          ),
        );
      }
      if (choices[conflict.id] == ConflictChoice.typed) {
        final Result<void> valid = await validateTypedValue(
          conflict,
          typedValues[conflict.id] ?? '',
        );
        if (!typedValues.containsKey(conflict.id) ||
            valid is FailureResult<void>) {
          return FailureResult<MergeOutcome>(
            valid is FailureResult<void>
                ? valid.failure
                : ValidationFailure(
                    localizedMessage: Copy.messages.conflictTypeValue,
                    localizedRecovery: Copy.messages.importFailedRecovery,
                  ),
          );
        }
      }
    }
    final QueryRow? target = await _db
        .customSelect(
          'SELECT folder_name FROM projects WHERE id = ?',
          variables: <Variable<Object>>[Variable<String>(projectId)],
        )
        .getSingleOrNull();
    if (target == null) {
      return FailureResult<MergeOutcome>(
        StorageFailure(
          localizedMessage: Copy.messages.packageProjectMissing,
          localizedRecovery: Copy.messages.importFailedRecovery,
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
      final String snapshotPath = 'projects/$folder/.merge/$sessionId.json';
      final MergeSnapshotStore snapshots = MergeSnapshotStore(_db, _files);
      final Result<void> stored = await runInTransaction(
        _db,
        () => RecordSchema.deferIndexing(_db, () async {
          final SnapshotRows before = await snapshots.capture(
            projectId,
            bundle.tables,
          );
          final Set<({String table, String id})> decisions =
              <({String table, String id})>{};
          written.add(snapshotPath);
          await snapshots.publish(
            path: snapshotPath,
            projectId: projectId,
            before: before,
            after: const <String, List<Map<String, Object?>>>{},
            importedFiles: written
                .where((String path) => path != snapshotPath)
                .toList(),
          );
          await VersionVectorSchema.remoteWrites(_db, () async {
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
            await _advanceRows(plan.updates, chooser: chooser);
          });
          for (final settled in plan.settled) {
            decisions.add((table: 'record_fields', id: settled.rowId));
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
            snapshotPath: snapshotPath,
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
          final Map<String, Map<String, String>> vectorAliases =
              <String, Map<String, String>>{};
          for (final FieldConflict conflict in plan.conflicts) {
            await _settle(
              conflict,
              choices[conflict.id]!,
              sessionId: sessionId,
              incoming: bundle.tables,
              chooser: chooser,
              typedValue: typedValues[conflict.id],
              insertedRecords: plan.insertedRecords.toSet(),
              vectorAliases: vectorAliases,
              decisions: decisions,
            );
          }
          for (final PossibleDuplicate pair in duplicates) {
            await _pair(pair, projectId, skipped: skipped, chooser: chooser);
          }
          await VersionVectorSchema.remoteWrites(
            _db,
            () async => _mergeVectors(
              bundle,
              projectId,
              aliases: vectorAliases,
              deferred: <String>{
                for (final FieldConflict conflict in plan.conflicts)
                  if (choices[conflict.id] == ConflictChoice.later)
                    '${conflict.table}/${conflict.rowId}',
                for (final FieldConflict conflict in plan.conflicts)
                  if (choices[conflict.id] == ConflictChoice.later &&
                      conflict.incomingRowId != null)
                    '${conflict.table}/${conflict.incomingRowId}',
              },
            ),
          );
          await _advanceDecisionVectors(
            bundle,
            before: before,
            decisions: decisions,
            aliases: vectorAliases,
          );
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
                if ((choices[conflict.id] == ConflictChoice.theirs ||
                        choices[conflict.id] == ConflictChoice.typed) &&
                    conflict.recordId.isNotEmpty)
                  conflict.recordId,
            ],
            operator: chooser,
          );
          await snapshots.publish(
            path: snapshotPath,
            projectId: projectId,
            before: before,
            after: await snapshots.capture(projectId, bundle.tables),
            importedFiles: written
                .where((String path) => path != snapshotPath)
                .toList(),
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
    String? typedValue,
    Set<String> insertedRecords = const <String>{},
    Map<String, Map<String, String>>? vectorAliases,
    required Set<({String table, String id})> decisions,
  }) async {
    if ((choice == ConflictChoice.keepBoth &&
            conflict.kind != ConflictKind.template) ||
        (conflict.kind == ConflictKind.template &&
            (choice == ConflictChoice.later ||
                (!conflict.allowChooseOne &&
                    choice != ConflictChoice.keepBoth)))) {
      throw ValidationFailure(
        localizedMessage: Copy.messages.importFileChanged,
        localizedRecovery: Copy.messages.importFailedRecovery,
      );
    }
    final bool theirs = choice == ConflictChoice.theirs;
    if (choice == ConflictChoice.typed) {
      await _validateTyped(conflict, typedValue);
    }
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
          if (conflict.incomingRowId != null)
            'incoming_row_id': conflict.incomingRowId,
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
    if (choice == ConflictChoice.later) {
      // Null resolution is durable and continues to block approval.
      return;
    }
    decisions.add((table: entityType, id: entityId));
    final List<QueryRow> equivalent = await _db
        .customSelect(
          'SELECT id FROM merge_conflicts WHERE resolution IS NULL '
          'AND entity_type = ? AND entity_id = ? AND field_key = ? '
          'AND mine_value = ? AND theirs_value = ?',
          variables: <Variable<Object>>[
            Variable<String>(entityType),
            Variable<String>(entityId),
            Variable<String>(
              conflict.fieldKey.isEmpty
                  ? conflict.kind.name
                  : conflict.fieldKey,
            ),
            Variable<String>(conflict.mine),
            Variable<String>(conflict.theirs),
          ],
        )
        .get();
    for (final QueryRow unresolved in equivalent) {
      final String resolvedId = unresolved.read<String>('id');
      _valueOf(
        await resolveMergeConflict(
          _db,
          id: resolvedId,
          resolution: choice.name,
          resolvedBy: chooser,
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
        ),
      );
      if (resolvedId != conflictId) {
        await appendAudit(
          _db,
          entityType: 'merge_conflicts',
          entityId: resolvedId,
          action: AuditAction.updated,
          fieldKey: 'resolution',
          newValue: choice.name,
          reason: 'merge conflict: settled earlier deferred choice',
          clock: _clock,
          device: _deviceId,
          operator: chooser,
        );
      }
    }
    final String chosenValue = choice == ConflictChoice.typed
        ? typedValue!
        : conflict.theirs;
    final bool replace = theirs || choice == ConflictChoice.typed;
    final String reason = choice == ConflictChoice.keepBoth
        ? 'merge conflict: kept both templates'
        : choice == ConflictChoice.typed
        ? 'merge conflict: typed a replacement'
        : theirs
        ? 'merge conflict: took incoming'
        : "merge conflict: kept this device's";
    switch (conflict.kind) {
      case ConflictKind.value:
        if (replace) {
          await _writeValue(
            rowId: entityId,
            previous: conflict.mine,
            value: chosenValue,
            verified: true,
            verifiedBy: chooser,
            reason: reason,
            operator: chooser,
          );
          return;
        }
      case ConflictKind.caption:
        if (replace) {
          await _update(
            'UPDATE captions SET text_refined = ?, refined_at = ?, '
            'updated_at = ?, updated_by_device = ?, rev = rev + 1 '
            'WHERE id = ?',
            <Object?>[chosenValue, _now, _now, _deviceId, entityId],
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
      case ConflictKind.template:
        await _settleTemplate(
          conflict,
          choice,
          incoming,
          insertedRecords: insertedRecords,
          aliases: vectorAliases ?? <String, Map<String, String>>{},
          decisions: decisions,
        );
      case ConflictKind.reference:
        final String peerId = conflict.incomingRowId ?? entityId;
        if (vectorAliases != null) {
          (vectorAliases['reference_rows'] ??= <String, String>{})[peerId] =
              entityId;
        }
        if (theirs) {
          final Map<String, Object?> peer = incoming['reference_rows']!
              .firstWhere((Map<String, Object?> row) => row['id'] == peerId);
          await _update(
            'UPDATE reference_rows SET "values" = ?, '
            'updated_at = ?, updated_by_device = ?, rev = rev + 1 WHERE id = ?',
            <Object?>[peer['values'], _now, _deviceId, entityId],
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
      newValue: replace || choice == ConflictChoice.keepBoth
          ? chosenValue
          : conflict.mine,
      reason: '$reason (incoming: ${conflict.theirs})',
      clock: _clock,
      device: _deviceId,
      operator: chooser,
    );
  }

  Future<void> _settleTemplate(
    FieldConflict conflict,
    ConflictChoice choice,
    Map<String, List<Map<String, Object?>>> incoming, {
    required Set<String> insertedRecords,
    required Map<String, Map<String, String>> aliases,
    required Set<({String table, String id})> decisions,
  }) async {
    final sqlite.Template here =
        await (_db.select(
              _db.templates,
            )..where((sqlite.$TemplatesTable t) => t.id.equals(conflict.rowId)))
            .getSingle();
    final List<sqlite.TemplateField> fields =
        await (_db.select(_db.templateFields)..where(
              (sqlite.$TemplateFieldsTable t) => t.templateId.equals(here.id),
            ))
            .get();
    final List<sqlite.TemplateRow> rows =
        await (_db.select(_db.templateRows)..where(
              (sqlite.$TemplateRowsTable t) => t.templateId.equals(here.id),
            ))
            .get();
    final Map<String, Object?> header = incoming['templates']!.firstWhere(
      (Map<String, Object?> t) => t['id'] == here.id,
    );
    final List<Map<String, Object?>> peerFields = <Map<String, Object?>>[
      for (final Map<String, Object?> row
          in incoming['template_fields'] ?? const [])
        if (row['template_id'] == here.id) row,
    ];
    final List<Map<String, Object?>> peerRows = <Map<String, Object?>>[
      for (final Map<String, Object?> row
          in incoming['template_rows'] ?? const [])
        if (row['template_id'] == here.id) row,
    ];
    final TemplateDef mine = TemplateMapper.fromRows(
      header: here,
      fields: fields,
      rows: rows,
    );
    final TemplateDef peer = TemplateMapper.fromRows(
      header: _db.templates.map(header),
      fields: <sqlite.TemplateField>[
        for (final Map<String, Object?> row in peerFields)
          _db.templateFields.map(row),
      ],
      rows: <sqlite.TemplateRow>[
        for (final Map<String, Object?> row in peerRows)
          _db.templateRows.map(row),
      ],
    );
    if (choice == ConflictChoice.keepBoth) {
      final String copyId = _ids.newId();
      decisions.add((table: 'templates', id: copyId));
      final Object? decoded = jsonDecode('${header['detection'] ?? '{}'}');
      final Map<String, Object?> detection = <String, Object?>{
        if (decoded is Map) ...decoded.cast<String, Object?>(),
        '_tapture_merge_source': <String, Object?>{
          'id': here.id,
          'shape': conflict.theirs,
        },
      };
      await _insert('templates', <String, Object?>{
        ...header,
        'id': copyId,
        'project_id': here.projectId,
        'detection': jsonEncode(detection),
        'created_at': _now,
        'updated_at': _now,
        'updated_by_device': _deviceId,
        'rev': 1,
      }, await _columns('templates'));
      (aliases['templates'] ??= <String, String>{})[here.id] = copyId;
      for (final String table in const <String>[
        'template_fields',
        'template_rows',
      ]) {
        final Set<String> columns = await _columns(table);
        for (final Map<String, Object?> row
            in table == 'template_fields' ? peerFields : peerRows) {
          final String childId = _ids.newId();
          decisions.add((table: table, id: childId));
          await _insert(table, <String, Object?>{
            ...row,
            'id': childId,
            'template_id': copyId,
            'created_at': _now,
            'updated_at': _now,
            'updated_by_device': _deviceId,
            'rev': 1,
          }, columns);
          (aliases[table] ??= <String, String>{})[row['id']! as String] =
              childId;
        }
      }
      for (final Map<String, Object?> record
          in incoming['records'] ?? const []) {
        if (record['template_id'] == here.id &&
            insertedRecords.contains(record['id'])) {
          decisions.add((table: 'records', id: record['id']! as String));
          await _update(
            'UPDATE records SET template_id = ?, updated_at = ?, '
            'updated_by_device = ?, rev = rev + 1 WHERE id = ?',
            <Object?>[copyId, _now, _deviceId, record['id']],
          );
        }
      }
      return;
    }
    final bool theirs = choice == ConflictChoice.theirs;
    final TemplateDef remembered = TemplateVersioning.remember(
      from: theirs ? mine : peer,
      to: theirs ? peer : mine,
    );
    final TemplateDef selected = remembered.copyWith(
      detection: <String, Object?>{
        ...remembered.detection,
        '_tapture_merge_shapes': <String, Object?>{
          if (mine.detection['_tapture_merge_shapes'] is Map)
            ...(mine.detection['_tapture_merge_shapes']! as Map)
                .cast<String, Object?>(),
          if (peer.detection['_tapture_merge_shapes'] is Map)
            ...(peer.detection['_tapture_merge_shapes']! as Map)
                .cast<String, Object?>(),
          '${mine.version}': conflict.mine,
          '${peer.version}': conflict.theirs,
        },
      },
    );
    final sqlite.TemplatesCompanion stored =
        TemplateMapper.headerToRow(selected).copyWith(
          projectId: Value<String?>(here.projectId),
          updatedAt: Value<DateTime>(_clock.nowUtc()),
          updatedByDevice: Value<String>(_deviceId),
          rev: Value<int>(here.rev + 1),
        );
    await (_db.update(
      _db.templates,
    )..where((sqlite.$TemplatesTable t) => t.id.equals(here.id))).write(stored);
    if (theirs) {
      for (final String table in const <String>[
        'template_fields',
        'template_rows',
      ]) {
        await _db.customStatement(
          'DELETE FROM $table WHERE template_id = ?',
          <Object?>[here.id],
        );
        final Set<String> columns = await _columns(table);
        for (final Map<String, Object?> row
            in table == 'template_fields' ? peerFields : peerRows) {
          decisions.add((table: table, id: row['id']! as String));
          await _insert(table, <String, Object?>{
            ...row,
            'updated_at': _now,
            'updated_by_device': _deviceId,
            'rev': (row['rev'] as int? ?? 1) + 1,
          }, columns);
        }
      }
    }
  }

  Future<void> _validateTyped(FieldConflict conflict, String? value) async {
    if (value == null ||
        (conflict.kind != ConflictKind.value &&
            conflict.kind != ConflictKind.caption)) {
      throw ValidationFailure(
        localizedMessage: Copy.messages.conflictTypeValue,
        localizedRecovery: Copy.messages.importFailedRecovery,
      );
    }
    if (conflict.kind == ConflictKind.caption) {
      return;
    }
    final QueryRow? record = await _db
        .customSelect(
          'SELECT template_id FROM records WHERE id = ?',
          variables: <Variable<Object>>[Variable<String>(conflict.recordId)],
        )
        .getSingleOrNull();
    final sqlite.TemplateField? stored = record == null
        ? null
        : await (_db.select(_db.templateFields)..where(
                (sqlite.$TemplateFieldsTable table) =>
                    table.templateId.equals(
                      record.read<String>('template_id'),
                    ) &
                    table.fieldKey.equals(conflict.fieldKey),
              ))
              .getSingleOrNull();
    if (stored == null) {
      throw ValidationFailure(
        localizedMessage: Copy.messages.importFileChanged,
        localizedRecovery: Copy.messages.importFailedRecovery,
      );
    }
    final FieldDef field = TemplateMapper.fieldFromRow(stored);
    final List<QueryRow> siblings = await _db
        .customSelect(
          'SELECT field_key, value_final, value_raw FROM record_fields WHERE record_id = ?',
          variables: <Variable<Object>>[Variable<String>(conflict.recordId)],
        )
        .get();
    final issues = RecordRules.validateField(field, value, <String, Object?>{
      for (final QueryRow sibling in siblings)
        sibling.read<String>('field_key'):
            sibling.data['value_final'] ?? sibling.data['value_raw'],
      field.fieldKey: value,
    });
    for (final issue in issues) {
      if (issue.blocks) {
        throw ValidationFailure(
          message: issue.message,
          localizedMessage: issue.localizedMessage,
          localizedRecovery: Copy.messages.importFailedRecovery,
        );
      }
    }
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
      throw StorageFailure(
        localizedMessage: Copy.messages.importFileChanged,
        localizedRecovery: Copy.messages.importFailedRecovery,
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
    String snapshotPath = '',
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
            'lineage': bundle.manifest.toJson()['lineage'],
          }),
          status: status,
          undoSnapshotPath: snapshotPath,
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

  /// Joins observed clocks only for admitted entities. Deferred edits keep
  /// their incoming component pending so a later reimport can settle them.
  Future<void> _mergeVectors(
    InspectedBundle bundle,
    String projectId, {
    Set<String> deferred = const <String>{},
    Map<String, Map<String, String>> aliases =
        const <String, Map<String, String>>{},
  }) async {
    if (bundle.manifest.versionVectors.isEmpty) return;
    final BundleTables? admitted = await BundleTables.read(_db, projectId);
    if (admitted == null) return;
    final Map<String, Set<Object?>> ids = <String, Set<Object?>>{
      for (final table in admitted.rows.entries)
        table.key: table.value
            .map((Map<String, Object?> row) => row['id'])
            .toSet(),
    };
    final int now = _clock.nowUtc().millisecondsSinceEpoch ~/ 1000;
    final List<List<Object?>> values = <List<Object?>>[
      for (final table in bundle.manifest.versionVectors.entries)
        for (final entity in table.value.entries)
          if ((ids[table.key]?.contains(
                    aliases[table.key]?[entity.key] ?? entity.key,
                  ) ??
                  false) &&
              !deferred.contains('${table.key}/${entity.key}'))
            for (final counter in entity.value.entries)
              <Object?>[
                _ids.newId(),
                table.key,
                aliases[table.key]?[entity.key] ?? entity.key,
                counter.key,
                counter.value,
                now,
                now,
                _deviceId,
                1,
              ],
    ];
    await _storeVectors(values);
  }

  /// A resolution is authored after both histories were observed. Preserve
  /// any trigger increments, but lift its counter above a received component
  /// for this device, even when the peer observed a newer counter than ours.
  /// The snapshot supplies the previous counter without additional row reads.
  Future<void> _advanceDecisionVectors(
    InspectedBundle bundle, {
    required SnapshotRows before,
    required Set<({String table, String id})> decisions,
    required Map<String, Map<String, String>> aliases,
  }) async {
    if (decisions.isEmpty) return;
    final Map<({String table, String id}), int> floors =
        <({String table, String id}), int>{
          for (final entity in decisions) entity: 1,
        };
    for (final Map<String, Object?> vector
        in before['version_vectors'] ?? const <Map<String, Object?>>[]) {
      if (vector['device_id'] != _deviceId) continue;
      final entity = (
        table: vector['entity_type']! as String,
        id: vector['entity_id']! as String,
      );
      if (!decisions.contains(entity)) continue;
      floors[entity] = (vector['seen_rev']! as int) + 1;
    }
    for (final table in bundle.manifest.versionVectors.entries) {
      for (final incoming in table.value.entries) {
        final entity = (
          table: table.key,
          id: aliases[table.key]?[incoming.key] ?? incoming.key,
        );
        final int? observed = incoming.value[_deviceId];
        if (!decisions.contains(entity) || observed == null) continue;
        if (observed + 1 > floors[entity]!) {
          floors[entity] = observed + 1;
        }
      }
    }
    final int now = _clock.nowUtc().millisecondsSinceEpoch ~/ 1000;
    await _storeVectors(<List<Object?>>[
      for (final entry in floors.entries)
        <Object?>[
          _ids.newId(),
          entry.key.table,
          entry.key.id,
          _deviceId,
          entry.value,
          now,
          now,
          _deviceId,
          1,
        ],
    ]);
  }

  Future<void> _storeVectors(List<List<Object?>> values) async {
    for (int offset = 0; offset < values.length; offset += 80) {
      final List<List<Object?>> chunk = values.sublist(
        offset,
        offset + 80 < values.length ? offset + 80 : values.length,
      );
      await _db.customStatement(
        'INSERT INTO version_vectors (id, entity_type, entity_id, device_id, '
        'seen_rev, created_at, updated_at, updated_by_device, rev) VALUES '
        '${List<String>.filled(chunk.length, '(?, ?, ?, ?, ?, ?, ?, ?, ?)').join(', ')} '
        'ON CONFLICT(entity_type, entity_id, device_id) DO UPDATE SET '
        'seen_rev = MAX(version_vectors.seen_rev, excluded.seen_rev), '
        'updated_at = excluded.updated_at, updated_by_device = excluded.updated_by_device, '
        'rev = version_vectors.rev + 1 '
        'WHERE excluded.seen_rev > version_vectors.seen_rev',
        chunk.expand((List<Object?> row) => row).toList(),
      );
    }
  }

  Future<void> _advanceRows(
    Map<String, List<Map<String, Object?>>> updates, {
    required String chooser,
  }) async {
    for (final table in updates.entries) {
      if (!BundleFormat.insertOrder.contains(table.key)) {
        throw const CorruptionFailure();
      }
      final Set<String> columns = await _columns(table.key);
      for (final Map<String, Object?> row in table.value) {
        final List<String> names = <String>[
          for (final String name in row.keys)
            if (name != 'id' && name != 'created_at' && columns.contains(name))
              name,
        ];
        final QueryRow? before = await _db
            .customSelect(
              'SELECT * FROM ${table.key} WHERE id = ?',
              variables: <Variable<Object>>[
                Variable<String>(row['id']! as String),
              ],
            )
            .getSingleOrNull();
        if (before == null) {
          throw const CorruptionFailure();
        }
        await _db.customStatement(
          'UPDATE ${table.key} SET '
          '${names.map((String name) => '"$name" = ?').join(', ')} WHERE id = ?',
          <Object?>[for (final String name in names) row[name], row['id']],
        );
        for (final String name in names) {
          if (name == 'rev' ||
              name == 'updated_at' ||
              name == 'updated_by_device' ||
              before.data[name] == row[name]) {
            continue;
          }
          await appendAudit(
            _db,
            entityType: table.key,
            entityId: row['id']! as String,
            action: AuditAction.updated,
            fieldKey: name,
            previousValue: '${before.data[name] ?? ''}',
            newValue: '${row[name] ?? ''}',
            reason: 'merge: causalFastForward',
            clock: _clock,
            device: _deviceId,
            operator: chooser,
          );
        }
      }
    }
  }

  /// Reference datasets and rows, by the merge's rule: a dataset or a row
  /// key absent here is added; one present keeps this device's values.
  ///
  /// Keys are compared with the rows this device held before the import, so
  /// a key the package repeats (an ambiguous key column the operator
  /// accepted) arrives as every one of its rows, and a key this device
  /// already repeats matches without failing. A row id already here is
  /// never inserted twice.
  Future<void> _insertReference(
    Map<String, List<Map<String, Object?>>> tables,
  ) async {
    final List<Map<String, Object?>> incomingDatasets =
        tables['reference_datasets'] ?? const <Map<String, Object?>>[];
    final List<Map<String, Object?>> incomingRows =
        tables['reference_rows'] ?? const <Map<String, Object?>>[];
    final Set<String> datasets = await _existing('reference_datasets', <String>[
      for (final Map<String, Object?> row in incomingDatasets)
        row['id']! as String,
    ]);
    final Set<String> datasetColumns = await _columns('reference_datasets');
    for (final Map<String, Object?> row in incomingDatasets) {
      if (!datasets.contains(row['id'])) {
        await _insert('reference_datasets', row, datasetColumns);
      }
    }
    final Set<String> rowIds = await _existing('reference_rows', <String>[
      for (final Map<String, Object?> row in incomingRows) row['id']! as String,
    ]);
    final Set<String> keys = await _referenceKeys(<String>[
      for (final Map<String, Object?> row in incomingRows)
        row['dataset_id']! as String,
    ]);
    final Set<String> rowColumns = await _columns('reference_rows');
    for (final Map<String, Object?> row in incomingRows) {
      final String id = row['id']! as String;
      if (rowIds.contains(id) ||
          keys.contains(_referenceKey(row['dataset_id'], row['key_value']))) {
        continue;
      }
      await _insert('reference_rows', row, rowColumns);
      rowIds.add(id);
    }
  }

  /// Every `dataset/key` this device holds in [datasetIds], as
  /// [_referenceKey] spells it.
  Future<Set<String>> _referenceKeys(List<String> datasetIds) async {
    final Set<String> keys = <String>{};
    for (final List<String> chunk in _chunks(datasetIds.toSet().toList())) {
      final List<QueryRow> rows = await _db
          .customSelect(
            'SELECT dataset_id, key_value FROM reference_rows '
            'WHERE dataset_id IN '
            '(${List<String>.filled(chunk.length, '?').join(', ')})',
            variables: <Variable<Object>>[
              for (final String id in chunk) Variable<String>(id),
            ],
          )
          .get();
      keys.addAll(<String>[
        for (final QueryRow row in rows)
          _referenceKey(row.data['dataset_id'], row.data['key_value']),
      ]);
    }
    return keys;
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
    final Stream<List<int>> bytes = _valueOf(await bundle.openEntry(entry));
    written.add(target);
    final WrittenFile file = _valueOf(await _files.writeStream(target, bytes));
    final String? expected = _checksums(bundle)[entry];
    if (expected == null || file.sha256 != expected) {
      throw CorruptionFailure(
        localizedMessage: Copy.messages.importFileChanged,
        localizedRecovery: Copy.messages.importFailedRecovery,
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
      return StorageFailure(
        localizedMessage: Copy.messages.importNoRoom,
        localizedRecovery: Copy.messages.importNoRoomRecovery,
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

String _referenceIdentity(String meta) {
  final Object? decoded = jsonDecode(meta);
  if (decoded is Map && decoded['kind'] == 'reference') {
    final Object? id = decoded['incoming_row_id'];
    return id is String ? ':$id' : '';
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

/// [records] each on a template version: a package from a build before
/// records kept one places each record on its template's version in
/// [templates], as the upgrade that added the column did on a device.
List<Map<String, Object?>> _onTemplateVersions(
  List<Map<String, Object?>> records,
  List<Map<String, Object?>> templates,
) {
  final Map<Object?, Object?> versions = <Object?, Object?>{
    for (final Map<String, Object?> template in templates)
      template['id']: template['version'],
  };
  return <Map<String, Object?>>[
    for (final Map<String, Object?> record in records)
      if (record['template_version'] is int)
        record
      else
        <String, Object?>{
          ...record,
          'template_version': switch (versions[record['template_id']]) {
            final int version => version,
            _ => 1,
          },
        },
  ];
}

/// One reference row's `dataset/key` identity, as a merge compares keys.
String _referenceKey(Object? datasetId, Object? keyValue) =>
    '$datasetId/$keyValue';

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
    localizedMessage: failure.localizedMessage,
    localizedRecovery: Copy.messages.importFailedRecovery,
  );
}

/// The device's package import. Tests leave this empty and pass a fake.
final Provider<PackageImportRepository?> packageImportRepositoryProvider =
    Provider<PackageImportRepository?>((Ref _) => null);

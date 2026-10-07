import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/db/tables/template_fields.dart';
import 'package:tapture/core/db/tables/template_rows.dart';
import 'package:tapture/core/db/tables/templates.dart';
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/template_repository.dart';
import '../domain/template_versioning.dart';
import 'template_mapper.dart';

/// Drift-backed [TemplateRepository]. The only feature file besides the
/// mapper that imports both the table and the domain.
final class TemplateRepositoryImpl implements TemplateRepository {
  /// Opens against [_db], stamping writes from [_clock], [_deviceId] and
  /// [_ids].
  TemplateRepositoryImpl({
    required this._db,
    required this._clock,
    required this._deviceId,
    required this._ids,
  });

  final sqlite.AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;

  @override
  Stream<List<TemplateDef>> watchByProject(String projectId) {
    return _changes().asyncMap((_) => _listOwned(projectId));
  }

  @override
  Stream<List<TemplateDef>> watchLibrary() {
    return _changes().asyncMap((_) => _listOwned(null));
  }

  @override
  Future<Result<TemplateDef?>> byId(String id) async {
    if (id.isEmpty) {
      return const Success<TemplateDef?>(null);
    }
    try {
      return Success<TemplateDef?>(await _load(id));
    } on Failure catch (failure) {
      return FailureResult<TemplateDef?>(failure);
    } on Object catch (error) {
      return FailureResult<TemplateDef?>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<TemplateDef>> save(TemplateDef template) async {
    final ValidationFailure? invalid = _validate(template);
    if (invalid != null) {
      return FailureResult<TemplateDef>(invalid);
    }
    return runInTransaction(_db, () async {
      final TemplateDef? existing = template.id.isEmpty
          ? null
          : await _load(template.id);
      final TemplateDef stamped = existing == null
          ? template
          : TemplateVersioning.remember(from: existing, to: template);
      final Result<sqlite.Template> written = await upsertTemplate(
        _db,
        row: TemplateMapper.headerToRow(stamped),
        clock: _clock,
        deviceId: _deviceId,
        ids: _ids,
      );
      switch (written) {
        case FailureResult<sqlite.Template>(:final Failure failure):
          throw StorageFailure(
            message: failure.message,
            localizedMessage: failure.localizedMessage,
            recoveryAction: failure.recoveryAction ?? 'Try again.',
            localizedRecovery: failure.localizedRecovery,
          );
        case Success<sqlite.Template>(:final sqlite.Template value):
          await _replaceFields(templateId: value.id, fields: stamped.fields);
          if (existing != null) {
            final Set<String> active = stamped.fields
                .map((field) => field.fieldKey)
                .toSet();
            for (final FieldDef field in existing.fields) {
              if (!active.contains(field.fieldKey)) {
                await _retireFieldValues(value.id, field.fieldKey);
              }
            }
          }
          await _replaceRows(templateId: value.id, rows: stamped.rows);
          final TemplateDef? loaded = await _load(value.id);
          if (loaded == null) {
            throw StorageFailure(
              localizedMessage:
                  Copy.messages.failureTheDatabaseCouldNotCompleteThatWrite,
              localizedRecovery:
                  Copy.messages.failureFreeUpSpaceOrExportAProject,
            );
          }
          return loaded;
      }
    });
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) async {
    if (id.isEmpty) {
      return FailureResult<void>(_missing);
    }
    if (reason.trim().isEmpty) {
      return FailureResult<void>(_needsReason);
    }
    return runInTransaction(_db, () async {
      final sqlite.Template? header = await _header(id);
      if (header == null || await _isTombstoned(_db.templates, id)) {
        throw StorageFailure(
          localizedMessage: Copy.messages.failureThatRowIsNoLongerOnThis,
          localizedRecovery: Copy.messages.failureRefreshTheListAndTryAgain,
        );
      }
      final List<Map<String, String>> children = <Map<String, String>>[];
      for (final sqlite.TemplateField field in await _fieldsOf(id)) {
        await _deleteChild(_db.templateFields, field.id, reason, children);
      }
      for (final sqlite.TemplateRow row in await _rowsOf(id)) {
        await _deleteChild(_db.templateRows, row.id, reason, children);
      }
      await _tombstone(_db.templates, id, reason);
      final sqlite.Tombstone deletion = (await _deletion(_db.templates, id))!;
      await appendAudit(
        _db,
        entityType: _db.templates.actualTableName,
        entityId: id,
        action: AuditAction.deleted,
        fieldKey: _cascadeField,
        previousValue: deletion.id,
        newValue: jsonEncode(children),
        reason: reason,
        clock: _clock,
        device: _deviceId,
      );
    });
  }

  @override
  Future<Result<void>> restore(String id) {
    return runInTransaction(_db, () async {
      final sqlite.Template? header = await _header(id);
      if (header == null) throw _missing;
      final String? projectId = header.projectId;
      if (projectId != null && await _isTombstoned(_db.projects, projectId)) {
        throw _missing;
      }
      final sqlite.Tombstone? deletion = await _deletion(_db.templates, id);
      if (deletion == null) return;
      final sqlite.AuditLogData? audit =
          await (_db.select(_db.auditLog)..where(
                (row) =>
                    row.entityType.equals(_db.templates.actualTableName) &
                    row.entityId.equals(id) &
                    row.fieldKey.equals(_cascadeField) &
                    row.previousValue.equals(deletion.id),
              ))
              .getSingleOrNull();
      // Legacy deletions have no cascade identity: leave their child
      // tombstones intact rather than resurrect independently removed data.
      if (audit?.newValue case final String snapshot) {
        for (final Object? raw in jsonDecode(snapshot) as List<Object?>) {
          final Map<String, Object?> child = Map<String, Object?>.from(
            raw as Map,
          );
          final TableInfo<Table, Object?>? table = switch (child['table']) {
            'template_fields' => _db.templateFields,
            'template_rows' => _db.templateRows,
            _ => null,
          };
          if (table == null) continue;
          final String childId = child['id']! as String;
          final QueryRow? owned = await _db
              .customSelect(
                'SELECT id FROM "${table.actualTableName}" WHERE id = ? AND template_id = ?',
                variables: <Variable<Object>>[
                  Variable<String>(childId),
                  Variable<String>(id),
                ],
              )
              .getSingleOrNull();
          if (owned == null) continue;
          if ((await _deletion(table, childId))?.id == child['tombstone']) {
            await _restoreRow(table, childId);
          }
        }
      }
      await _restoreRow(_db.templates, id);
      await appendAudit(
        _db,
        entityType: _db.templates.actualTableName,
        entityId: id,
        action: AuditAction.updated,
        fieldKey: 'deleted',
        previousValue: 'true',
        newValue: 'false',
        clock: _clock,
        device: _deviceId,
      );
    });
  }

  Future<void> _deleteChild(
    TableInfo<Table, Object?> table,
    String id,
    String reason,
    List<Map<String, String>> children,
  ) async {
    if (await _isTombstoned(table, id)) return;
    await _tombstone(table, id, reason);
    children.add(<String, String>{
      'table': table.actualTableName,
      'id': id,
      'tombstone': (await _deletion(table, id))!.id,
    });
  }

  Future<void> _restoreRow(TableInfo<Table, Object?> table, String id) async {
    await removeTombstone(_db, entityType: table.actualTableName, entityId: id);
    await _db.customUpdate(
      'UPDATE "${table.actualTableName}" SET updated_at = ?, '
      'updated_by_device = ?, rev = rev + 1 WHERE id = ?',
      variables: <Variable<Object>>[
        Variable<DateTime>(_clock.nowUtc()),
        Variable<String>(_deviceId),
        Variable<String>(id),
      ],
      updates: <TableInfo<Table, Object?>>{table},
    );
  }

  Future<List<TemplateDef>> _listOwned(String? projectId) async {
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT h.* FROM templates h WHERE '
          '${projectId == null ? 'h.project_id IS NULL' : 'h.project_id = ?'} '
          "AND NOT EXISTS (SELECT 1 FROM tombstones t WHERE t.entity_type = 'templates' AND t.entity_id = h.id)",
          variables: <Variable<Object>>[
            if (projectId != null) Variable<String>(projectId),
          ],
        )
        .get();
    final List<TemplateDef> list = <TemplateDef>[];
    for (final QueryRow row in rows) {
      list.add(await _assemble(_db.templates.map(row.data)));
    }
    list.sort(_byName);
    return list;
  }

  Future<TemplateDef?> _load(String id) async {
    final sqlite.Template? header = await _header(id);
    if (header == null || await _isTombstoned(_db.templates, id)) {
      return null;
    }
    return _assemble(header);
  }

  Future<TemplateDef> _assemble(sqlite.Template header) async {
    final Set<String> deadFields = await _tombstoned(
      _db.templateFields,
      header.id,
    );
    final Set<String> deadRows = await _tombstoned(_db.templateRows, header.id);
    final List<sqlite.TemplateField> fields = (await _fieldsOf(header.id))
        .where((sqlite.TemplateField row) => !deadFields.contains(row.id))
        .toList();
    final List<sqlite.TemplateRow> rows = (await _rowsOf(
      header.id,
    )).where((sqlite.TemplateRow row) => !deadRows.contains(row.id)).toList();
    return TemplateMapper.fromRows(header: header, fields: fields, rows: rows);
  }

  Future<void> _replaceFields({
    required String templateId,
    required List<FieldDef> fields,
  }) async {
    final Map<String, sqlite.TemplateField> existing =
        <String, sqlite.TemplateField>{
          for (final sqlite.TemplateField row in await _fieldsOf(templateId))
            row.fieldKey: row,
        };
    final Set<String> keep = <String>{};
    for (int index = 0; index < fields.length; index++) {
      final FieldDef field = fields[index];
      keep.add(field.fieldKey);
      final String? reused = existing[field.fieldKey]?.id;
      _throwIfFailed(
        await upsertTemplateField(
          _db,
          row: TemplateMapper.fieldToRow(
            field,
            templateId: templateId,
            id: reused,
            sortOrder: index,
          ),
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
        ),
      );
      if (reused != null) {
        // A reintroduced key reuses its removed row, so lift that removal.
        await removeTombstone(
          _db,
          entityType: _db.templateFields.actualTableName,
          entityId: reused,
        );
      }
    }
    for (final sqlite.TemplateField row in existing.values) {
      if (!keep.contains(row.fieldKey)) {
        await _tombstone(_db.templateFields, row.id, _removedReason);
      }
    }
  }

  Future<void> _replaceRows({
    required String templateId,
    required List<TemplateRow> rows,
  }) async {
    final Map<String, sqlite.TemplateRow> existing =
        <String, sqlite.TemplateRow>{
          for (final sqlite.TemplateRow row in await _rowsOf(templateId))
            row.identifier: row,
        };
    final Set<String> keep = <String>{};
    for (final TemplateRow row in rows) {
      keep.add(row.identifier);
      final String? reused = existing[row.identifier]?.id;
      _throwIfFailed(
        await upsertTemplateRow(
          _db,
          row: TemplateMapper.rowToRow(row, templateId: templateId, id: reused),
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
        ),
      );
      if (reused != null) {
        await removeTombstone(
          _db,
          entityType: _db.templateRows.actualTableName,
          entityId: reused,
        );
      }
    }
    for (final sqlite.TemplateRow row in existing.values) {
      if (!keep.contains(row.identifier)) {
        await _tombstone(_db.templateRows, row.id, _removedReason);
      }
    }
  }

  // A template deletion changes value flags, not captured template versions.
  // One transaction covers definition, flags, causal stamps and per-record
  // history. Pages and batches bound host memory and database round trips.
  Future<void> _retireFieldValues(String templateId, String fieldKey) async {
    const int pageSize = 128;
    String cursor = '';
    final DateTime now = _clock.nowUtc();
    while (true) {
      final List<QueryRow> rows = await _db
          .customSelect(
            'SELECT f.id, f.record_id FROM record_fields f '
            'JOIN records r ON r.id = f.record_id '
            'WHERE r.template_id = ? AND f.field_key = ? '
            "AND r.status != 'deleted' AND f.retired_at IS NULL AND f.id > ? "
            "AND NOT EXISTS (SELECT 1 FROM tombstones t WHERE t.entity_type = 'records' AND t.entity_id = r.id) "
            "AND NOT EXISTS (SELECT 1 FROM tombstones t WHERE t.entity_type = 'record_fields' AND t.entity_id = f.id) "
            'ORDER BY f.id LIMIT ?',
            variables: <Variable<Object>>[
              Variable<String>(templateId),
              Variable<String>(fieldKey),
              Variable<String>(cursor),
              const Variable<int>(pageSize),
            ],
          )
          .get();
      if (rows.isEmpty) return;
      await _db.batch((Batch batch) {
        for (final QueryRow row in rows) {
          batch.update(
            _db.recordFields,
            sqlite.RecordFieldsCompanion.custom(
              retiredAt: Variable<DateTime>(now),
              updatedAt: Variable<DateTime>(now),
              updatedByDevice: Variable<String>(_deviceId),
              rev: _db.recordFields.rev + const Constant<int>(1),
            ),
            where: (table) => table.id.equals(row.read<String>('id')),
          );
          batch.insert(
            _db.auditLog,
            auditEntry(
              entityType: 'records',
              entityId: row.read<String>('record_id'),
              action: AuditAction.updated,
              fieldKey: fieldKey,
              previousValue: 'false',
              newValue: 'true',
              reason: retiredAuditReason,
              device: _deviceId,
              at: now,
            ),
          );
        }
      });
      cursor = rows.last.read<String>('id');
      if (rows.length < pageSize) return;
    }
  }

  Future<sqlite.Template?> _header(String id) {
    return (_db.select(_db.templates)
          ..where((sqlite.$TemplatesTable tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<sqlite.TemplateField>> _fieldsOf(String templateId) async {
    final Result<List<sqlite.TemplateField>> loaded = await listTemplateFields(
      _db,
      templateId: templateId,
    );
    switch (loaded) {
      case FailureResult<List<sqlite.TemplateField>>(:final Failure failure):
        throw StorageFailure(
          message: failure.message,
          localizedMessage: failure.localizedMessage,
          recoveryAction: failure.recoveryAction ?? 'Try again.',
          localizedRecovery: failure.localizedRecovery,
        );
      case Success<List<sqlite.TemplateField>>(
        :final List<sqlite.TemplateField> value,
      ):
        return value;
    }
  }

  Future<List<sqlite.TemplateRow>> _rowsOf(String templateId) {
    return (_db.select(_db.templateRows)..where(
          (sqlite.$TemplateRowsTable tbl) => tbl.templateId.equals(templateId),
        ))
        .get();
  }

  Future<Set<String>> _tombstoned(
    TableInfo<Table, Object?> table,
    String templateId,
  ) async {
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT t.entity_id FROM tombstones t '
          'JOIN "${table.actualTableName}" child ON child.id = t.entity_id '
          'WHERE t.entity_type = ? AND child.template_id = ?',
          variables: <Variable<Object>>[
            Variable<String>(table.actualTableName),
            Variable<String>(templateId),
          ],
        )
        .get();
    return <String>{
      for (final QueryRow row in rows) row.read<String>('entity_id'),
    };
  }

  Future<bool> _isTombstoned(TableInfo<Table, Object?> table, String id) async {
    return await _deletion(table, id) != null;
  }

  Future<sqlite.Tombstone?> _deletion(
    TableInfo<Table, Object?> table,
    String id,
  ) {
    return (_db.select(_db.tombstones)..where(
          (sqlite.$TombstonesTable row) =>
              row.entityType.equals(table.actualTableName) &
              row.entityId.equals(id),
        ))
        .getSingleOrNull();
  }

  Future<void> _tombstone(
    TableInfo<Table, Object?> table,
    String entityId,
    String reason,
  ) {
    return writeTombstone(
      _db,
      entityType: table.actualTableName,
      entityId: entityId,
      reason: reason,
      clock: _clock,
      deviceId: _deviceId,
    );
  }

  Stream<void> _changes() {
    return Stream<void>.multi((MultiStreamController<void> listener) {
      final List<bool> scheduled = <bool>[false];
      final List<StreamSubscription<Object?>> subs =
          <StreamSubscription<Object?>>[
            _db.select(_db.templates).watch().listen((_) {
              _queueChange(listener, scheduled);
            }),
            _db.select(_db.templateFields).watch().listen((_) {
              _queueChange(listener, scheduled);
            }),
            _db.select(_db.templateRows).watch().listen((_) {
              _queueChange(listener, scheduled);
            }),
            _db.select(_db.tombstones).watch().listen((_) {
              _queueChange(listener, scheduled);
            }),
          ];
      listener.onCancel = () async {
        for (final StreamSubscription<Object?> sub in subs) {
          await sub.cancel();
        }
      };
    });
  }
}

/// The template store. Defaults to an empty in-memory stand-in so
/// suites never open Drift (FE-TEST-03). [main] replaces this with
/// [TemplateRepositoryImpl] against the on-disk database.
final Provider<TemplateRepository> templateRepositoryProvider =
    Provider<TemplateRepository>((Ref _) {
      return _EmptyTemplateRepository();
    });

/// Empty watch streams and failing writes. Production never keeps this;
/// tests that need rows inject [FakeTemplateRepository] or an in-memory
/// [TemplateRepositoryImpl].
final class _EmptyTemplateRepository implements TemplateRepository {
  @override
  Stream<List<TemplateDef>> watchLibrary() =>
      Stream<List<TemplateDef>>.value(const <TemplateDef>[]);

  @override
  Future<Result<void>> restore(String id) async =>
      FailureResult<void>(_missing);

  @override
  Stream<List<TemplateDef>> watchByProject(String projectId) {
    return Stream<List<TemplateDef>>.value(const <TemplateDef>[]);
  }

  @override
  Future<Result<TemplateDef?>> byId(String id) async {
    return const Success<TemplateDef?>(null);
  }

  @override
  Future<Result<TemplateDef>> save(TemplateDef template) async {
    return FailureResult<TemplateDef>(_missing);
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) async {
    return FailureResult<void>(_missing);
  }
}

ValidationFailure? _validate(TemplateDef template) {
  if (template.name.trim().isEmpty) {
    return ValidationFailure(
      localizedMessage: Copy.messages.failureATemplateNeedsAName,
      localizedRecovery: Copy.messages.failureEnterANameAndSaveAgain,
    );
  }
  final Set<String> keys = <String>{};
  for (final FieldDef field in template.fields) {
    if (field.fieldKey.trim().isEmpty) {
      return ValidationFailure(
        localizedMessage: Copy.messages.failureAFieldNeedsAKey,
        localizedRecovery: Copy.messages.failureGiveEveryFieldAKeyAndSave,
      );
    }
    if (!keys.add(field.fieldKey)) {
      return ValidationFailure(
        localizedMessage: Copy.messages.failureEachFieldKeyMustBeUniqueOn,
        localizedRecovery:
            Copy.messages.failureRenameTheDuplicateKeyAndSaveAgain,
      );
    }
  }
  return null;
}

int _byName(TemplateDef left, TemplateDef right) {
  final int byName = left.name.toLowerCase().compareTo(
    right.name.toLowerCase(),
  );
  if (byName != 0) {
    return byName;
  }
  return left.id.compareTo(right.id);
}

void _queueChange(MultiStreamController<void> listener, List<bool> scheduled) {
  if (scheduled.first || listener.isClosed) {
    return;
  }
  scheduled[0] = true;
  scheduleMicrotask(() {
    scheduled[0] = false;
    if (!listener.isClosed) {
      listener.add(null);
    }
  });
}

void _throwIfFailed<T>(Result<T> result) {
  switch (result) {
    case FailureResult<T>(:final Failure failure):
      throw StorageFailure(
        message: failure.message,
        localizedMessage: failure.localizedMessage,
        recoveryAction: failure.recoveryAction ?? 'Try again.',
        localizedRecovery: failure.localizedRecovery,
      );
    case Success<T>():
      return;
  }
}

final StorageFailure _missing = StorageFailure(
  localizedMessage: Copy.messages.failureThatRowIsNoLongerOnThis,
  localizedRecovery: Copy.messages.failureRefreshTheListAndTryAgain,
);

final StorageFailure _needsReason = StorageFailure(
  localizedMessage: Copy.messages.failureADeleteNeedsAReason,
  localizedRecovery: Copy.messages.failureSayWhyThisRowShouldBeRemoved,
);

const String _removedReason = 'Removed from the template.';
const String _cascadeField = 'deletedChildren';

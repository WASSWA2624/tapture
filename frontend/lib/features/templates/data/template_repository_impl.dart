import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
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
            recoveryAction: failure.recoveryAction ?? 'Try again.',
          );
        case Success<sqlite.Template>(:final sqlite.Template value):
          await _replaceFields(templateId: value.id, fields: stamped.fields);
          await _replaceRows(templateId: value.id, rows: stamped.rows);
          final TemplateDef? loaded = await _load(value.id);
          if (loaded == null) {
            throw const StorageFailure(
              message: 'The database could not complete that write.',
              recoveryAction:
                  'Free up space or export a project, then try again.',
            );
          }
          return loaded;
      }
    });
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) async {
    if (id.isEmpty) {
      return const FailureResult<void>(_missing);
    }
    if (reason.trim().isEmpty) {
      return const FailureResult<void>(_needsReason);
    }
    return runInTransaction(_db, () async {
      final sqlite.Template? header = await _header(id);
      if (header == null || await _isTombstoned(_db.templates, id)) {
        throw const StorageFailure(
          message: 'That row is no longer on this device.',
          recoveryAction: 'Refresh the list and try again.',
        );
      }
      for (final sqlite.TemplateField field in await _fieldsOf(id)) {
        await _tombstone(_db.templateFields, field.id, reason);
      }
      for (final sqlite.TemplateRow row in await _rowsOf(id)) {
        await _tombstone(_db.templateRows, row.id, reason);
      }
      await _tombstone(_db.templates, id, reason);
    });
  }

  Future<List<TemplateDef>> _listOwned(String projectId) async {
    final List<sqlite.Template> headers =
        await (_db.select(_db.templates)..where(
              (sqlite.$TemplatesTable tbl) => tbl.projectId.equals(projectId),
            ))
            .get();
    final Set<String> dead = await _tombstoned(_db.templates);
    final List<TemplateDef> list = <TemplateDef>[];
    for (final sqlite.Template header in headers) {
      if (dead.contains(header.id)) {
        continue;
      }
      list.add(await _assemble(header));
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
    final Set<String> deadFields = await _tombstoned(_db.templateFields);
    final Set<String> deadRows = await _tombstoned(_db.templateRows);
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
      _throwIfFailed(
        await upsertTemplateField(
          _db,
          row: TemplateMapper.fieldToRow(
            field,
            templateId: templateId,
            id: existing[field.fieldKey]?.id,
            sortOrder: index,
          ),
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
        ),
      );
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
      _throwIfFailed(
        await upsertTemplateRow(
          _db,
          row: TemplateMapper.rowToRow(
            row,
            templateId: templateId,
            id: existing[row.identifier]?.id,
          ),
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
        ),
      );
    }
    for (final sqlite.TemplateRow row in existing.values) {
      if (!keep.contains(row.identifier)) {
        await _tombstone(_db.templateRows, row.id, _removedReason);
      }
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
          recoveryAction: failure.recoveryAction ?? 'Try again.',
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

  Future<Set<String>> _tombstoned(TableInfo<dynamic, dynamic> table) async {
    final List<sqlite.Tombstone> rows =
        await (_db.select(_db.tombstones)..where(
              (sqlite.$TombstonesTable tbl) =>
                  tbl.entityType.equals(table.actualTableName),
            ))
            .get();
    return <String>{for (final sqlite.Tombstone row in rows) row.entityId};
  }

  Future<bool> _isTombstoned(
    TableInfo<dynamic, dynamic> table,
    String id,
  ) async {
    return (await _tombstoned(table)).contains(id);
  }

  Future<void> _tombstone(
    TableInfo<dynamic, dynamic> table,
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
  Stream<List<TemplateDef>> watchByProject(String projectId) {
    return Stream<List<TemplateDef>>.value(const <TemplateDef>[]);
  }

  @override
  Future<Result<TemplateDef?>> byId(String id) async {
    return const Success<TemplateDef?>(null);
  }

  @override
  Future<Result<TemplateDef>> save(TemplateDef template) async {
    return const FailureResult<TemplateDef>(_missing);
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) async {
    return const FailureResult<void>(_missing);
  }
}

ValidationFailure? _validate(TemplateDef template) {
  if (template.name.trim().isEmpty) {
    return const ValidationFailure(
      message: 'A template needs a name.',
      recoveryAction: 'Enter a name and save again.',
    );
  }
  final Set<String> keys = <String>{};
  for (final FieldDef field in template.fields) {
    if (field.fieldKey.trim().isEmpty) {
      return const ValidationFailure(
        message: 'A field needs a key.',
        recoveryAction: 'Give every field a key and save again.',
      );
    }
    if (!keys.add(field.fieldKey)) {
      return const ValidationFailure(
        message: 'Each field key must be unique on a template.',
        recoveryAction: 'Rename the duplicate key and save again.',
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
        recoveryAction: failure.recoveryAction ?? 'Try again.',
      );
    case Success<T>():
      return;
  }
}

const StorageFailure _missing = StorageFailure(
  message: 'That row is no longer on this device.',
  recoveryAction: 'Refresh the list and try again.',
);

const StorageFailure _needsReason = StorageFailure(
  message: 'A delete needs a reason.',
  recoveryAction: 'Say why this row should be removed, then try again.',
);

const String _removedReason = 'Removed from the template.';

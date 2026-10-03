import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/record_schema.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/quality/quality.dart'
    show identityKeysOf, storedIdentityHash;
import 'package:tapture/features/records/records.dart' show RecordLifecycle;

import '../domain/import_duplicates.dart';
import '../domain/record_import.dart';
import '../domain/record_import_store.dart';

/// The Drift [RecordImportStore] (task 020).
///
/// One [write] is one transaction, with search indexing deferred to its end
/// ([RecordSchema.deferIndexing]); a throw, or a cancel, rolls back every
/// row of it. A created record is a record of the template in status
/// needs review, source [RecordImport.importedSource], with each non-empty
/// value inserted raw under the same source. A replace writes each
/// non-empty value over what the field displays; a merge writes only where
/// the field is empty. Raw values are never rewritten and nothing is
/// deleted (FE-SEC-08); an approved record that changes goes back to
/// review (§38).
final class RecordImportStoreImpl implements RecordImportStore {
  /// Creates the store over `db`, stamped with `clock` and `deviceId`, new
  /// ids from `ids`, and the operator from `operatorName` when given.
  const RecordImportStoreImpl({
    required sqlite.AppDatabase db,
    required Clock clock,
    required String deviceId,
    required IdService ids,
    String Function()? operatorName,
  }) : _db = db, // ignore: prefer_initializing_formals
       _clock = clock, // ignore: prefer_initializing_formals
       _deviceId = deviceId, // ignore: prefer_initializing_formals
       _ids = ids, // ignore: prefer_initializing_formals
       _operatorName = operatorName; // ignore: prefer_initializing_formals

  final sqlite.AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;
  final String Function()? _operatorName;

  @override
  Future<Result<Map<String, String>>> identities({
    required String projectId,
    required String templateId,
  }) {
    return Result.captureAsync(() async {
      final List<QueryRow> rows = await _db
          .customSelect(
            'SELECT id, identity_hash FROM records WHERE project_id = ? '
            'AND template_id = ? AND status <> ? '
            'ORDER BY captured_at, id',
            variables: <Variable<Object>>[
              Variable<String>(projectId),
              Variable<String>(templateId),
              Variable<String>(RecordStatus.deleted.stored),
            ],
          )
          .get();
      final Map<String, String> byHash = <String, String>{};
      for (final QueryRow row in rows) {
        byHash.putIfAbsent(
          row.read<String>('identity_hash'),
          () => row.read<String>('id'),
        );
      }
      return byHash;
    });
  }

  @override
  Future<Result<void>> write({
    required String projectId,
    required String templateId,
    required List<ImportWrite> rows,
    required int batchSize,
    required void Function(int written) onBatch,
    required CancellationToken token,
  }) async {
    if (rows.isEmpty) {
      return const Success<void>(null);
    }
    final Result<void> outcome = await runInTransaction<void>(
      _db,
      () => RecordSchema.deferIndexing<void>(_db, () async {
        final QueryRow? template = await _db
            .customSelect(
              'SELECT version, identity_fields FROM templates '
              'WHERE id = ? AND (project_id = ? OR project_id IS NULL)',
              variables: <Variable<Object>>[
                Variable<String>(templateId),
                Variable<String>(projectId),
              ],
            )
            .getSingleOrNull();
        if (template == null) {
          throw _missingTemplateFailure;
        }
        final _Target target = (
          projectId: projectId,
          templateId: templateId,
          version: template.read<int>('version'),
          identityKeys: identityKeysOf(
            template.read<String?>('identity_fields'),
          ),
          operator: await _operator(),
        );
        for (int index = 0; index < rows.length; index++) {
          if (token.isCancelled) {
            throw const CancelledFailure();
          }
          final ImportWrite row = rows[index];
          switch (row.match) {
            case ImportMatch.create:
              await _create(target, row);
            case ImportMatch.replace || ImportMatch.merge:
              await _update(target, row);
            case ImportMatch.keep || ImportMatch.ask:
              break;
          }
          if ((index + 1) % batchSize == 0 || index == rows.length - 1) {
            onBatch(index + 1);
          }
        }
      }),
    );
    if (token.isCancelled && outcome is FailureResult<void>) {
      return const FailureResult<void>(CancelledFailure());
    }
    return outcome;
  }

  Future<void> _create(_Target target, ImportWrite row) async {
    final String id = _ids.newId();
    final Result<sqlite.RecordRow> created = await upsertRecord(
      _db,
      row: sqlite.RecordsCompanion(
        id: Value<String>(id),
        projectId: Value<String>(target.projectId),
        templateId: Value<String>(target.templateId),
        templateVersion: Value<int>(target.version),
        status: Value<String>(RecordStatus.needsReview.stored),
        processingMode: const Value<String>(_processingMode),
        contextJson: const Value<String>('{}'),
        identityHash: Value<String>(
          storedIdentityHash(
            recordId: id,
            values: row.values,
            identityKeys: target.identityKeys,
          ),
        ),
        source: const Value<String>(RecordImport.importedSource),
        capturedAt: Value<DateTime>(_clock.nowUtc()),
        capturedBy: Value<String>(_deviceId),
      ),
      clock: _clock,
      deviceId: _deviceId,
      ids: _ids,
    );
    _expect(created);
    await appendAudit(
      _db,
      entityType: _recordsEntity,
      entityId: id,
      action: AuditAction.created,
      newValue: RecordStatus.needsReview.stored,
      reason: RecordImport.importedSource,
      clock: _clock,
      device: _deviceId,
      operator: target.operator,
    );
    for (final MapEntry<String, String> value in row.values.entries) {
      if (value.value.isEmpty) {
        continue;
      }
      await _insertValue(id, value.key, value.value, target.operator);
    }
  }

  Future<void> _update(_Target target, ImportWrite row) async {
    final String? id = row.existingId;
    final QueryRow? head = id == null
        ? null
        : await _db
              .customSelect(
                'SELECT status FROM records WHERE id = ? AND project_id = ?',
                variables: <Variable<Object>>[
                  Variable<String>(id),
                  Variable<String>(target.projectId),
                ],
              )
              .getSingleOrNull();
    final RecordStatus? status = head == null
        ? null
        : RecordStatus.fromStored(head.read<String>('status'));
    if (id == null || status == null || status == RecordStatus.deleted) {
      throw _missingRecordFailure;
    }
    var changed = false;
    for (final MapEntry<String, String> value in row.values.entries) {
      if (value.value.isEmpty) {
        continue;
      }
      final QueryRow? stored = await _db
          .customSelect(
            'SELECT id, COALESCE(NULLIF(value_final, \'\'), '
            'NULLIF(value_refined, \'\'), value_raw, \'\') AS shown '
            'FROM record_fields WHERE record_id = ? AND field_key = ?',
            variables: <Variable<Object>>[
              Variable<String>(id),
              Variable<String>(value.key),
            ],
          )
          .getSingleOrNull();
      if (stored == null) {
        await _insertValue(id, value.key, value.value, target.operator);
        changed = true;
        continue;
      }
      final bool empty = stored.read<String>('shown').isEmpty;
      if (row.match == ImportMatch.merge && !empty) {
        continue;
      }
      changed =
          await writeRecordFieldEdit(
            _db,
            id: stored.read<String>('id'),
            value: value.value,
            source: RecordImport.importedSource,
            clock: _clock,
            deviceId: _deviceId,
            operator: target.operator,
            reason: RecordImport.importedSource,
          ) ||
          changed;
    }
    if (!changed) {
      return;
    }
    await _db.customUpdate(
      'UPDATE records SET updated_at = ?, updated_by_device = ?, '
      'rev = rev + 1 WHERE id = ?',
      variables: <Variable<Object>>[
        Variable<DateTime>(_clock.nowUtc()),
        Variable<String>(_deviceId),
        Variable<String>(id),
      ],
      updates: <TableInfo<dynamic, dynamic>>{_db.records},
      updateKind: UpdateKind.update,
    );
    final RecordStatus next = RecordLifecycle.afterEdit(status);
    if (next != status) {
      await writeRecordStatus(
        _db,
        recordId: id,
        status: next.stored,
        previousStatus: status.stored,
        clock: _clock,
        deviceId: _deviceId,
        operator: target.operator,
        reason: RecordImport.importedSource,
      );
    }
  }

  Future<void> _insertValue(
    String recordId,
    String fieldKey,
    String value,
    String? operator,
  ) async {
    _expect(
      await insertRecordField(
        _db,
        row: sqlite.RecordFieldsCompanion(
          recordId: Value<String>(recordId),
          fieldKey: Value<String>(fieldKey),
          valueRaw: Value<String?>(value),
          source: const Value<String>(RecordImport.importedSource),
        ),
        clock: _clock,
        deviceId: _deviceId,
        ids: _ids,
        operator: operator,
        auditReason: RecordImport.importedSource,
      ),
    );
  }

  /// The operator to stamp: `operatorName` when given, else the device
  /// profile's operator name; null when blank.
  Future<String?> _operator() async {
    final String Function()? named = _operatorName;
    final String name;
    if (named != null) {
      name = named();
    } else {
      final QueryRow? profile = await _db
          .customSelect('SELECT operator_name FROM device_profile LIMIT 1')
          .getSingleOrNull();
      name = profile?.read<String?>('operator_name') ?? '';
    }
    final String trimmed = name.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// Where imported rows are written. Unavailable until `main` overrides it
/// with [RecordImportStoreImpl] over the on-disk database; tests override it
/// with a fake or an in-memory database (FE-TEST-03).
final Provider<RecordImportStore> recordImportStoreProvider =
    Provider<RecordImportStore>((Ref _) {
      return const _UnavailableRecordImportStore();
    });

final class _UnavailableRecordImportStore implements RecordImportStore {
  const _UnavailableRecordImportStore();

  @override
  Future<Result<Map<String, String>>> identities({
    required String projectId,
    required String templateId,
  }) async {
    return FailureResult<Map<String, String>>(_unavailableFailure);
  }

  @override
  Future<Result<void>> write({
    required String projectId,
    required String templateId,
    required List<ImportWrite> rows,
    required int batchSize,
    required void Function(int written) onBatch,
    required CancellationToken token,
  }) async {
    return FailureResult<void>(_unavailableFailure);
  }
}

/// The template and operator every row of one write is stamped with.
typedef _Target = ({
  String projectId,
  String templateId,
  int version,
  List<String> identityKeys,
  String? operator,
});

/// Throws the failure of [result], so the open transaction rolls back.
void _expect<T>(Result<T> result) {
  if (result case FailureResult<T>(failure: final Failure writeFailure)) {
    throw writeFailure;
  }
}

/// `processing_mode` of an imported record: nothing processes it.
const String _processingMode = 'manual';

const String _recordsEntity = 'records';

final StorageFailure _missingTemplateFailure = StorageFailure(
  localizedMessage: Copy.messages.failureTheTemplateTheseRowsWereMatchedTo,
  localizedRecovery: Copy.messages.failureChooseAnotherTemplateAndImportAgain,
);

final StorageFailure _missingRecordFailure = StorageFailure(
  localizedMessage: Copy.messages.failureARecordARowMatchedIsNo,
  localizedRecovery: Copy.messages.failureImportTheFileAgainToMatchIt,
);

final StorageFailure _unavailableFailure = StorageFailure(
  localizedMessage: Copy.messages.failureRecordsCannotBeImportedRightNow,
  localizedRecovery: Copy.messages.failureRestartTaptureThenImportAgain,
);

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/record_schema.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/quality/quality.dart' show identityHash;

import '../domain/record_lifecycle.dart';
import '../domain/record_repository.dart';
import '../domain/record_value.dart';
import '../domain/template_change_plan.dart';

/// The write half of the Drift record store (task 014): a record saved by
/// hand, status moves, value edits, template changes, delete and restore.
///
/// Every public call is one `runInTransaction`. A status move is checked
/// with [RecordLifecycle] inside that transaction before anything is written;
/// an illegal one comes back as the lifecycle's [ValidationFailure] without
/// a throw, because a throw rolls the transaction back and `runInTransaction`
/// turns every non-storage failure into a generic storage one. A failure
/// after the first write throws, so nothing of the call is kept.
///
/// Status is only ever written through `writeRecordStatus` (D3), which bumps
/// the revision, stamps an approval and appends the `status` audit row.
/// Calls that write several rows run under [RecordSchema.deferIndexing], so
/// the schema's triggers rebuild the record's search document once, inside
/// the same transaction. Values are never deleted and raw values never
/// rewritten (FE-SEC-08); files are never touched.
///
/// The operator written on audit rows, verified values and approvals is
/// [operatorName] when one is given, else the device profile's operator name;
/// a blank name means no operator (the audit row still names the device).
///
/// Under `test/features/records/record_repository_contract.dart` these writes
/// behave exactly like `FakeRecordRepository`. `RecordRepositoryImpl`
/// composes them with the read side: its `save` returns the entry the reader
/// finds under the id [save] returns.
final class RecordWrites {
  /// Creates the writes over `db`, stamped with `clock` and `deviceId`, new
  /// ids from `ids`, and the operator from `operatorName` when given.
  const RecordWrites({
    required this._db,
    required this._clock,
    required this._deviceId,
    required this._ids,
    this._operatorName,
  });

  final sqlite.AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;
  final String Function()? _operatorName;

  /// `processing_mode` and `source` of a record saved by hand, and the
  /// reason on its `created` audit row.
  static const String manualSource = 'manual';

  /// Source of a value typed into a record saved by hand, as capture writes.
  static const String typedSource = 'TYPED';

  /// Reason on the status row an edit of an approved record writes.
  static const String editedReason = 'Values edited';

  /// Reason on the status row a template change of an approved record
  /// writes.
  static const String templateChangedReason = 'Template changed';

  /// Reason on the status row a restore writes.
  static const String restoredReason = 'Restored';

  /// Reason on the `templateId` and `templateRowId` rows of a template
  /// change, in the shape processing's template choice writes.
  static const String templateChangeAuditReason = '{"method":"remap"}';

  /// Audit field key of a template change (the marker processing uses).
  static const String templateAuditKey = 'templateId';

  /// Audit field key of the checklist row a template change lets go.
  static const String templateRowAuditKey = 'templateRowId';

  /// Saves a record made by hand from [draft] and returns its id.
  ///
  /// The record starts as a draft, with processing mode and source
  /// [manualSource], [RecordDraft.context] as its frozen context snapshot,
  /// and the next number in its project (the schema's trigger allocates it).
  /// Each typed value is inserted raw with source [typedSource]; a blank key
  /// or an empty value is skipped. The identity hash is the SHA-256 of the
  /// record id, the equivalent of capture hashing its session id (which is
  /// the record id). One `created` audit row (no field key, new value
  /// `draft`, reason [manualSource]) comes before the per-value rows.
  ///
  /// A draft without a project or template, or on another project's
  /// template, is a [ValidationFailure]; a template not on this device is a
  /// [StorageFailure]. Nothing is written in either case.
  Future<Result<String>> save(RecordDraft draft) async {
    if (draft.projectId.trim().isEmpty || draft.templateId.trim().isEmpty) {
      return const FailureResult<String>(_needsProjectAndTemplate);
    }
    return _write<String>((String? operator) async {
      final Failure? unusable = await _unusableTemplate(
        draft.templateId,
        projectId: draft.projectId,
      );
      if (unusable != null) {
        return FailureResult<String>(unusable);
      }
      return RecordSchema.deferIndexing(_db, () async {
        final String id = _ids.newId();
        _expect(
          await upsertRecord(
            _db,
            row: sqlite.RecordsCompanion(
              id: Value<String>(id),
              projectId: Value<String>(draft.projectId),
              templateId: Value<String>(draft.templateId),
              status: Value<String>(RecordStatus.draft.stored),
              processingMode: const Value<String>(manualSource),
              contextJson: Value<String>(jsonEncode(draft.context)),
              identityHash: Value<String>(
                sha256.convert(utf8.encode(id)).toString(),
              ),
              source: const Value<String>(manualSource),
              capturedAt: Value<DateTime>(_clock.nowUtc()),
              capturedBy: Value<String>(_deviceId),
            ),
            clock: _clock,
            deviceId: _deviceId,
            ids: _ids,
          ),
        );
        await appendAudit(
          _db,
          entityType: _recordsEntity,
          entityId: id,
          action: AuditAction.created,
          newValue: RecordStatus.draft.stored,
          reason: manualSource,
          clock: _clock,
          device: _deviceId,
          operator: operator,
        );
        for (final MapEntry<String, String> field in draft.fields.entries) {
          if (field.key.trim().isEmpty || field.value.isEmpty) {
            continue;
          }
          _expect(
            await insertRecordField(
              _db,
              row: sqlite.RecordFieldsCompanion(
                recordId: Value<String>(id),
                fieldKey: Value<String>(field.key),
                valueRaw: Value<String?>(field.value),
                source: const Value<String>(typedSource),
              ),
              clock: _clock,
              deviceId: _deviceId,
              ids: _ids,
              operator: operator,
            ),
          );
        }
        return Success<String>(id);
      });
    });
  }

  /// Moves record [id] to [to] after checking the move with
  /// [RecordLifecycle], with [reason] on the status audit row.
  ///
  /// An illegal move, a move to the status it already has, a move into
  /// deleted (use [moveToBin]) or out of it (use [restore]), and a record whose
  /// stored status this app does not know are each a [ValidationFailure]
  /// that writes nothing. A record not on this device is a [StorageFailure].
  /// Approving stamps the approval time and operator.
  Future<Result<void>> transition(
    String id,
    RecordStatus to, {
    String? reason,
  }) {
    return _write<void>((String? operator) async {
      final _Head? head = await _head(id);
      if (head == null) {
        return const FailureResult<void>(_missing);
      }
      if (to == RecordStatus.deleted) {
        return const FailureResult<void>(_useDelete);
      }
      final RecordStatus? from = head.status;
      if (from == null) {
        return const FailureResult<void>(_unknownStatus);
      }
      if (from == RecordStatus.deleted) {
        return const FailureResult<void>(_useRestore);
      }
      final Result<void> legal = RecordLifecycle.check(from, to);
      if (legal is FailureResult<void>) {
        return legal;
      }
      await writeRecordStatus(
        _db,
        recordId: id,
        status: to.stored,
        previousStatus: from.stored,
        clock: _clock,
        deviceId: _deviceId,
        operator: operator,
        reason: reason,
      );
      return const Success<void>(null);
    });
  }

  /// Writes [edits] onto record [id], in order, in one transaction.
  ///
  /// A field with a value gets the edit as its refined value through
  /// `writeRecordFieldEdit`: the approved value is superseded so the field
  /// displays the edit, the raw value stays, the source becomes manual and
  /// the value verified, and one audit row holds what the field displayed
  /// before and the edit. A field with no value is inserted with the edit as
  /// its raw value, manual and verified, with its own `created` audit row.
  /// An edit to what a field already displays writes nothing, so a call that
  /// changes nothing leaves an approved record approved.
  ///
  /// An edited value also loses its evidence-removed flag (with the flag's
  /// own audit row): the operator has now vouched for it, so it no longer
  /// rests on the photos that went. A retired value stays retired.
  ///
  /// When anything changed, an approved record moves to needsReview through
  /// the status writer ([editedReason]); any other record has its revision
  /// and update time bumped. The search document is rebuilt once, before the
  /// transaction commits. A record in the bin, or an edit without a field
  /// key, is a [ValidationFailure]; a record not on this device is a
  /// [StorageFailure]; nothing is written in any of those cases.
  Future<Result<void>> editValues(String id, List<RecordValueEdit> edits) {
    return _write<void>((String? operator) async {
      final _Head? head = await _head(id);
      if (head == null) {
        return const FailureResult<void>(_missing);
      }
      final Result<void> editable = _editable(head);
      if (editable is FailureResult<void>) {
        return editable;
      }
      for (final RecordValueEdit edit in edits) {
        if (edit.fieldKey.trim().isEmpty) {
          return const FailureResult<void>(_needsField);
        }
      }
      return RecordSchema.deferIndexing(_db, () async {
        bool changed = false;
        for (final RecordValueEdit edit in edits) {
          if (await _edit(id, edit, operator)) {
            changed = true;
          }
        }
        if (changed) {
          await _refreshIdentityHash(head);
          if (!await _sendBackToReview(head, operator, editedReason)) {
            await _touch(id);
          }
        }
        return const Success<void>(null);
      });
    });
  }

  /// What moving record [id] to template [templateId] would map, retire,
  /// add and restore, by field key, without writing anything.
  ///
  /// The target's field keys are its live (untombstoned) template fields in
  /// sort order. A record or template not on this device is a
  /// [StorageFailure]; the template the record already uses, or one that
  /// belongs to another project, is a [ValidationFailure].
  Future<Result<TemplateChangePlan>> planTemplateChange(
    String id,
    String templateId,
  ) {
    return _inTransaction<TemplateChangePlan>(() async {
      final _Head? head = await _head(id);
      if (head == null) {
        return const FailureResult<TemplateChangePlan>(_missing);
      }
      return (await _plan(head, templateId)).map((_Remap remap) => remap.plan);
    });
  }

  /// Moves record [id] to template [templateId] as [planTemplateChange]
  /// describes, in one transaction.
  ///
  /// The record's template becomes [templateId] and its checklist row is let
  /// go (it belonged to the old template), with a [templateAuditKey] audit row
  /// (and a [templateRowAuditKey] one when a row was set). Values the target
  /// does not declare are retired and retired values it declares are brought
  /// back, each through the flag helpers with its own audit row; no value is
  /// ever deleted or rewritten. An approved record moves to needsReview
  /// ([templateChangedReason]). The search document is rebuilt once, before
  /// the transaction commits.
  ///
  /// A record in the bin, the template already in use or another project's
  /// template is a [ValidationFailure]; a record or template not on this
  /// device is a [StorageFailure]; nothing is written in any of those cases.
  Future<Result<void>> changeTemplate(String id, String templateId) {
    return _write<void>((String? operator) async {
      final _Head? head = await _head(id);
      if (head == null) {
        return const FailureResult<void>(_missing);
      }
      final Result<void> editable = _editable(head);
      if (editable is FailureResult<void>) {
        return editable;
      }
      final Result<_Remap> planned = await _plan(head, templateId);
      if (planned case FailureResult<_Remap>(failure: final Failure refusal)) {
        return FailureResult<void>(refusal);
      }
      final _Remap remap = (planned as Success<_Remap>).value;
      await RecordSchema.deferIndexing(_db, () async {
        await _db.customUpdate(
          'UPDATE records SET template_id = ?, template_row_id = NULL, '
          'updated_at = ?, updated_by_device = ?, rev = rev + 1 WHERE id = ?',
          variables: <Variable<Object>>[
            Variable<String>(templateId),
            Variable<DateTime>(_clock.nowUtc()),
            Variable<String>(_deviceId),
            Variable<String>(id),
          ],
          updates: <TableInfo<dynamic, dynamic>>{_db.records},
          updateKind: UpdateKind.update,
        );
        await _auditRecord(
          id,
          fieldKey: templateAuditKey,
          previous: head.templateId,
          next: templateId,
          operator: operator,
        );
        final String? templateRowId = head.templateRowId;
        if (templateRowId != null) {
          await _auditRecord(
            id,
            fieldKey: templateRowAuditKey,
            previous: templateRowId,
            next: null,
            operator: operator,
          );
        }
        for (final String key in remap.plan.retired) {
          await setRecordFieldRetired(
            _db,
            id: remap.valueIds[key]!,
            clock: _clock,
            deviceId: _deviceId,
            operator: operator,
          );
        }
        for (final String key in remap.plan.restored) {
          await clearRecordFieldRetired(
            _db,
            id: remap.valueIds[key]!,
            clock: _clock,
            deviceId: _deviceId,
            operator: operator,
          );
        }
        await _sendBackToReview(head, operator, templateChangedReason);
      });
      return const Success<void>(null);
    });
  }

  /// Moves record [id] to the recycle bin (D12): status deleted through the
  /// status writer and a `records` tombstone, both with [reason], in one
  /// transaction. The previous status stays in the status audit row for
  /// [restore]; the record's photos and files are not touched, and its
  /// search document is kept so a restore finds it again.
  ///
  /// A blank [reason], or a move to deleted the lifecycle refuses (a record
  /// already deleted, or one being processed), is a [ValidationFailure]; a
  /// record not on this device is a [StorageFailure]; nothing is written.
  ///
  /// `RecordRepository.delete` lands here. The name says what happens rather
  /// than `delete`, so the repository file that calls it holds no call the
  /// data-safety guardrail reads as a hard row delete (FE-SEC-08).
  Future<Result<void>> moveToBin(String id, {required String reason}) {
    return _write<void>((String? operator) async {
      final _Head? head = await _head(id);
      if (head == null) {
        return const FailureResult<void>(_missing);
      }
      if (reason.trim().isEmpty) {
        return const FailureResult<void>(_needsReason);
      }
      final RecordStatus? from = head.status;
      if (from == null) {
        return const FailureResult<void>(_unknownStatus);
      }
      final Result<void> legal = RecordLifecycle.check(
        from,
        RecordStatus.deleted,
      );
      if (legal is FailureResult<void>) {
        return legal;
      }
      await RecordSchema.deferIndexing(_db, () async {
        await writeRecordStatus(
          _db,
          recordId: id,
          status: RecordStatus.deleted.stored,
          previousStatus: from.stored,
          clock: _clock,
          deviceId: _deviceId,
          operator: operator,
          reason: reason,
        );
        await writeTombstone(
          _db,
          entityType: _recordsEntity,
          entityId: id,
          reason: reason,
          clock: _clock,
          deviceId: _deviceId,
        );
      });
      return const Success<void>(null);
    });
  }

  /// Brings record [id] back from the recycle bin whole (D12), in one
  /// transaction: its `records` tombstone is lifted and its status returns,
  /// through the status writer ([restoredReason]), to the status the latest
  /// `status` audit row into deleted says it had. When that status is not a
  /// legal restore target, or the trail holds none, the record lands in
  /// needsReview ([RecordLifecycle.restoreTarget]). The revision bump lets
  /// the restore win over a deletion that has already travelled.
  ///
  /// A record that is not deleted is a [ValidationFailure]; a record not on
  /// this device is a [StorageFailure]; nothing is written.
  Future<Result<void>> restore(String id) {
    return _write<void>((String? operator) async {
      final _Head? head = await _head(id);
      if (head == null) {
        return const FailureResult<void>(_missing);
      }
      if (head.status != RecordStatus.deleted) {
        return const FailureResult<void>(_notInBin);
      }
      final RecordStatus target = RecordLifecycle.restoreTarget(
        RecordStatus.deleted,
        await _statusBeforeDelete(id),
      );
      await RecordSchema.deferIndexing(_db, () async {
        await removeTombstone(_db, entityType: _recordsEntity, entityId: id);
        await writeRecordStatus(
          _db,
          recordId: id,
          status: target.stored,
          previousStatus: RecordStatus.deleted.stored,
          clock: _clock,
          deviceId: _deviceId,
          operator: operator,
          reason: restoredReason,
        );
      });
      return const Success<void>(null);
    });
  }

  // --------------------------------------------------------------- plumbing

  /// Runs [body] in one transaction with the operator resolved, and returns
  /// the [Result] it chose. A throw rolls everything back and reads as a
  /// [StorageFailure].
  Future<Result<T>> _write<T>(
    Future<Result<T>> Function(String? operator) body,
  ) {
    return _inTransaction<T>(() async => body(await _operator()));
  }

  /// Runs [body] in one transaction and returns the [Result] it chose.
  Future<Result<T>> _inTransaction<T>(Future<Result<T>> Function() body) async {
    final Result<Result<T>> outcome = await runInTransaction<Result<T>>(
      _db,
      body,
    );
    return switch (outcome) {
      Success<Result<T>>(:final Result<T> value) => value,
      FailureResult<Result<T>>(failure: final Failure storageFailure) =>
        FailureResult<T>(storageFailure),
    };
  }

  /// The operator to stamp: [_operatorName] when given, else the device
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

  /// Record [id]'s project, template, checklist row and status, or null when
  /// it is not on this device. An unknown stored status reads as null.
  Future<_Head?> _head(String id) async {
    final QueryRow? row = await _db
        .customSelect(
          'SELECT project_id, template_id, template_row_id, status '
          'FROM records WHERE id = ?',
          variables: <Variable<Object>>[Variable<String>(id)],
        )
        .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return (
      id: id,
      projectId: row.read<String>('project_id'),
      templateId: row.read<String>('template_id'),
      templateRowId: row.read<String?>('template_row_id'),
      status: RecordStatus.fromStored(row.read<String>('status')),
    );
  }

  /// [Success] when [head]'s values, photos or template may change.
  Result<void> _editable(_Head head) {
    final RecordStatus? status = head.status;
    return status == null
        ? const Success<void>(null)
        : RecordLifecycle.checkEditable(status);
  }

  /// Writes one edit inside the open transaction; true when it changed what
  /// the field displays.
  Future<bool> _edit(
    String recordId,
    RecordValueEdit edit,
    String? operator,
  ) async {
    final QueryRow? stored = await _db
        .customSelect(
          'SELECT id FROM record_fields WHERE record_id = ? AND field_key = ?',
          variables: <Variable<Object>>[
            Variable<String>(recordId),
            Variable<String>(edit.fieldKey),
          ],
        )
        .getSingleOrNull();
    if (stored == null) {
      if (edit.value.isEmpty) {
        return false;
      }
      _expect(
        await insertRecordField(
          _db,
          row: sqlite.RecordFieldsCompanion(
            recordId: Value<String>(recordId),
            fieldKey: Value<String>(edit.fieldKey),
            valueRaw: Value<String?>(edit.value),
            source: const Value<String>(recordFieldEditSource),
            verified: const Value<bool>(true),
            verifiedBy: Value<String?>(operator),
            verifiedAt: Value<DateTime?>(_clock.nowUtc()),
          ),
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
          operator: operator,
        ),
      );
      return true;
    }
    final String valueId = stored.read<String>('id');
    final bool edited = await writeRecordFieldEdit(
      _db,
      id: valueId,
      value: edit.value,
      clock: _clock,
      deviceId: _deviceId,
      operator: operator,
    );
    if (edited) {
      await clearRecordFieldEvidenceRemoved(
        _db,
        id: valueId,
        clock: _clock,
        deviceId: _deviceId,
        operator: operator,
      );
    }
    return edited;
  }

  /// Moves an approved record back to review (§38) with [reason]; true when
  /// it did.
  Future<bool> _sendBackToReview(
    _Head head,
    String? operator,
    String reason,
  ) async {
    final RecordStatus? status = head.status;
    if (status == null) {
      return false;
    }
    final RecordStatus next = RecordLifecycle.afterEdit(status);
    if (next == status) {
      return false;
    }
    await writeRecordStatus(
      _db,
      recordId: head.id,
      status: next.stored,
      previousStatus: status.stored,
      clock: _clock,
      deviceId: _deviceId,
      operator: operator,
      reason: reason,
    );
    return true;
  }

  /// Bumps record [id]'s revision and update stamps after its values
  /// changed, so a merge carries the change.
  Future<void> _touch(String id) {
    return _db.customUpdate(
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
  }

  /// Appends one record-level audit row for a template change.
  Future<void> _auditRecord(
    String id, {
    required String fieldKey,
    required String previous,
    required String? next,
    required String? operator,
  }) {
    return appendAudit(
      _db,
      entityType: _recordsEntity,
      entityId: id,
      action: AuditAction.updated,
      fieldKey: fieldKey,
      previousValue: previous,
      newValue: next,
      reason: templateChangeAuditReason,
      clock: _clock,
      device: _deviceId,
      operator: operator,
    );
  }

  /// Why template [templateId] cannot hold a record of [projectId], or null
  /// when it can: missing or tombstoned is a storage failure, another
  /// project's template a validation failure.
  Future<Failure?> _unusableTemplate(
    String templateId, {
    required String projectId,
  }) async {
    final QueryRow? template = await _db
        .customSelect(
          'SELECT t.project_id AS project_id FROM templates t WHERE t.id = ? '
          'AND NOT EXISTS (SELECT 1 FROM tombstones x WHERE '
          "x.entity_type = 'templates' AND x.entity_id = t.id)",
          variables: <Variable<Object>>[Variable<String>(templateId)],
        )
        .getSingleOrNull();
    if (template == null) {
      return _missingTemplate;
    }
    final String? owner = template.read<String?>('project_id');
    if (owner != null && owner != projectId) {
      return _otherProject;
    }
    return null;
  }

  /// Recomputes the stored identity hash from the record's identity values.
  Future<void> _refreshIdentityHash(_Head head) async {
    final List<QueryRow> templates = await _db
        .customSelect(
          'SELECT identity_fields FROM templates WHERE id = ?',
          variables: <Variable<Object>>[Variable<String>(head.templateId)],
        )
        .get();
    if (templates.isEmpty) {
      return;
    }
    final Object? decoded = jsonDecode(
      templates.first.read<String>('identity_fields'),
    );
    final List<String> keys = decoded is List
        ? <String>[for (final Object? key in decoded) ?key?.toString()]
        : const <String>[];
    if (keys.isEmpty) {
      return;
    }
    final List<QueryRow> values = await _db
        .customSelect(
          'SELECT field_key, '
          'COALESCE(value_final, value_refined, value_raw) AS value '
          'FROM record_fields WHERE record_id = ?',
          variables: <Variable<Object>>[Variable<String>(head.id)],
        )
        .get();
    final Map<String, Object?> fields = <String, Object?>{
      for (final QueryRow row in values)
        row.read<String>('field_key'): row.read<String>('value'),
    };
    await _db.customUpdate(
      'UPDATE records SET identity_hash = ? WHERE id = ?',
      variables: <Variable<Object>>[
        Variable<String>(identityHash(fields, keys)),
        Variable<String>(head.id),
      ],
      updates: <TableInfo<dynamic, dynamic>>{_db.records},
      updateKind: UpdateKind.update,
    );
  }

  /// The re-map of [head]'s live values onto template [templateId], with the
  /// value id behind each key.
  Future<Result<_Remap>> _plan(_Head head, String templateId) async {
    final Failure? unusable = await _unusableTemplate(
      templateId,
      projectId: head.projectId,
    );
    if (unusable is StorageFailure) {
      return FailureResult<_Remap>(unusable);
    }
    if (templateId == head.templateId) {
      return const FailureResult<_Remap>(_sameTemplate);
    }
    if (unusable != null) {
      return FailureResult<_Remap>(unusable);
    }
    final List<QueryRow> fields = await _db
        .customSelect(
          'SELECT tf.field_key AS field_key FROM template_fields tf '
          'WHERE tf.template_id = ? AND NOT EXISTS (SELECT 1 FROM tombstones '
          "x WHERE x.entity_type = 'template_fields' AND x.entity_id = tf.id) "
          'ORDER BY tf.sort_order, tf.label, tf.field_key',
          variables: <Variable<Object>>[Variable<String>(templateId)],
        )
        .get();
    final List<QueryRow> values = await _db
        .customSelect(
          'SELECT f.id AS id, f.field_key AS field_key, '
          'f.retired_at IS NOT NULL AS retired FROM record_fields f '
          'WHERE f.record_id = ? AND NOT EXISTS (SELECT 1 FROM tombstones x '
          "WHERE x.entity_type = 'record_fields' AND x.entity_id = f.id) "
          'ORDER BY f.rowid',
          variables: <Variable<Object>>[Variable<String>(head.id)],
        )
        .get();
    return Success<_Remap>((
      plan: TemplateChangePlan.forValues(
        fromTemplateId: head.templateId,
        toTemplateId: templateId,
        values: <RecordValue>[
          for (final QueryRow value in values)
            RecordValue(
              fieldKey: value.read<String>('field_key'),
              retired: value.read<int>('retired') != 0,
            ),
        ],
        targetFieldKeys: <String>[
          for (final QueryRow field in fields) field.read<String>('field_key'),
        ],
      ),
      valueIds: <String, String>{
        for (final QueryRow value in values)
          value.read<String>('field_key'): value.read<String>('id'),
      },
    ));
  }

  /// The status record [id] had before its latest move into deleted, from
  /// the `status` audit rows; null when none names a status.
  Future<RecordStatus?> _statusBeforeDelete(String id) async {
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT previous_value FROM audit_log WHERE entity_type = ? '
          'AND entity_id = ? AND field_key = ? AND action = ? '
          'AND new_value = ? ORDER BY at DESC, rowid DESC',
          variables: <Variable<Object>>[
            const Variable<String>(_recordsEntity),
            Variable<String>(id),
            const Variable<String>(recordStatusAuditKey),
            Variable<String>(AuditAction.updated.name),
            Variable<String>(RecordStatus.deleted.stored),
          ],
        )
        .get();
    for (final QueryRow row in rows) {
      final RecordStatus? previous = RecordStatus.fromStored(
        row.read<String?>('previous_value') ?? '',
      );
      if (previous != null) {
        return previous;
      }
    }
    return null;
  }
}

/// A record's identity and state, read at the start of a write.
typedef _Head = ({
  String id,
  String projectId,
  String templateId,
  String? templateRowId,
  RecordStatus? status,
});

/// A template change plan with the value id behind each field key.
typedef _Remap = ({TemplateChangePlan plan, Map<String, String> valueIds});

/// Audit entity and tombstone entity type of a record.
const String _recordsEntity = 'records';

/// Throws the failure [result] carries, so the open transaction rolls back.
void _expect<T>(Result<T> result) {
  if (result case FailureResult<T>(failure: final Failure writeFailure)) {
    throw StorageFailure(
      message: writeFailure.message,
      recoveryAction: writeFailure.recoveryAction ?? _tryAgain,
    );
  }
}

const String _tryAgain = 'Try again.';

const StorageFailure _missing = StorageFailure(
  message: 'That record is no longer on this device.',
  recoveryAction: 'Refresh the list and try again.',
);

const StorageFailure _missingTemplate = StorageFailure(
  message: 'That template is no longer on this device.',
  recoveryAction: 'Choose another template and try again.',
);

const ValidationFailure _sameTemplate = ValidationFailure(
  message: 'This record already uses that template.',
  recoveryAction: 'Choose a different template.',
);

const ValidationFailure _otherProject = ValidationFailure(
  message: 'That template belongs to another project.',
  recoveryAction: 'Choose a template from this project.',
);

const ValidationFailure _needsProjectAndTemplate = ValidationFailure(
  message: 'A record needs a project and a template.',
  recoveryAction: 'Choose a project and a template, then save again.',
);

const ValidationFailure _needsReason = ValidationFailure(
  message: 'A delete needs a reason.',
  recoveryAction: 'Say why the record should go, then try again.',
);

const ValidationFailure _needsField = ValidationFailure(
  message: 'An edit needs the field it changes.',
  recoveryAction: 'Choose a field, then save again.',
);

const ValidationFailure _useDelete = ValidationFailure(
  message: 'A record goes to the recycle bin only through delete.',
  recoveryAction: 'Use Delete, which lets you undo it.',
);

const ValidationFailure _useRestore = ValidationFailure(
  message: 'This record is in the recycle bin.',
  recoveryAction: 'Restore it from the recycle bin first.',
);

const ValidationFailure _notInBin = ValidationFailure(
  message: 'This record is not in the recycle bin.',
  recoveryAction: 'Refresh the list; it may already be restored.',
);

const ValidationFailure _unknownStatus = ValidationFailure(
  message: 'This record has a status this version of the app does not know.',
  recoveryAction: 'Update the app, then try again.',
);

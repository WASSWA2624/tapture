import 'package:drift/drift.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/record_fields.dart'
    show insertRecordField;
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/fields/field_value.dart' show ValueSource;
import 'package:tapture/features/processing/processing.dart'
    show PreviewedValue, ProposalPreview;
import 'package:tapture/features/records/domain/domain.dart' show RecordValue;

/// Commits an operator's exact proposal decisions beside the retained evidence.
final class ReviewProposalWriter {
  /// Uses the same guarded preview as review, without an online request.
  const ReviewProposalWriter({
    required this._db,
    required this._clock,
    required this._proposals,
    required this._refreshIdentity,
  });

  final AppDatabase _db;
  final Clock _clock;
  final ProposalPreview _proposals;
  final Future<void> Function(String recordId) _refreshIdentity;

  /// Rejects stale or invented decisions before writing the entire selection.
  Future<Result<void>> resolve(
    String recordId, {
    required Map<String, String> accepted,
    required Map<String, String> rejected,
  }) async {
    if (accepted.isEmpty && rejected.isEmpty) return const Success<void>(null);
    try {
      final Map<String, String> decisions = <String, String>{
        ...accepted,
        ...rejected,
      };
      if (accepted.keys.any(rejected.containsKey)) throw Failure.from(_stale());
      final _Snapshot snapshot = await _snapshot(recordId);
      _validate(await _proposals.forRecord(recordId), decisions);
      return runInTransaction<void>(_db, () async {
        final _Snapshot current = await _snapshot(recordId);
        if (current != snapshot) throw Failure.from(_stale());
        _validate(await _proposals.forRecord(recordId), decisions);
        final profile = await _db.select(_db.deviceProfile).getSingleOrNull();
        final String device = profile?.deviceId ?? '';
        final String operator = profile?.operatorName ?? '';
        final DateTime now = _clock.nowUtc();
        for (final MapEntry<String, String> decision in decisions.entries) {
          final RecordField? field =
              await (_db.select(_db.recordFields)..where(
                    ($RecordFieldsTable t) =>
                        t.recordId.equals(recordId) &
                        t.fieldKey.equals(decision.key),
                  ))
                  .getSingleOrNull();
          final String shown = _shown(field);
          final bool accept = accepted.containsKey(decision.key);
          final bool clear =
              !accept &&
              field != null &&
              !field.verified &&
              field.valueFinal == null &&
              RecordValue.sourceOf(field.source) != ValueSource.manual &&
              (shown == decision.value || decision.value == field.valueRaw);
          if (accept || clear) {
            if (field == null) {
              final Result<RecordField> inserted = await insertRecordField(
                _db,
                row: RecordFieldsCompanion.insert(
                  createdAt: now,
                  updatedAt: now,
                  updatedByDevice: device,
                  recordId: recordId,
                  fieldKey: decision.key,
                  valueRaw: Value<String?>(decision.value),
                  valueFinal: Value<String?>(decision.value),
                  source: 'manual',
                  verified: const Value<bool>(true),
                  verifiedBy: Value<String?>(operator),
                  verifiedAt: Value<DateTime?>(now),
                ),
                clock: _clock,
                deviceId: device,
                ids: UuidV7Service(_clock),
                operator: operator,
                auditReason: Copy.reviewProposalsApplied(1),
              );
              inserted.fold(
                (Failure failure) => throw Failure.from(failure),
                (_) {},
              );
            } else {
              await (_db.update(
                _db.recordFields,
              )..where(($RecordFieldsTable t) => t.id.equals(field.id))).write(
                RecordFieldsCompanion(
                  valueFinal: Value<String?>(accept ? decision.value : ''),
                  source: Value<String>(accept ? field.source : 'manual'),
                  verified: Value<bool>(accept),
                  verifiedBy: Value<String?>(accept ? operator : null),
                  verifiedAt: Value<DateTime?>(accept ? now : null),
                  updatedAt: Value<DateTime>(now),
                  updatedByDevice: Value<String>(device),
                  rev: Value<int>(field.rev + 1),
                ),
              );
            }
          }
          if ((accept || clear) && field != null) {
            await appendAudit(
              _db,
              entityType: 'records',
              entityId: recordId,
              action: AuditAction.updated,
              fieldKey: decision.key,
              previousValue: shown,
              newValue: accept ? decision.value : '',
              reason: accept
                  ? Copy.reviewProposalsApplied(1)
                  : Copy.reviewProposalsRejected,
              clock: _clock,
              device: device,
              operator: operator,
            );
          }
          await appendAudit(
            _db,
            entityType: 'processing',
            entityId: snapshot.jobId,
            action: AuditAction.updated,
            fieldKey: decision.key,
            previousValue: shown,
            newValue: decision.value,
            reason:
                '${accept ? 'proposal-accepted' : 'proposal-rejected'}:'
                '${snapshot.generation}',
            clock: _clock,
            device: device,
            operator: operator,
          );
        }
        await _refreshIdentity(recordId);
        await _db.customUpdate(
          'UPDATE records SET updated_at = ?, updated_by_device = ?, '
          'rev = rev + 1 WHERE id = ?',
          variables: <Variable<Object>>[
            Variable<DateTime>(now),
            Variable<String>(device),
            Variable<String>(recordId),
          ],
          updates: <TableInfo<dynamic, dynamic>>{_db.records},
        );
      });
    } on Failure catch (failure) {
      return FailureResult<void>(failure);
    } on Object catch (error) {
      return FailureResult<void>(storageFailureFrom(error));
    }
  }

  Future<_Snapshot> _snapshot(String recordId) async {
    final row = await (_db.select(
      _db.records,
    )..where(($RecordsTable t) => t.id.equals(recordId))).getSingleOrNull();
    final job =
        await (_db.select(_db.processing)
              ..where(($ProcessingTable t) => t.recordId.equals(recordId))
              ..orderBy(<OrderClauseGenerator<$ProcessingTable>>[
                ($ProcessingTable t) => OrderingTerm.desc(t.queuedAt),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (row == null ||
        job == null ||
        const <String>{
          'approved',
          'deleted',
          'archived',
          'queued',
          'processing',
        }.contains(row.status)) {
      throw Failure.from(_stale());
    }
    return (rev: row.rev, jobId: job.id, generation: job.requestGeneration);
  }

  void _validate(
    Result<List<PreviewedValue>> read,
    Map<String, String> decisions,
  ) {
    final List<PreviewedValue> proposals = read.fold(
      (Failure failure) => throw Failure.from(failure),
      (List<PreviewedValue> values) => values,
    );
    final Map<String, String> byKey = <String, String>{
      for (final PreviewedValue value in proposals) value.fieldKey: value.value,
    };
    if (decisions.entries.any(
      (MapEntry<String, String> decision) =>
          byKey[decision.key] != decision.value,
    )) {
      throw Failure.from(_stale());
    }
  }
}

typedef _Snapshot = ({int rev, String jobId, int generation});

String _shown(RecordField? field) =>
    field?.valueFinal ?? field?.valueRefined ?? field?.valueRaw ?? '';

ValidationFailure _stale() => ValidationFailure(
  localizedMessage: Copy.messages.reviewProposalsChanged,
  localizedRecovery: Copy.messages.reviewProposalsChangedRecovery,
);

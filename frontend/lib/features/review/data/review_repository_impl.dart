import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/database_provider.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/quality/quality.dart'
    show identityKeysOf, storedIdentityHash;

import '../domain/review_repository.dart';

/// The Drift review store (task 016): conflicts, verifiers and evidence
/// read beside a record, a verify that leaves the value as it was, and the
/// choice of which stored side is final.
///
/// Both writes are one transaction each, stamped with this device and its
/// operator from the device profile, with one audit row per value changed.
/// Neither touches the raw or refined columns, so nothing captured is lost.
final class ReviewRepositoryImpl implements ReviewRepository {
  /// Creates the store over [db], stamped with [clock].
  const ReviewRepositoryImpl({
    required this._db,
    this._clock = const SystemClock(),
  });

  final AppDatabase _db;
  final Clock _clock;

  @override
  Future<Result<ReviewFacts>> facts(String recordId) async {
    try {
      final List<QueryRow> conflicts = await _db
          .customSelect(
            'SELECT rf.field_key AS field_key FROM merge_conflicts mc '
            'JOIN record_fields rf ON rf.id = mc.entity_id '
            "WHERE mc.resolution IS NULL AND mc.entity_type = 'record_fields' "
            'AND rf.record_id = ? '
            'UNION SELECT mc.field_key AS field_key FROM merge_conflicts mc '
            "WHERE mc.resolution IS NULL AND mc.entity_type = 'records' "
            'AND mc.entity_id = ? '
            'UNION SELECT mc.field_key AS field_key FROM merge_conflicts mc '
            'JOIN photos p ON p.id = mc.entity_id '
            "WHERE mc.resolution IS NULL AND mc.entity_type = 'photos' "
            'AND p.record_id = ?',
            variables: <Variable<Object>>[
              Variable<String>(recordId),
              Variable<String>(recordId),
              Variable<String>(recordId),
            ],
          )
          .get();
      final List<QueryRow> verified = await _db
          .customSelect(
            'SELECT field_key, verified_by FROM record_fields '
            'WHERE record_id = ? AND verified = 1',
            variables: <Variable<Object>>[Variable<String>(recordId)],
          )
          .get();
      final List<QueryRow> evidence = await _db
          .customSelect(
            'SELECT rf.field_key AS field_key, fe.source_type AS source_type, '
            'fe.photo_id AS photo_id, fe.page AS page, fe.region AS region, '
            'fe.snippet AS snippet, p.width AS photo_width, '
            'p.height AS photo_height FROM field_evidence fe '
            'JOIN record_fields rf ON rf.id = fe.record_field_id '
            'LEFT JOIN photos p ON p.id = fe.photo_id '
            'WHERE rf.record_id = ? AND NOT EXISTS (SELECT 1 FROM tombstones t '
            "WHERE t.entity_type = 'field_evidence' AND t.entity_id = fe.id) "
            'ORDER BY fe.created_at, fe.id',
            variables: <Variable<Object>>[Variable<String>(recordId)],
          )
          .get();
      final Map<String, List<ValueEvidence>> byField =
          <String, List<ValueEvidence>>{};
      for (final QueryRow row in evidence) {
        byField
            .putIfAbsent(row.read<String>('field_key'), () => <ValueEvidence>[])
            .add((
              kind: _kind(row.read<String>('source_type')),
              photoId: row.read<String?>('photo_id'),
              page: row.read<int?>('page'),
              regionJson: row.read<String?>('region'),
              snippet: row.read<String?>('snippet'),
              photoWidth: row.read<int?>('photo_width'),
              photoHeight: row.read<int?>('photo_height'),
            ));
      }
      return Success<ReviewFacts>((
        conflicts: <String>{
          for (final QueryRow row in conflicts) row.read<String>('field_key'),
        },
        verifiedBy: <String, String>{
          for (final QueryRow row in verified)
            row.read<String>('field_key'):
                row.read<String?>('verified_by') ?? '',
        },
        evidence: byField,
      ));
    } on Object catch (error) {
      return FailureResult<ReviewFacts>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<void>> verify(String recordId, List<String> fieldKeys) async {
    final Failure? refused = await _refusal(recordId);
    if (refused != null) {
      return FailureResult<void>(refused);
    }
    final List<String> keys = <String>{...fieldKeys}.toList();
    if (keys.isEmpty) {
      return const Success<void>(null);
    }
    return runInTransaction<void>(_db, () async {
      final _Stamp stamp = await _stamp();
      final DateTime now = _clock.nowUtc();
      final List<QueryRow> open = await _db
          .customSelect(
            'SELECT id, field_key FROM record_fields WHERE record_id = ? '
            'AND verified = 0 AND field_key IN (${_marks(keys)}) '
            "AND COALESCE(NULLIF(value_final, ''), NULLIF(value_refined, ''), "
            "NULLIF(value_raw, '')) IS NOT NULL",
            variables: <Variable<Object>>[
              Variable<String>(recordId),
              for (final String key in keys) Variable<String>(key),
            ],
          )
          .get();
      for (final QueryRow row in open) {
        await _db.customUpdate(
          'UPDATE record_fields SET verified = 1, verified_by = ?, '
          'verified_at = ?, updated_at = ?, updated_by_device = ?, '
          'rev = rev + 1 WHERE id = ?',
          variables: <Variable<Object>>[
            Variable<String>(stamp.operator ?? ''),
            Variable<DateTime>(now),
            Variable<DateTime>(now),
            Variable<String>(stamp.device),
            Variable<String>(row.read<String>('id')),
          ],
          updates: <TableInfo<dynamic, dynamic>>{_db.recordFields},
          updateKind: UpdateKind.update,
        );
        await appendAudit(
          _db,
          entityType: _recordsEntity,
          entityId: recordId,
          action: AuditAction.updated,
          fieldKey: row.read<String>('field_key'),
          previousValue: 'false',
          newValue: 'true',
          reason: Copy.reviewVerifiedReason,
          clock: _clock,
          device: stamp.device,
          operator: stamp.operator,
        );
      }
      if (open.isNotEmpty) {
        await _touch(recordId, stamp.device, now);
      }
    });
  }

  @override
  Future<Result<void>> chooseFinal(
    String recordId,
    String fieldKey,
    String value,
  ) async {
    final Failure? refused = await _refusal(recordId);
    if (refused != null) {
      return FailureResult<void>(refused);
    }
    return runInTransaction<void>(_db, () async {
      final QueryRow? stored = await _db
          .customSelect(
            'SELECT id, value_raw, value_refined, value_final '
            'FROM record_fields WHERE record_id = ? AND field_key = ?',
            variables: <Variable<Object>>[
              Variable<String>(recordId),
              Variable<String>(fieldKey),
            ],
          )
          .getSingleOrNull();
      if (stored == null) {
        return;
      }
      final String? current = stored.read<String?>('value_final');
      if (current == value) {
        return;
      }
      final String shown = <String>[
        current ?? '',
        stored.read<String?>('value_refined') ?? '',
        stored.read<String?>('value_raw') ?? '',
      ].firstWhere((String side) => side.isNotEmpty, orElse: () => '');
      final _Stamp stamp = await _stamp();
      final DateTime now = _clock.nowUtc();
      await _db.customUpdate(
        'UPDATE record_fields SET value_final = ?, updated_at = ?, '
        'updated_by_device = ?, rev = rev + 1 WHERE id = ?',
        variables: <Variable<Object>>[
          Variable<String>(value),
          Variable<DateTime>(now),
          Variable<String>(stamp.device),
          Variable<String>(stored.read<String>('id')),
        ],
        updates: <TableInfo<dynamic, dynamic>>{_db.recordFields},
        updateKind: UpdateKind.update,
      );
      await appendAudit(
        _db,
        entityType: _recordsEntity,
        entityId: recordId,
        action: AuditAction.updated,
        fieldKey: fieldKey,
        previousValue: shown.isEmpty ? null : shown,
        newValue: value,
        reason: Copy.reviewSideReason,
        clock: _clock,
        device: stamp.device,
        operator: stamp.operator,
      );
      await _refreshIdentityHash(recordId);
      await _touch(recordId, stamp.device, now);
    });
  }

  /// Why [recordId] may not be changed here, or null when it may: it must be
  /// on this device, and neither approved nor in the recycle bin.
  Future<Failure?> _refusal(String recordId) async {
    try {
      final QueryRow? row = await _db
          .customSelect(
            'SELECT status FROM records WHERE id = ?',
            variables: <Variable<Object>>[Variable<String>(recordId)],
          )
          .getSingleOrNull();
      if (row == null) {
        return StorageFailure(
          localizedMessage: Copy.messages.reviewRecordGone,
          localizedRecovery: Copy.messages.reviewRecordGoneAction,
        );
      }
      final RecordStatus? status = RecordStatus.fromStored(
        row.read<String>('status'),
      );
      if (status == RecordStatus.approved || status == RecordStatus.deleted) {
        return ValidationFailure(
          localizedMessage: Copy.messages.reviewRecordSettled,
          localizedRecovery: Copy.messages.reviewRecordSettledAction,
        );
      }
      return null;
    } on Object catch (error) {
      return storageFailureFrom(error);
    }
  }

  /// This device and its operator, from the device profile.
  Future<_Stamp> _stamp() async {
    final QueryRow? profile = await _db
        .customSelect(
          'SELECT device_id, operator_name FROM device_profile LIMIT 1',
        )
        .getSingleOrNull();
    final String name = (profile?.read<String?>('operator_name') ?? '').trim();
    return (
      device: profile?.read<String?>('device_id') ?? '',
      operator: name.isEmpty ? null : name,
    );
  }

  /// Bumps record [recordId]'s revision after one of its values changed, so
  /// a merge carries the change.
  Future<void> _touch(String recordId, String device, DateTime now) {
    return _db.customUpdate(
      'UPDATE records SET updated_at = ?, updated_by_device = ?, '
      'rev = rev + 1 WHERE id = ?',
      variables: <Variable<Object>>[
        Variable<DateTime>(now),
        Variable<String>(device),
        Variable<String>(recordId),
      ],
      updates: <TableInfo<dynamic, dynamic>>{_db.records},
      updateKind: UpdateKind.update,
    );
  }

  /// Recomputes the stored identity hash after a final value changed, as a
  /// value edit does.
  Future<void> _refreshIdentityHash(String recordId) async {
    final QueryRow? template = await _db
        .customSelect(
          'SELECT t.identity_fields AS identity_fields FROM records r '
          'JOIN templates t ON t.id = r.template_id WHERE r.id = ?',
          variables: <Variable<Object>>[Variable<String>(recordId)],
        )
        .getSingleOrNull();
    final List<String> keys = identityKeysOf(
      template?.read<String?>('identity_fields'),
    );
    if (keys.isEmpty) {
      return;
    }
    final List<QueryRow> values = await _db
        .customSelect(
          'SELECT field_key, '
          'COALESCE(value_final, value_refined, value_raw) AS value '
          'FROM record_fields WHERE record_id = ?',
          variables: <Variable<Object>>[Variable<String>(recordId)],
        )
        .get();
    await _db.customUpdate(
      'UPDATE records SET identity_hash = ? WHERE id = ?',
      variables: <Variable<Object>>[
        Variable<String>(
          storedIdentityHash(
            recordId: recordId,
            values: <String, Object?>{
              for (final QueryRow row in values)
                row.read<String>('field_key'): row.read<String?>('value'),
            },
            identityKeys: keys,
          ),
        ),
        Variable<String>(recordId),
      ],
      updates: <TableInfo<dynamic, dynamic>>{_db.records},
      updateKind: UpdateKind.update,
    );
  }
}

/// Who and where a write is stamped with.
typedef _Stamp = ({String device, String? operator});

/// Audit entity of a value change: the record it belongs to.
const String _recordsEntity = 'records';

EvidenceKind _kind(String stored) {
  return switch (stored) {
    'document' => EvidenceKind.document,
    'transcript' => EvidenceKind.transcript,
    _ => EvidenceKind.photo,
  };
}

String _marks(List<String> values) =>
    List<String>.filled(values.length, '?').join(', ');

/// The review store over the database opened in `main`. Tests override it.
final Provider<ReviewRepository> reviewRepositoryProvider =
    Provider<ReviewRepository>((Ref ref) {
      return ReviewRepositoryImpl(db: ref.watch(appDatabaseProvider));
    });

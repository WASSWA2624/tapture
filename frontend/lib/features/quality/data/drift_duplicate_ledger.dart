import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/records/records.dart'
    show RecordRepository, RecordValueEdit;

import '../domain/duplicate_ledger.dart';

/// The ledger a resolution writes through (task 015).
///
/// [DuplicateOverride], [DuplicateLink] and the merge hand it their writes
/// in order; [commit] then applies them inside the caller's transaction:
/// value edits through the record store, so history keeps what each field
/// showed before; photos re-filed from [sourceRecordId] onto
/// [targetRecordId], each with its own audit row; and one audit row per
/// record naming the choice, both records and the person.
final class DriftDuplicateLedger implements DuplicateLedger {
  /// Creates a ledger that writes onto [targetRecordId], taking photos from
  /// [sourceRecordId].
  DriftDuplicateLedger({
    required this.targetRecordId,
    required this.sourceRecordId,
  });

  /// The record that keeps the values and receives the photos.
  final String targetRecordId;

  /// The record photos are taken from.
  final String sourceRecordId;

  final List<RecordValueEdit> _edits = <RecordValueEdit>[];
  final List<String> _photos = <String>[];
  final List<_Audit> _audits = <_Audit>[];

  @override
  void replaceValue({
    required String fieldKey,
    required String? previous,
    required String next,
  }) {
    _edits.add((fieldKey: fieldKey, value: next));
  }

  @override
  void attachPhoto(String sha256) {
    _photos.add(sha256);
  }

  @override
  void addAudit({
    required String action,
    required String leftId,
    required String rightId,
    required String person,
    required String detail,
  }) {
    _audits.add((
      action: action,
      leftId: leftId,
      rightId: rightId,
      person: person,
      detail: detail,
    ));
  }

  /// Applies every write, in the order it arrived, inside the open
  /// transaction on [db]. A failed write throws, so the caller's
  /// transaction rolls back whole.
  Future<void> commit({
    required AppDatabase db,
    required RecordRepository records,
    required String projectId,
    required Clock clock,
    required String deviceId,
    required IdService ids,
  }) async {
    if (_edits.isNotEmpty) {
      final Result<void> edited = await records.editValues(
        targetRecordId,
        List<RecordValueEdit>.unmodifiable(_edits),
      );
      if (edited case FailureResult<void>(failure: final Failure editFailure)) {
        throw editFailure;
      }
    }
    for (final String sha256 in _photos) {
      await _refile(
        db,
        sha256: sha256,
        projectId: projectId,
        clock: clock,
        deviceId: deviceId,
        ids: ids,
      );
    }
    for (final _Audit audit in _audits) {
      for (final (String entity, String other) in <(String, String)>[
        (audit.leftId, audit.rightId),
        (audit.rightId, audit.leftId),
      ]) {
        await appendAudit(
          db,
          entityType: _recordsEntity,
          entityId: entity,
          action: AuditAction.updated,
          fieldKey: duplicateAuditKey,
          previousValue: other,
          newValue: audit.action,
          reason: audit.detail,
          clock: clock,
          device: deviceId,
          operator: audit.person,
        );
      }
    }
  }

  /// Files the photo [sha256] of [sourceRecordId] on [targetRecordId]. The
  /// file and its row stay; only the row's record changes, with an audit row
  /// naming both records.
  Future<void> _refile(
    AppDatabase db, {
    required String sha256,
    required String projectId,
    required Clock clock,
    required String deviceId,
    required IdService ids,
  }) async {
    final List<QueryRow> rows = await db
        .customSelect(
          'SELECT id FROM photos WHERE project_id = ? AND sha256 = ? '
          'AND record_id = ?',
          variables: <Variable<Object>>[
            Variable<String>(projectId),
            Variable<String>(sha256),
            Variable<String>(sourceRecordId),
          ],
        )
        .get();
    for (final QueryRow row in rows) {
      final String photoId = row.read<String>('id');
      final Result<Photo> moved = await upsertPhoto(
        db,
        row: PhotosCompanion(
          id: Value<String>(photoId),
          recordId: Value<String?>(targetRecordId),
        ),
        clock: clock,
        deviceId: deviceId,
        ids: ids,
      );
      if (moved case FailureResult<Photo>(failure: final Failure moveFailure)) {
        throw moveFailure;
      }
      await appendAudit(
        db,
        entityType: _photosEntity,
        entityId: photoId,
        action: AuditAction.updated,
        fieldKey: _photoRecordKey,
        previousValue: sourceRecordId,
        newValue: targetRecordId,
        reason: duplicateAuditKey,
        clock: clock,
        device: deviceId,
      );
    }
  }
}

/// Audit field key of every duplicate resolution row.
const String duplicateAuditKey = 'duplicate';

/// One audit row a resolution asked for.
typedef _Audit = ({
  String action,
  String leftId,
  String rightId,
  String person,
  String detail,
});

const String _recordsEntity = 'records';

const String _photosEntity = 'photos';

const String _photoRecordKey = 'record_id';

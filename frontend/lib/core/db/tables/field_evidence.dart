import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

/// Provenance for one record-field value: photo region, document page or
/// transcript segment.
@TableIndex(name: 'field_evidence_by_field', columns: {#recordFieldId})
@DataClassName('FieldEvidenceRow')
class FieldEvidence extends Table with MergeColumns {
  /// Record field this evidence supports.
  TextColumn get recordFieldId => text()();

  /// Photo, document or transcript.
  TextColumn get sourceType => textEnum<FieldEvidenceSource>()();

  /// Photo this region came from, when [sourceType] is photo.
  TextColumn get photoId => text().nullable()();

  /// Document this page came from, when [sourceType] is document.
  TextColumn get documentId => text().nullable()();

  /// Document page number, when known.
  IntColumn get page => integer().nullable()();

  /// Bounding box JSON. An object, stored as text.
  TextColumn get region => text().nullable()();

  /// Transcript segment or OCR snippet, stored as data.
  TextColumn get snippet => text().nullable()();

  /// Confidence of the extraction, when the provider reported one.
  RealColumn get confidence => real().nullable()();
}

/// Where a [FieldEvidenceRow] came from.
enum FieldEvidenceSource {
  /// A photo region.
  photo,

  /// A document page.
  document,

  /// A transcript segment.
  transcript,
}

/// Inserts an evidence row after refusing a malformed [FieldEvidence.region].
Future<Result<FieldEvidenceRow>> insertFieldEvidence(
  GeneratedDatabase db, {
  required Insertable<FieldEvidenceRow> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    _ensureRegionJson(row);
  } on Failure catch (failure) {
    return FailureResult<FieldEvidenceRow>(failure);
  }
  final AppDatabase database = db as AppDatabase;
  return _FieldEvidenceDao(
    database,
    clock: clock,
    deviceId: deviceId,
    ids: ids,
  ).upsert(row);
}

/// Evidence rows for [recordFieldId], oldest first.
Future<Result<List<FieldEvidenceRow>>> listFieldEvidenceForField(
  GeneratedDatabase db, {
  required String recordFieldId,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final List<FieldEvidenceRow> rows =
        await (database.select(database.fieldEvidence)
              ..where(
                ($FieldEvidenceTable tbl) =>
                    tbl.recordFieldId.equals(recordFieldId),
              )
              ..orderBy(<OrderClauseGenerator<$FieldEvidenceTable>>[
                ($FieldEvidenceTable tbl) => OrderingTerm.asc(tbl.createdAt),
                ($FieldEvidenceTable tbl) => OrderingTerm.asc(tbl.id),
              ]))
            .get();
    return Success<List<FieldEvidenceRow>>(rows);
  } on Failure catch (failure) {
    return FailureResult<List<FieldEvidenceRow>>(failure);
  } on Object catch (error) {
    return FailureResult<List<FieldEvidenceRow>>(storageFailureFrom(error));
  }
}

void _ensureRegionJson(Insertable<FieldEvidenceRow> row) {
  final Expression<Object>? expression = row.toColumns(false)['region'];
  if (expression is! Variable<String>) {
    return;
  }
  final String? raw = expression.value;
  if (raw == null) {
    return;
  }
  late final Object? decoded;
  try {
    decoded = jsonDecode(raw) as Object?;
  } on FormatException {
    throw const StorageFailure(
      message: 'A bounding box is not valid JSON.',
      recoveryAction: 'Fix the region object and save again.',
    );
  }
  if (decoded is! Map) {
    throw const StorageFailure(
      message: 'A bounding box must be a JSON object.',
      recoveryAction: 'Fix the region object and save again.',
    );
  }
}

final class _FieldEvidenceDao extends BaseDao<FieldEvidence, FieldEvidenceRow> {
  _FieldEvidenceDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.fieldEvidence);
}

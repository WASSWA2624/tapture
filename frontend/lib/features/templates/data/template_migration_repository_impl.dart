import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/database_provider.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/field_def.dart';
import '../domain/template_def.dart';
import '../domain/template_migration_repository.dart';
import '../domain/template_versioning.dart';

/// Local, audited template migrations. No value column is ever overwritten.
final class TemplateMigrationRepositoryImpl
    implements TemplateMigrationRepository {
  /// Uses the same database connection and transaction as record writes.
  const TemplateMigrationRepositoryImpl({
    required this._db,
    this._clock = const SystemClock(),
  });

  final AppDatabase _db;
  final Clock _clock;

  @override
  Future<Result<Map<String, int>>> fieldValueCounts(String templateId) async {
    try {
      final List<QueryRow> rows = await _db
          .customSelect(
            'SELECT f.field_key, COUNT(*) AS value_count '
            'FROM records r JOIN record_fields f ON f.record_id = r.id '
            "WHERE r.template_id = ? AND r.status != 'deleted' "
            "AND NOT EXISTS (SELECT 1 FROM tombstones t WHERE t.entity_type = 'records' AND t.entity_id = r.id) "
            "AND NOT EXISTS (SELECT 1 FROM tombstones t WHERE t.entity_type = 'record_fields' AND t.entity_id = f.id) "
            "AND (NULLIF(TRIM(f.value_raw), '') IS NOT NULL "
            "OR NULLIF(TRIM(f.value_refined), '') IS NOT NULL "
            "OR NULLIF(TRIM(f.value_final), '') IS NOT NULL) "
            'GROUP BY f.field_key',
            variables: <Variable<Object>>[Variable<String>(templateId)],
          )
          .get();
      return Success<Map<String, int>>(<String, int>{
        for (final QueryRow row in rows)
          row.read<String>('field_key'): row.read<int>('value_count'),
      });
    } on Object catch (error) {
      return FailureResult<Map<String, int>>(storageFailureFrom(error));
    }
  }

  @override
  Stream<List<CapturedTemplateRecord>> watch(String templateId) {
    return _db
        .customSelect(
          'SELECT r.id, r.template_version, f.field_key, f.value_raw, '
          'f.value_refined, f.value_final, f.retired_at '
          'FROM records r LEFT JOIN record_fields f ON f.record_id = r.id '
          "AND NOT EXISTS (SELECT 1 FROM tombstones t WHERE t.entity_type = 'record_fields' AND t.entity_id = f.id) "
          "WHERE r.template_id = ? AND r.status != 'deleted' "
          "AND NOT EXISTS (SELECT 1 FROM tombstones t WHERE t.entity_type = 'records' AND t.entity_id = r.id) "
          'ORDER BY r.id, f.field_key',
          variables: <Variable<Object>>[Variable<String>(templateId)],
          readsFrom: <TableInfo<dynamic, dynamic>>{
            _db.records,
            _db.recordFields,
            _db.tombstones,
          },
        )
        .watch()
        .map(_captured);
  }

  @override
  Future<Result<void>> migrate({
    required TemplateDef template,
    required List<CapturedTemplateRecord> reviewed,
  }) {
    return runInTransaction(_db, () async {
      final Template? latest =
          await (_db.select(_db.templates)
                ..where(($TemplatesTable row) => row.id.equals(template.id)))
              .getSingleOrNull();
      if (latest == null || latest.version != template.version) {
        throw _staleFailure;
      }
      final Set<String> active = <String>{
        for (final FieldDef field in template.fields) field.fieldKey,
      };
      final DateTime now = _clock.nowUtc();
      final List<DeviceProfileRow> profiles = await _db
          .select(_db.deviceProfile)
          .get();
      final String device = profiles.isEmpty ? '' : profiles.first.deviceId;
      for (final CapturedTemplateRecord reviewedRecord in reviewed) {
        if (reviewedRecord.templateVersion >= template.version) {
          continue;
        }
        final RecordRow? record =
            await (_db.select(_db.records)..where(
                  ($RecordsTable row) => row.id.equals(reviewedRecord.id),
                ))
                .getSingleOrNull();
        if (record == null ||
            record.templateId != template.id ||
            record.templateVersion != reviewedRecord.templateVersion ||
            record.status == 'deleted') {
          throw _staleFailure;
        }
        final List<RecordField> fields =
            await (_db.select(_db.recordFields)..where(
                  ($RecordFieldsTable row) => row.recordId.equals(record.id),
                ))
                .get();
        for (final RecordField field in fields) {
          final bool retire = !active.contains(field.fieldKey);
          if (retire == (field.retiredAt != null)) {
            continue;
          }
          if (retire) {
            await setRecordFieldRetired(
              _db,
              id: field.id,
              clock: _clock,
              deviceId: device,
            );
          } else {
            await clearRecordFieldRetired(
              _db,
              id: field.id,
              clock: _clock,
              deviceId: device,
            );
          }
        }
        await (_db.update(
          _db.records,
        )..where(($RecordsTable row) => row.id.equals(record.id))).write(
          RecordsCompanion(
            templateVersion: Value<int>(template.version),
            rev: Value<int>(record.rev + 1),
            updatedAt: Value<DateTime>(now),
            updatedByDevice: Value<String>(device),
          ),
        );
        await appendAudit(
          _db,
          entityType: 'records',
          entityId: record.id,
          action: AuditAction.updated,
          fieldKey: 'template_version',
          previousValue: '${record.templateVersion}',
          newValue: '${template.version}',
          reason: 'Template migration',
          clock: _clock,
          device: device,
        );
      }
    });
  }
}

/// Uses the application database; tests inject the same port or a memory DB.
final Provider<TemplateMigrationRepository>
templateMigrationRepositoryProvider = Provider<TemplateMigrationRepository>(
  (Ref ref) =>
      TemplateMigrationRepositoryImpl(db: ref.watch(appDatabaseProvider)),
);

List<CapturedTemplateRecord> _captured(List<QueryRow> rows) {
  final Map<String, CapturedTemplateRecord> records =
      <String, CapturedTemplateRecord>{};
  for (final QueryRow row in rows) {
    final String id = row.read<String>('id');
    final CapturedTemplateRecord record = records.putIfAbsent(
      id,
      () => (
        id: id,
        templateVersion: row.read<int>('template_version'),
        fields: <String, String>{},
        retired: <String>{},
      ),
    );
    final String? field = row.readNullable<String>('field_key');
    if (field == null) {
      continue;
    }
    record.fields[field] =
        row.readNullable<String>('value_final') ??
        row.readNullable<String>('value_refined') ??
        row.readNullable<String>('value_raw') ??
        '';
    if (row.data['retired_at'] != null) {
      record.retired.add(field);
    }
  }
  return records.values.toList(growable: false);
}

/// The template or a reviewed record moved on after the preview was read.
final StorageFailure _staleFailure = StorageFailure(
  localizedMessage: Copy.messages.failureTheTemplateOrItsRecordsChangedWhile,
  localizedRecovery: Copy.messages.failureReviewTheUpdatedChangesAndTryAgain,
);

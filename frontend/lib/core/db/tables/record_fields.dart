import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

/// One field value on a record. Unique on [recordId] plus [fieldKey].
///
/// The raw column is written once at insert. Refinement writes
/// [valueRefined]; approval writes [valueFinal].
@TableIndex(name: 'record_fields_by_final', columns: {#fieldKey, #valueFinal})
class RecordFields extends Table with MergeColumns {
  /// Record this value belongs to.
  TextColumn get recordId => text()();

  /// Template field key this value fills.
  TextColumn get fieldKey => text()();

  /// Original captured value. Written once at insert, never updated.
  TextColumn get valueRaw => text().nullable()();

  /// Refined value written beside the original, never over it.
  TextColumn get valueRefined => text().nullable()();

  /// Approved value used for export and search.
  TextColumn get valueFinal => text().nullable()();

  /// Confidence of a proposed refinement, when one exists.
  RealColumn get confidence => real().nullable()();

  /// Shared confidence band at the time this proposal was written.
  TextColumn get confidenceBand => text().nullable()();

  /// Where this value came from (typed, lookup, extraction).
  TextColumn get source => text()();

  /// Extraction method, such as local OCR or provider extraction.
  TextColumn get method => text().nullable()();

  /// Provider id when an online service proposed the value.
  TextColumn get provider => text().nullable()();

  /// Provider model when one was involved.
  TextColumn get model => text().nullable()();

  /// Prompt or local-rule version that produced the proposal.
  TextColumn get promptVersion => text().nullable()();

  /// Whether an operator has verified the final value.
  BoolColumn get verified => boolean().withDefault(const Constant(false))();

  /// Operator who verified it.
  TextColumn get verifiedBy => text().nullable()();

  /// When it was verified.
  DateTimeColumn get verifiedAt => dateTime().nullable()();

  /// When every photo this value was read from stopped being live.
  ///
  /// Null while at least one photo evidence row is live, or when the value
  /// never had photo evidence. The value itself is never deleted.
  DateTimeColumn get evidenceRemovedAt => dateTime().nullable()();

  /// When a template change left this value without a field to fill.
  ///
  /// Null while the record's template declares [fieldKey]. A retired value
  /// is kept, never deleted, and comes back if the key maps again.
  DateTimeColumn get retiredAt => dateTime().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{recordId, fieldKey},
  ];
}

/// Inserts a field row. A later write that includes the raw column is refused.
Future<Result<RecordField>> insertRecordField(
  GeneratedDatabase db, {
  required Insertable<RecordField> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
  String? operator,
  String? auditReason,
}) {
  return _writeRecordField(
    db,
    row: row,
    clock: clock,
    deviceId: deviceId,
    ids: ids,
    operator: operator,
    auditReason: auditReason,
    allowRaw: true,
  );
}

/// Writes a refined value beside the original raw column.
Future<Result<RecordField>> writeRecordFieldRefined(
  GeneratedDatabase db, {
  required String id,
  required String valueRefined,
  double? confidence,
  required Clock clock,
  required String deviceId,
  required IdService ids,
  String? operator,
}) {
  return _writeRecordField(
    db,
    row: RecordFieldsCompanion(
      id: Value<String>(id),
      valueRefined: Value<String>(valueRefined),
      confidence: confidence == null
          ? const Value<double?>.absent()
          : Value<double?>(confidence),
    ),
    clock: clock,
    deviceId: deviceId,
    ids: ids,
    operator: operator,
    allowRaw: false,
  );
}

/// Writes the approved final value. The raw column stays as captured.
Future<Result<RecordField>> writeRecordFieldFinal(
  GeneratedDatabase db, {
  required String id,
  required String valueFinal,
  required Clock clock,
  required String deviceId,
  required IdService ids,
  String? verifiedBy,
  String? operator,
}) {
  final DateTime now = clock.nowUtc();
  return _writeRecordField(
    db,
    row: RecordFieldsCompanion(
      id: Value<String>(id),
      valueFinal: Value<String>(valueFinal),
      verified: const Value<bool>(true),
      verifiedBy: Value<String?>(verifiedBy),
      verifiedAt: Value<DateTime>(now),
    ),
    clock: clock,
    deviceId: deviceId,
    ids: ids,
    operator: operator,
    allowRaw: false,
  );
}

/// Writes an operator's correction of value [id] as its refined value,
/// inside the caller's transaction, and returns whether anything changed.
///
/// The correction supersedes an approved value: `value_final` is cleared so
/// the field displays [value]; the raw value stays as captured. The value
/// becomes [source] and verified by [operator] at the clock's time. One
/// audit row is appended (entity `records`, action updated, the value's own
/// field key, [reason]) whose previous value is what the field displayed
/// before the edit (final, else refined, else raw, the first that is not
/// empty; null when nothing showed) and whose new value is [value]. The
/// history therefore reads what the operator saw, not the column written.
///
/// A value that already displays [value] is left alone and false returned.
/// A value removed earlier (tombstoned, as a merge can leave one) displayed
/// nothing: its tombstone is lifted and the correction written with no
/// previous value. Bumps `rev`, `updated_at` and `updated_by_device`; never
/// touches the value flags. Throws a [StorageFailure] when the value is not
/// on this device, so the caller's transaction rolls back.
Future<bool> writeRecordFieldEdit(
  GeneratedDatabase db, {
  required String id,
  required String value,
  String source = recordFieldEditSource,
  Clock? clock,
  String? deviceId,
  String? operator,
  String? reason,
}) {
  final AppDatabase database = db as AppDatabase;
  final DateTime now = (clock ?? const SystemClock()).nowUtc();
  final String device = deviceId ?? '';
  return database.transaction(() async {
    final QueryRow? row = await database
        .customSelect(
          'SELECT f.record_id AS record_id, f.field_key AS field_key, '
          'f.value_raw AS raw, f.value_refined AS refined, '
          'f.value_final AS approved, EXISTS (SELECT 1 FROM tombstones t '
          "WHERE t.entity_type = 'record_fields' AND t.entity_id = f.id) "
          'AS gone FROM record_fields f WHERE f.id = ?',
          variables: <Variable<Object>>[Variable<String>(id)],
        )
        .getSingleOrNull();
    if (row == null) {
      throw const StorageFailure(
        message: 'That value is no longer on this device.',
        recoveryAction: 'Refresh the record and try again.',
      );
    }
    final bool gone = row.read<int>('gone') != 0;
    final String shown = gone
        ? ''
        : _shownValue(
            approved: row.read<String?>('approved'),
            refined: row.read<String?>('refined'),
            raw: row.read<String?>('raw'),
          );
    if (shown == value) {
      return false;
    }
    if (gone) {
      await removeTombstone(
        database,
        entityType: database.recordFields.actualTableName,
        entityId: id,
      );
    }
    await database.customUpdate(
      'UPDATE record_fields SET value_refined = ?, value_final = NULL, '
      'source = ?, verified = 1, verified_by = ?, verified_at = ?, '
      'updated_at = ?, updated_by_device = ?, rev = rev + 1 WHERE id = ?',
      variables: <Variable<Object>>[
        Variable<String>(value),
        Variable<String>(source),
        Variable<String>(operator),
        Variable<DateTime>(now),
        Variable<DateTime>(now),
        Variable<String>(device),
        Variable<String>(id),
      ],
      updates: <TableInfo<dynamic, dynamic>>{database.recordFields},
      updateKind: UpdateKind.update,
    );
    await appendAudit(
      database,
      entityType: 'records',
      entityId: row.read<String>('record_id'),
      action: AuditAction.updated,
      fieldKey: row.read<String>('field_key'),
      previousValue: shown.isEmpty ? null : shown,
      newValue: value,
      reason: reason,
      clock: clock,
      device: device,
      operator: operator,
    );
    return true;
  });
}

/// The source [writeRecordFieldEdit] stamps on an operator's correction.
/// Processing treats it as hand-entered and never overwrites it.
const String recordFieldEditSource = 'manual';

/// What a value displays: [approved], else [refined], else [raw], taking the
/// first that is not empty; empty when none holds text.
String _shownValue({String? approved, String? refined, String? raw}) {
  for (final String? stage in <String?>[approved, refined, raw]) {
    if (stage != null && stage.isNotEmpty) {
      return stage;
    }
  }
  return '';
}

Future<Result<RecordField>> _writeRecordField(
  GeneratedDatabase db, {
  required Insertable<RecordField> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
  String? operator,
  String? auditReason,
  required bool allowRaw,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final _RecordFieldsDao dao = _RecordFieldsDao(
      database,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    );
    final Map<String, Expression<Object>> columns =
        Map<String, Expression<Object>>.of(row.toColumns(false));
    final String? id = _idOf(row);
    final RecordField? existing = id == null
        ? null
        : (await dao.getById(id)).fold(
            (Failure failure) => throw failure,
            (RecordField? value) => value,
          );
    if (existing != null && columns.containsKey('value_raw')) {
      throw const StorageFailure(
        message: 'The original value cannot be changed.',
        recoveryAction: 'Leave the captured value and write a refined one.',
      );
    }
    if (!allowRaw) {
      columns.remove('value_raw');
    }
    return await database.transaction(() async {
      final Result<RecordField> written = await dao.upsert(
        RawValuesInsertable<RecordField>(columns),
      );
      switch (written) {
        case FailureResult<RecordField>():
          return written;
        case Success<RecordField>(:final RecordField value):
          await appendAudit(
            database,
            entityType: 'records',
            entityId: value.recordId,
            action: existing == null
                ? AuditAction.created
                : AuditAction.updated,
            fieldKey: value.fieldKey,
            previousValue: _auditPrevious(existing, columns),
            newValue: _auditNew(value, columns),
            clock: clock,
            device: deviceId,
            operator: operator,
            reason: auditReason,
          );
          return written;
      }
    });
  } on Failure catch (failure) {
    return FailureResult<RecordField>(failure);
  } on Object catch (error) {
    return FailureResult<RecordField>(storageFailureFrom(error));
  }
}

String? _idOf(Insertable<RecordField> row) {
  final Expression<Object>? expression = row.toColumns(false)['id'];
  if (expression is Variable<String>) {
    return expression.value;
  }
  return null;
}

String? _auditPrevious(
  RecordField? existing,
  Map<String, Expression<Object>> columns,
) {
  if (existing == null) {
    return null;
  }
  if (columns.containsKey('value_final')) {
    return existing.valueFinal;
  }
  if (columns.containsKey('value_refined')) {
    return existing.valueRefined;
  }
  return existing.valueRaw;
}

String? _auditNew(RecordField value, Map<String, Expression<Object>> columns) {
  if (columns.containsKey('value_final')) {
    return value.valueFinal;
  }
  if (columns.containsKey('value_refined')) {
    return value.valueRefined;
  }
  return value.valueRaw;
}

/// Audit `reason` of a row that sets or clears
/// [RecordFields.evidenceRemovedAt].
///
/// Value-flag audit rows sit on entity `records` with the record id, action
/// updated, the value's own field key, and previous and new values `'false'`
/// and `'true'` for the flag before and after. The reason names the flag, so
/// the history tells a flag change from a value edit on the same key.
const String evidenceRemovedAuditReason = 'evidenceRemoved';

/// Audit `reason` of a row that sets or clears [RecordFields.retiredAt].
/// Same shape as [evidenceRemovedAuditReason].
const String retiredAuditReason = 'retired';

/// Flags value [id] as having lost its photo evidence, inside the caller's
/// transaction, with its own audit row ([evidenceRemovedAuditReason]).
///
/// Returns false, writing nothing, when the flag is already set. Bumps
/// `rev` and `updated_at`; the value columns are never touched. Throws a
/// [StorageFailure] when the value is not on this device.
Future<bool> setRecordFieldEvidenceRemoved(
  GeneratedDatabase db, {
  required String id,
  Clock? clock,
  String? deviceId,
  String? operator,
}) {
  return _writeFlag(
    db,
    id: id,
    flag: _Flag.evidenceRemoved,
    set: true,
    clock: clock,
    deviceId: deviceId,
    operator: operator,
  );
}

/// Clears the evidence-removed flag of value [id], inside the caller's
/// transaction, with its own audit row. Returns false when it was not set.
Future<bool> clearRecordFieldEvidenceRemoved(
  GeneratedDatabase db, {
  required String id,
  Clock? clock,
  String? deviceId,
  String? operator,
}) {
  return _writeFlag(
    db,
    id: id,
    flag: _Flag.evidenceRemoved,
    set: false,
    clock: clock,
    deviceId: deviceId,
    operator: operator,
  );
}

/// Marks value [id] retired (its template no longer declares the key),
/// inside the caller's transaction, with its own audit row
/// ([retiredAuditReason]). The value is kept. Returns false when already
/// retired. Throws a [StorageFailure] when the value is not on this device.
Future<bool> setRecordFieldRetired(
  GeneratedDatabase db, {
  required String id,
  Clock? clock,
  String? deviceId,
  String? operator,
}) {
  return _writeFlag(
    db,
    id: id,
    flag: _Flag.retired,
    set: true,
    clock: clock,
    deviceId: deviceId,
    operator: operator,
  );
}

/// Brings retired value [id] back (its key maps again), inside the caller's
/// transaction, with its own audit row. Returns false when it was not
/// retired.
Future<bool> clearRecordFieldRetired(
  GeneratedDatabase db, {
  required String id,
  Clock? clock,
  String? deviceId,
  String? operator,
}) {
  return _writeFlag(
    db,
    id: id,
    flag: _Flag.retired,
    set: false,
    clock: clock,
    deviceId: deviceId,
    operator: operator,
  );
}

/// Flags every value of photo [photoId]'s record whose photo evidence is no
/// longer live, and returns their field keys in key order.
///
/// Call it after the photo's tombstone is written, in the same transaction.
/// A value is flagged only when it has at least one photo evidence row and
/// every such row points at a photo whose whole derivation family (the
/// photo, the photos it was derived from and the photos derived from it)
/// has no untombstoned member filed on this record. Typed, manual, context
/// and default values are never flagged, values are never deleted, and each
/// flag writes its own audit row. An unfiled or unknown photo flags nothing.
Future<List<String>> flagEvidenceRemovedForPhoto(
  GeneratedDatabase db, {
  required String photoId,
  Clock? clock,
  String? deviceId,
  String? operator,
}) {
  return _syncEvidenceFlags(
    db,
    photoId: photoId,
    set: true,
    clock: clock,
    deviceId: deviceId,
    operator: operator,
  );
}

/// The inverse of [flagEvidenceRemovedForPhoto] for a restored photo: clears
/// the flag on every value of the photo's record that has live photo
/// evidence again, and returns their field keys in key order.
///
/// Call it after the photo's tombstone is lifted, in the same transaction.
Future<List<String>> clearEvidenceRemovedForPhoto(
  GeneratedDatabase db, {
  required String photoId,
  Clock? clock,
  String? deviceId,
  String? operator,
}) {
  return _syncEvidenceFlags(
    db,
    photoId: photoId,
    set: false,
    clock: clock,
    deviceId: deviceId,
    operator: operator,
  );
}

/// The two value flags a helper above can write.
enum _Flag {
  evidenceRemoved('evidence_removed_at', evidenceRemovedAuditReason),
  retired('retired_at', retiredAuditReason);

  const _Flag(this.column, this.reason);

  final String column;
  final String reason;
}

/// Sources whose values were not read from a photo, so never flagged.
const Set<String> _unflaggedSources = <String>{
  'typed',
  'manual',
  'context',
  'default',
};

Future<bool> _writeFlag(
  GeneratedDatabase db, {
  required String id,
  required _Flag flag,
  required bool set,
  Clock? clock,
  String? deviceId,
  String? operator,
}) {
  final AppDatabase database = db as AppDatabase;
  final DateTime now = (clock ?? const SystemClock()).nowUtc();
  final String device = deviceId ?? '';
  return database.transaction(() async {
    final QueryRow? row = await database
        .customSelect(
          'SELECT record_id, field_key, ${flag.column} AS flagged '
          'FROM record_fields WHERE id = ?',
          variables: <Variable<Object>>[Variable<String>(id)],
        )
        .getSingleOrNull();
    if (row == null) {
      throw const StorageFailure(
        message: 'That value is no longer on this device.',
        recoveryAction: 'Refresh the record and try again.',
      );
    }
    final bool was = row.data['flagged'] != null;
    if (was == set) {
      return false;
    }
    await database.customUpdate(
      'UPDATE record_fields SET ${flag.column} = ?, updated_at = ?, '
      'updated_by_device = ?, rev = rev + 1 WHERE id = ?',
      variables: <Variable<Object>>[
        Variable<DateTime>(set ? now : null),
        Variable<DateTime>(now),
        Variable<String>(device),
        Variable<String>(id),
      ],
      updates: <TableInfo<dynamic, dynamic>>{database.recordFields},
      updateKind: UpdateKind.update,
    );
    await appendAudit(
      database,
      entityType: 'records',
      entityId: row.read<String>('record_id'),
      action: AuditAction.updated,
      fieldKey: row.read<String>('field_key'),
      previousValue: '$was',
      newValue: '$set',
      reason: flag.reason,
      clock: clock,
      device: device,
      operator: operator,
    );
    return true;
  });
}

Future<List<String>> _syncEvidenceFlags(
  GeneratedDatabase db, {
  required String photoId,
  required bool set,
  Clock? clock,
  String? deviceId,
  String? operator,
}) {
  final AppDatabase database = db as AppDatabase;
  return database.transaction(() async {
    final QueryRow? photo = await database
        .customSelect(
          'SELECT record_id FROM photos WHERE id = ?',
          variables: <Variable<Object>>[Variable<String>(photoId)],
        )
        .getSingleOrNull();
    final String? recordId = photo?.read<String?>('record_id');
    if (recordId == null) {
      return const <String>[];
    }
    final List<String> changed = <String>[];
    for (final _EvidenceState value in await _evidenceStates(
      database,
      recordId,
    )) {
      final bool due = set
          ? !value.flagged && value.flaggable && !value.live
          : value.flagged && value.live;
      if (!due) {
        continue;
      }
      final bool written = await _writeFlag(
        database,
        id: value.id,
        flag: _Flag.evidenceRemoved,
        set: set,
        clock: clock,
        deviceId: deviceId,
        operator: operator,
      );
      if (written) {
        changed.add(value.fieldKey);
      }
    }
    return changed;
  });
}

/// One value with photo evidence: whether it is flagged, whether it may be
/// flagged at all, and whether any of its photo evidence is still live.
typedef _EvidenceState = ({
  String id,
  String fieldKey,
  bool flagged,
  bool flaggable,
  bool live,
});

/// Live values of [recordId] that have at least one photo evidence row.
Future<List<_EvidenceState>> _evidenceStates(
  AppDatabase db,
  String recordId,
) async {
  final List<Variable<Object>> record = <Variable<Object>>[
    Variable<String>(recordId),
  ];
  final List<QueryRow> fields = await db
      .customSelect(
        'SELECT f.id AS id, f.field_key AS field_key, f.source AS source, '
        'f.evidence_removed_at AS flagged FROM record_fields f '
        'WHERE f.record_id = ? AND NOT EXISTS (SELECT 1 FROM tombstones t '
        "WHERE t.entity_type = 'record_fields' AND t.entity_id = f.id) "
        'ORDER BY f.field_key, f.id',
        variables: record,
      )
      .get();
  final List<QueryRow> evidence = await db
      .customSelect(
        'SELECT e.record_field_id AS field_id, e.photo_id AS photo_id '
        'FROM field_evidence e JOIN record_fields f '
        'ON f.id = e.record_field_id WHERE f.record_id = ? '
        'AND e.photo_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM '
        "tombstones t WHERE t.entity_type = 'field_evidence' "
        'AND t.entity_id = e.id)',
        variables: record,
      )
      .get();
  final List<QueryRow> photos = await db
      .customSelect(
        'SELECT p.id AS id, p.derived_from AS derived_from, '
        'p.record_id AS record_id, EXISTS (SELECT 1 FROM tombstones t '
        "WHERE t.entity_type = 'photos' AND t.entity_id = p.id) AS gone "
        'FROM photos p WHERE p.record_id = ?1 OR p.id IN (SELECT e.photo_id '
        'FROM field_evidence e JOIN record_fields f '
        'ON f.id = e.record_field_id WHERE f.record_id = ?1)',
        variables: record,
      )
      .get();
  final Map<String, Set<String>> byField = <String, Set<String>>{};
  for (final QueryRow row in evidence) {
    byField
        .putIfAbsent(row.read<String>('field_id'), () => <String>{})
        .add(row.read<String>('photo_id'));
  }
  final _PhotoFamilies families = _PhotoFamilies(recordId, photos);
  return <_EvidenceState>[
    for (final QueryRow field in fields)
      if (byField[field.read<String>('id')] case final Set<String> photoIds)
        (
          id: field.read<String>('id'),
          fieldKey: field.read<String>('field_key'),
          flagged: field.data['flagged'] != null,
          flaggable: !_unflaggedSources.contains(
            field.read<String>('source').toLowerCase(),
          ),
          live: photoIds.any(families.isLive),
        ),
  ];
}

/// Photos linked by `derived_from`, read for one record.
final class _PhotoFamilies {
  _PhotoFamilies(this._recordId, List<QueryRow> rows) {
    for (final QueryRow row in rows) {
      final String id = row.read<String>('id');
      _usable[id] =
          row.read<int>('gone') == 0 &&
          row.read<String?>('record_id') == _recordId;
      final String? parent = row.read<String?>('derived_from');
      if (parent != null) {
        _links.putIfAbsent(id, () => <String>{}).add(parent);
        _links.putIfAbsent(parent, () => <String>{}).add(id);
      }
    }
  }

  final String _recordId;
  final Map<String, bool> _usable = <String, bool>{};
  final Map<String, Set<String>> _links = <String, Set<String>>{};

  /// Whether [photoId] or any photo in its family is untombstoned and filed
  /// on this record.
  bool isLive(String photoId) {
    final Set<String> seen = <String>{photoId};
    final List<String> queue = <String>[photoId];
    while (queue.isNotEmpty) {
      final String id = queue.removeLast();
      if (_usable[id] ?? false) {
        return true;
      }
      for (final String next in _links[id] ?? const <String>{}) {
        if (seen.add(next)) {
          queue.add(next);
        }
      }
    }
    return false;
  }
}

/// Marks a field deleted without removing the row, so evidence can still
/// point at it.
Future<Result<void>> softDeleteRecordField(
  GeneratedDatabase db, {
  required String id,
  required String reason,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) {
  return _RecordFieldsDao(
    db as AppDatabase,
    clock: clock,
    deviceId: deviceId,
    ids: ids,
  ).softDelete(id, reason: reason);
}

final class _RecordFieldsDao extends BaseDao<RecordFields, RecordField> {
  _RecordFieldsDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.recordFields);
}

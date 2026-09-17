import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

/// Caption text owned by a record or a photo.
///
/// Applying one caption to several photos writes one row per photo. [textRaw]
/// is written once at insert; refinement writes [textRefined] beside it.
@TableIndex(name: 'captions_by_owner', columns: {#ownerType, #ownerId})
class Captions extends Table with MergeColumns {
  /// Record or photo.
  TextColumn get ownerType => textEnum<CaptionOwnerType>()();

  /// Merge id of the record or photo this caption describes.
  TextColumn get ownerId => text()();

  /// Original caption as entered. Written once at insert, never updated.
  TextColumn get textRaw => text()();

  /// Refined caption written beside the original, never over it.
  TextColumn get textRefined => text().nullable()();

  /// Typed or spoken.
  TextColumn get inputMode => textEnum<CaptionInputMode>()();

  /// When a refined value was written, if one has been.
  DateTimeColumn get refinedAt => dateTime().nullable()();
}

/// Who a [Caption] describes.
enum CaptionOwnerType {
  /// A record's main description.
  record,

  /// One photo's caption.
  photo,
}

/// How the raw caption was entered.
enum CaptionInputMode {
  /// Typed on the device.
  typed,

  /// Spoken and stored as entered.
  spoken,
}

/// Inserts a caption row. A later write that includes the raw column is
/// refused.
Future<Result<Caption>> insertCaption(
  GeneratedDatabase db, {
  required Insertable<Caption> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
  String? operator,
}) async {
  try {
    final Caption written = await _writeCaption(
      db,
      row: row,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
      operator: operator,
      allowRaw: true,
    );
    return Success<Caption>(written);
  } on Failure catch (failure) {
    return FailureResult<Caption>(failure);
  } on Object catch (error) {
    return FailureResult<Caption>(storageFailureFrom(error));
  }
}

/// Writes a refined caption beside the original raw column.
Future<Result<Caption>> writeCaptionRefined(
  GeneratedDatabase db, {
  required String id,
  required String textRefined,
  required Clock clock,
  required String deviceId,
  required IdService ids,
  String? operator,
}) async {
  try {
    final Caption written = await _writeCaption(
      db,
      row: CaptionsCompanion(
        id: Value<String>(id),
        textRefined: Value<String>(textRefined),
        refinedAt: Value<DateTime>(clock.nowUtc()),
      ),
      clock: clock,
      deviceId: deviceId,
      ids: ids,
      operator: operator,
      allowRaw: false,
    );
    return Success<Caption>(written);
  } on Failure catch (failure) {
    return FailureResult<Caption>(failure);
  } on Object catch (error) {
    return FailureResult<Caption>(storageFailureFrom(error));
  }
}

/// Writes one independent caption row per photo, in a single transaction.
///
/// There is no shared row: each photo keeps its own caption afterwards.
Future<Result<List<Caption>>> applyCaptionToPhotos(
  GeneratedDatabase db, {
  required List<String> photoIds,
  required String text,
  required CaptionInputMode inputMode,
  required Clock clock,
  required String deviceId,
  required IdService ids,
  String? operator,
}) {
  final AppDatabase database = db as AppDatabase;
  return runInTransaction(database, () async {
    final List<Caption> written = <Caption>[];
    for (final String photoId in photoIds) {
      final CaptionsCompanion companion = CaptionsCompanion(
        ownerType: const Value<CaptionOwnerType>(CaptionOwnerType.photo),
        ownerId: Value<String>(photoId),
        inputMode: Value<CaptionInputMode>(inputMode),
      );
      final Map<String, Expression<Object>> columns =
          Map<String, Expression<Object>>.of(companion.toColumns(false));
      columns['text_raw'] = Variable<String>(text);
      written.add(
        await _writeCaption(
          database,
          row: RawValuesInsertable<Caption>(columns),
          clock: clock,
          deviceId: deviceId,
          ids: ids,
          operator: operator,
          allowRaw: true,
        ),
      );
    }
    return written;
  });
}

Future<Caption> _writeCaption(
  GeneratedDatabase db, {
  required Insertable<Caption> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
  String? operator,
  required bool allowRaw,
}) async {
  final AppDatabase database = db as AppDatabase;
  final Result<Caption> written = await runInTransaction(database, () async {
    final _CaptionsDao dao = _CaptionsDao(
      database,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    );
    final Map<String, Expression<Object>> columns =
        Map<String, Expression<Object>>.of(row.toColumns(false));
    final String? id = _idOf(row);
    final Caption? existing = id == null
        ? null
        : (await dao.getById(id)).fold(
            (Failure failure) => throw failure,
            (Caption? value) => value,
          );
    if (existing != null && columns.containsKey('text_raw')) {
      throw const StorageFailure(
        message: 'The original caption cannot be changed.',
        recoveryAction: 'Leave the captured text and write a refined one.',
      );
    }
    if (!allowRaw) {
      columns.remove('text_raw');
    }
    final Result<Caption> upserted = await dao.upsert(
      RawValuesInsertable<Caption>(columns),
    );
    switch (upserted) {
      case FailureResult<Caption>(:final Failure failure):
        throw failure;
      case Success<Caption>(:final Caption value):
        await appendAudit(
          database,
          entityType: 'captions',
          entityId: value.ownerId,
          action: existing == null ? AuditAction.created : AuditAction.updated,
          fieldKey: 'caption',
          previousValue: existing == null
              ? null
              : (columns.containsKey('text_refined')
                    ? existing.textRefined
                    : existing.textRaw),
          newValue: columns.containsKey('text_refined')
              ? value.textRefined
              : value.textRaw,
          clock: clock,
          device: deviceId,
          operator: operator,
        );
        return value;
    }
  });
  return switch (written) {
    Success<Caption>(:final Caption value) => value,
    FailureResult<Caption>(:final Failure failure) => throw failure,
  };
}

String? _idOf(Insertable<Caption> row) {
  final Expression<Object>? expression = row.toColumns(false)['id'];
  if (expression is Variable<String>) {
    return expression.value;
  }
  return null;
}

final class _CaptionsDao extends BaseDao<Captions, Caption> {
  _CaptionsDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.captions);
}

part of 'reference.dart';

/// One row in a [Reference] dataset. Keys are indexed but may repeat after
/// the operator explicitly accepts an ambiguous key column.
///
/// [keyNormalised] is written at insert so lookup never folds at query time.
@TableIndex(name: 'reference_rows_by_key', columns: {#datasetId, #keyValue})
@TableIndex(
  name: 'reference_rows_by_normalised',
  columns: {#datasetId, #keyNormalised},
)
@DataClassName('ReferenceLookupRow')
class ReferenceRows extends Table with MergeColumns {
  /// Dataset this row belongs to.
  TextColumn get datasetId => text()();

  /// Key as imported, stored as data.
  TextColumn get keyValue => text()();

  /// Folded [keyValue] used for indexed lookup.
  TextColumn get keyNormalised => text()();

  /// Cell values JSON. An object, stored as text.
  TextColumn get values => text()();
}

final class _ReferenceRowsDao
    extends BaseDao<ReferenceRows, ReferenceLookupRow> {
  _ReferenceRowsDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.referenceRows);
}

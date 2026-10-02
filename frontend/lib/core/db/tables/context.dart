import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/time/clock.dart';

part 'context_state.dart';
part 'context_presets.dart';

/// One level in a project's context hierarchy.
///
/// [level] is the order from the root: a smaller value is higher, so setting
/// it clears every row whose level is strictly greater.
class Context extends Table with MergeColumns {
  @override
  String get tableName => 'context_definitions';

  /// Project that owns this level.
  TextColumn get projectId => text()();

  /// Hierarchy order. Unique together with [projectId].
  IntColumn get level => integer()();

  /// Template field key this level binds to.
  TextColumn get fieldKey => text()();

  /// Operator-facing name for the level.
  TextColumn get label => text()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{projectId, fieldKey},
  ];
}

/// Pins [value] at [level] and deletes every lower state row in one write.
///
/// State rows are the device's transient current values, never merged; the
/// step 4 rule clears the lower levels outright. Definitions and presets,
/// which merge, are only ever tombstoned ([deleteContextDefinition],
/// [deleteContextPreset]).
Future<void> setContextLevel(
  GeneratedDatabase tx, {
  required String projectId,
  required int level,
  required String value,
  required Clock clock,
  required String deviceId,
  String? fieldKey,
}) async {
  final AppDatabase db = tx as AppDatabase;
  final DateTime now = clock.nowUtc();
  final String device = deviceId;
  final String key = fieldKey ?? 'level-$level';
  await tx.transaction(() async {
    await (tx.delete(db.contextState)..where(
          ($ContextStateTable tbl) =>
              tbl.projectId.equals(projectId) &
              tbl.level.isBiggerThanValue(level),
        ))
        .go();
    final ContextStateRow? existing =
        await (tx.select(db.contextState)..where(
              ($ContextStateTable tbl) =>
                  tbl.projectId.equals(projectId) & tbl.fieldKey.equals(key),
            ))
            .getSingleOrNull();
    if (existing == null) {
      await tx
          .into(db.contextState)
          .insert(
            ContextStateCompanion.insert(
              projectId: projectId,
              level: level,
              fieldKey: Value<String>(key),
              value: value,
              setAt: now,
              createdAt: now,
              updatedAt: now,
              updatedByDevice: device,
            ),
          );
      return;
    }
    await (tx.update(
      db.contextState,
    )..where(($ContextStateTable tbl) => tbl.id.equals(existing.id))).write(
      ContextStateCompanion(
        value: Value<String>(value),
        setAt: Value<DateTime>(now),
        updatedAt: Value<DateTime>(now),
        updatedByDevice: Value<String>(device),
        rev: Value<int>(existing.rev + 1),
      ),
    );
  });
}

/// Inserts a named snapshot of the current context values and returns it.
Future<ContextPreset> upsertContextPreset(
  GeneratedDatabase tx, {
  required String projectId,
  required String name,
  required String values,
  required Clock clock,
  required String deviceId,
}) {
  final AppDatabase db = tx as AppDatabase;
  final DateTime now = clock.nowUtc();
  return tx
      .into(db.contextPresets)
      .insertReturning(
        ContextPresetsCompanion.insert(
          name: name,
          projectId: projectId,
          values: values,
          createdAt: now,
          updatedAt: now,
          updatedByDevice: deviceId,
        ),
      );
}

/// A project's context definitions that are not deleted, from the root
/// level down. `.get()` reads them once and `.watch()` follows them; a delete
/// also changes the watch, because the query reads the tombstones.
SimpleSelectStatement<$ContextTable, ContextData> liveContextDefinitions(
  GeneratedDatabase tx, {
  required String projectId,
}) {
  final AppDatabase db = tx as AppDatabase;
  return db.select(db.context)
    ..where(
      ($ContextTable tbl) =>
          tbl.projectId.equals(projectId) &
          tbl.id.isNotInQuery(_tombstoned(db, db.context.actualTableName)),
    )
    ..orderBy(<OrderClauseGenerator<$ContextTable>>[
      ($ContextTable tbl) => OrderingTerm.asc(tbl.level),
    ]);
}

/// A project's presets that are not deleted, in the order they were saved.
SimpleSelectStatement<$ContextPresetsTable, ContextPreset> liveContextPresets(
  GeneratedDatabase tx, {
  required String projectId,
}) {
  final AppDatabase db = tx as AppDatabase;
  return db.select(db.contextPresets)
    ..where(
      ($ContextPresetsTable tbl) =>
          tbl.projectId.equals(projectId) &
          tbl.id.isNotInQuery(
            _tombstoned(db, db.contextPresets.actualTableName),
          ),
    )
    ..orderBy(<OrderClauseGenerator<$ContextPresetsTable>>[
      ($ContextPresetsTable tbl) => OrderingTerm.asc(tbl.createdAt),
      ($ContextPresetsTable tbl) => OrderingTerm.asc(tbl.id),
    ]);
}

/// Deletes one definition: exactly one tombstone, in the caller's
/// transaction. The row stays for merge; [liveContextDefinitions] skips it
/// (FE-SEC-08, FE-SEC-09).
Future<void> deleteContextDefinition(
  GeneratedDatabase tx, {
  required String id,
  required String reason,
  required Clock clock,
  required String deviceId,
}) {
  final AppDatabase db = tx as AppDatabase;
  return writeTombstone(
    db,
    entityType: db.context.actualTableName,
    entityId: id,
    reason: reason,
    clock: clock,
    deviceId: deviceId,
  );
}

/// Deletes one preset: exactly one tombstone, in the caller's transaction.
/// The row stays for merge; [liveContextPresets] skips it.
Future<void> deleteContextPreset(
  GeneratedDatabase tx, {
  required String id,
  required String reason,
  required Clock clock,
  required String deviceId,
}) {
  final AppDatabase db = tx as AppDatabase;
  return writeTombstone(
    db,
    entityType: db.contextPresets.actualTableName,
    entityId: id,
    reason: reason,
    clock: clock,
    deviceId: deviceId,
  );
}

/// The ids tombstoned for [entityType], as a one-column subquery.
JoinedSelectStatement<$TombstonesTable, Tombstone> _tombstoned(
  AppDatabase db,
  String entityType,
) {
  return db.selectOnly(db.tombstones)
    ..addColumns(<Expression<Object>>[db.tombstones.entityId])
    ..where(db.tombstones.entityType.equals(entityType));
}

/// Clears transient current values (levels, and pins at level 0) before the
/// caller writes a new snapshot. Rows below level 0 hold the pickers' recent
/// values and are kept.
Future<void> clearContextStateForProject(
  GeneratedDatabase tx, {
  required String projectId,
}) async {
  final AppDatabase db = tx as AppDatabase;
  await (tx.delete(db.contextState)..where(
        ($ContextStateTable table) =>
            table.projectId.equals(projectId) &
            table.level.isBiggerOrEqualValue(0),
      ))
      .go();
}

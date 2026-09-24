import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/columns.dart';
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
    <Column<Object>>{projectId, level},
  ];
}

/// Pins [value] at [level] and deletes every lower state row in one write.
Future<void> setContextLevel(
  GeneratedDatabase tx, {
  required String projectId,
  required int level,
  required String value,
  Clock? clock,
  String? deviceId,
}) async {
  final AppDatabase db = tx as AppDatabase;
  final DateTime now = (clock ?? const SystemClock()).nowUtc();
  final String device = deviceId ?? '';
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
                  tbl.projectId.equals(projectId) & tbl.level.equals(level),
            ))
            .getSingleOrNull();
    if (existing == null) {
      await tx
          .into(db.contextState)
          .insert(
            ContextStateCompanion.insert(
              projectId: projectId,
              level: level,
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

/// Inserts a named snapshot of the current context values.
Future<ContextPreset> upsertContextPreset(
  GeneratedDatabase tx, {
  required String projectId,
  required String name,
  required String values,
  Clock? clock,
  String? deviceId,
}) async {
  final AppDatabase db = tx as AppDatabase;
  final DateTime now = (clock ?? const SystemClock()).nowUtc();
  final String device = deviceId ?? '';
  await tx
      .into(db.contextPresets)
      .insert(
        ContextPresetsCompanion.insert(
          name: name,
          projectId: projectId,
          values: values,
          createdAt: now,
          updatedAt: now,
          updatedByDevice: device,
        ),
      );
  return (tx.select(db.contextPresets)..where(
        ($ContextPresetsTable tbl) =>
            tbl.projectId.equals(projectId) & tbl.name.equals(name),
      ))
      .getSingle();
}

/// Removes one definition after its caller has recorded the merge tombstone.
Future<void> deleteContextDefinition(
  GeneratedDatabase tx, {
  required String id,
}) async {
  final AppDatabase db = tx as AppDatabase;
  await (tx.delete(
    db.context,
  )..where(($ContextTable table) => table.id.equals(id))).go();
}

/// Removes one preset after its caller has recorded the merge tombstone.
Future<void> deleteContextPreset(
  GeneratedDatabase tx, {
  required String id,
}) async {
  final AppDatabase db = tx as AppDatabase;
  await (tx.delete(
    db.contextPresets,
  )..where(($ContextPresetsTable table) => table.id.equals(id))).go();
}

/// Clears transient current values before the caller writes a new snapshot.
Future<void> clearContextStateForProject(
  GeneratedDatabase tx, {
  required String projectId,
}) async {
  final AppDatabase db = tx as AppDatabase;
  await (tx.delete(
        db.contextState,
      )..where(($ContextStateTable table) => table.projectId.equals(projectId)))
      .go();
}

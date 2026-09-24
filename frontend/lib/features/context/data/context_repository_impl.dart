import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/context.dart'
    show
        clearContextStateForProject,
        deleteContextDefinition,
        deleteContextPreset,
        upsertContextPreset;
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/context_cascade.dart';
import '../domain/context_repository.dart';
import '../domain/context_state.dart';
import 'context_mapper.dart';
import 'context_persistence.dart';

/// Drift-backed [ContextRepository].
final class ContextRepositoryImpl implements ContextRepository {
  /// Opens against [_db] with stamp sources.
  ContextRepositoryImpl({
    required this._db,
    required this._clock,
    required this._deviceId,
    required this._ids,
    ContextPersistence? persistence,
  }) : _persistence = persistence ?? MemoryContextPersistence();

  final sqlite.AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;
  final ContextPersistence _persistence;
  final Map<String, ContextState> _cache = <String, ContextState>{};

  @override
  Stream<ContextState> watch(String projectId) async* {
    final ContextState? cached = _cache[projectId];
    if (cached != null) {
      yield cached;
    }
    yield* _changes(projectId).asyncMap((_) => _load(projectId));
  }

  @override
  Future<Result<ContextState>> load(String projectId) async {
    try {
      return Success<ContextState>(await _load(projectId));
    } on Failure catch (failure) {
      return FailureResult<ContextState>(failure);
    } on Object catch (error) {
      return FailureResult<ContextState>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<ContextState>> saveHierarchy(
    String projectId,
    List<ContextLevel> levels,
  ) async {
    return runInTransaction(_db, () async {
      final List<sqlite.ContextData> existing =
          await (_db.select(_db.context)..where(
                (sqlite.$ContextTable tbl) => tbl.projectId.equals(projectId),
              ))
              .get();
      for (final sqlite.ContextData row in existing) {
        await writeTombstone(
          _db,
          entityType: _db.context.actualTableName,
          entityId: row.id,
          reason: 'Context hierarchy replaced.',
          clock: _clock,
          deviceId: _deviceId,
        );
        await deleteContextDefinition(_db, id: row.id);
      }
      final List<ContextLevel> ordered = <ContextLevel>[
        for (int i = 0; i < levels.length; i++) levels[i].copyWith(order: i),
      ];
      final DateTime now = _clock.nowUtc();
      for (final ContextLevel level in ordered) {
        await _db
            .into(_db.context)
            .insert(
              sqlite.ContextCompanion.insert(
                id: Value<String>(_ids.newId()),
                projectId: projectId,
                level: level.order + 1,
                fieldKey: level.fieldKey,
                label: ContextMapper.encodeLabel(level),
                createdAt: now,
                updatedAt: now,
                updatedByDevice: _deviceId,
              ),
            );
      }
      // Drop values whose field keys are no longer levels.
      final Set<String> keys = <String>{
        for (final ContextLevel level in ordered) level.fieldKey,
      };
      final ContextState current = await _load(projectId);
      final Map<String, String> nextValues = <String, String>{
        for (final MapEntry<String, String> e in current.values.entries)
          if (keys.contains(e.key)) e.key: e.value,
      };
      await _writeValues(projectId, ordered, nextValues, current.pinned);
      return _load(projectId);
    });
  }

  @override
  Future<Result<ContextState>> setLevelValue({
    required String projectId,
    required String fieldKey,
    required String value,
    bool clearBelow = true,
  }) async {
    return runInTransaction(_db, () async {
      final ContextState current = await _load(projectId);
      final ContextLevel? level = _levelOf(current, fieldKey);
      if (level == null) {
        throw const ValidationFailure(
          message: 'That field is not a context level.',
          recoveryAction: 'Pick a level from the hierarchy and try again.',
        );
      }
      final ContextState next = clearBelow
          ? ContextCascade.apply(
              state: current,
              changedFieldKey: fieldKey,
              newValue: value,
            )
          : current.copyWith(
              values: <String, String>{...current.values, fieldKey: value},
            );
      await _writeValues(projectId, next.levels, next.values, next.pinned);
      await _persistence.rememberRecent(
        projectId: projectId,
        fieldKey: fieldKey,
        value: value,
      );
      return _load(projectId);
    });
  }

  @override
  Future<Result<ContextState>> savePinned(
    String projectId,
    Map<String, String> pinned,
  ) async {
    return runInTransaction(_db, () async {
      final ContextState current = await _load(projectId);
      await _writeValues(projectId, current.levels, current.values, pinned);
      return _load(projectId);
    });
  }

  @override
  Future<Result<ContextState>> applyPreset(
    String projectId,
    ContextPreset preset,
  ) async {
    return runInTransaction(_db, () async {
      final ContextState current = await _load(projectId);
      final Map<String, String> nextValues = <String, String>{};
      for (final ContextLevel level in current.levels) {
        final String? value = preset.values[level.fieldKey];
        if (value != null) {
          nextValues[level.fieldKey] = value;
        }
      }
      await _writeValues(projectId, current.levels, nextValues, preset.pinned);
      await (_db.update(_db.contextPresets)..where(
            (sqlite.$ContextPresetsTable tbl) => tbl.id.equals(preset.id),
          ))
          .write(
            sqlite.ContextPresetsCompanion(
              updatedAt: Value<DateTime>(_clock.nowUtc()),
              updatedByDevice: Value<String>(_deviceId),
            ),
          );
      return _load(projectId);
    });
  }

  @override
  Stream<List<ContextPreset>> watchPresets(String projectId) {
    return _presetChanges(projectId).asyncMap((_) => _listPresets(projectId));
  }

  @override
  Future<Result<ContextPreset>> savePreset({
    required String projectId,
    required String name,
    required Map<String, String> values,
    required Map<String, String> pinned,
    bool overwrite = false,
  }) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const FailureResult<ContextPreset>(
        ValidationFailure(
          message: 'A preset needs a name.',
          recoveryAction: 'Enter a name and try again.',
        ),
      );
    }
    try {
      final sqlite.ContextPreset? existing =
          await (_db.select(_db.contextPresets)..where(
                (sqlite.$ContextPresetsTable tbl) =>
                    tbl.projectId.equals(projectId) & tbl.name.equals(trimmed),
              ))
              .getSingleOrNull();
      if (existing != null && !overwrite) {
        return const FailureResult<ContextPreset>(
          ValidationFailure(
            message: 'A preset with that name already exists.',
            recoveryAction: 'Choose another name, or confirm overwrite.',
          ),
        );
      }
      final String payload = ContextMapper.encodePresetPayload(
        values: values,
        pinned: pinned,
      );
      if (existing != null) {
        await (_db.update(_db.contextPresets)..where(
              (sqlite.$ContextPresetsTable tbl) => tbl.id.equals(existing.id),
            ))
            .write(
              sqlite.ContextPresetsCompanion(
                values: Value<String>(payload),
                updatedAt: Value<DateTime>(_clock.nowUtc()),
                updatedByDevice: Value<String>(_deviceId),
                rev: Value<int>(existing.rev + 1),
              ),
            );
        final sqlite.ContextPreset row =
            await (_db.select(_db.contextPresets)..where(
                  (sqlite.$ContextPresetsTable tbl) =>
                      tbl.id.equals(existing.id),
                ))
                .getSingle();
        return Success<ContextPreset>(ContextMapper.presetFromRow(row));
      }
      final sqlite.ContextPreset written = await upsertContextPreset(
        _db,
        projectId: projectId,
        name: trimmed,
        values: payload,
        clock: _clock,
        deviceId: _deviceId,
      );
      return Success<ContextPreset>(ContextMapper.presetFromRow(written));
    } on Failure catch (failure) {
      return FailureResult<ContextPreset>(failure);
    } on Object catch (error) {
      return FailureResult<ContextPreset>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<void>> deletePreset(String id, {required String reason}) async {
    if (id.isEmpty || reason.trim().isEmpty) {
      return const FailureResult<void>(
        StorageFailure(
          message: 'A delete needs an id and a reason.',
          recoveryAction: 'Try again.',
        ),
      );
    }
    return runInTransaction(_db, () async {
      await writeTombstone(
        _db,
        entityType: _db.contextPresets.actualTableName,
        entityId: id,
        reason: reason,
        clock: _clock,
        deviceId: _deviceId,
      );
      await deleteContextPreset(_db, id: id);
    });
  }

  @override
  Future<Result<List<String>>> recentValues({
    required String projectId,
    required String fieldKey,
  }) async {
    return Success<List<String>>(
      await _persistence.recents(projectId: projectId, fieldKey: fieldKey),
    );
  }

  Future<ContextState> _load(String projectId) async {
    final List<sqlite.ContextData> definitions =
        await (_db.select(_db.context)
              ..where(
                (sqlite.$ContextTable tbl) => tbl.projectId.equals(projectId),
              )
              ..orderBy(<OrderClauseGenerator<sqlite.$ContextTable>>[
                (sqlite.$ContextTable tbl) =>
                    OrderingTerm(expression: tbl.level),
              ]))
            .get();
    final List<sqlite.ContextStateRow> states =
        await (_db.select(_db.contextState)..where(
              (sqlite.$ContextStateTable tbl) =>
                  tbl.projectId.equals(projectId),
            ))
            .get();
    final ContextState state = ContextMapper.fromRows(
      definitions: definitions,
      states: states,
      pinned: ContextMapper.pinsFromStateRows(states),
    );
    _cache[projectId] = state;
    return state;
  }

  Future<void> _writeValues(
    String projectId,
    List<ContextLevel> levels,
    Map<String, String> values,
    Map<String, String> pinned,
  ) async {
    await clearContextStateForProject(_db, projectId: projectId);
    final DateTime now = _clock.nowUtc();
    if (pinned.isNotEmpty) {
      await _db
          .into(_db.contextState)
          .insert(
            sqlite.ContextStateCompanion.insert(
              projectId: projectId,
              level: 0,
              value: jsonEncode(pinned),
              setAt: now,
              createdAt: now,
              updatedAt: now,
              updatedByDevice: _deviceId,
            ),
          );
    }
    for (final ContextLevel level in levels) {
      final String? value = values[level.fieldKey];
      if (value == null || value.isEmpty) {
        continue;
      }
      await _db
          .into(_db.contextState)
          .insert(
            sqlite.ContextStateCompanion.insert(
              projectId: projectId,
              level: level.order + 1,
              value: value,
              setAt: now,
              createdAt: now,
              updatedAt: now,
              updatedByDevice: _deviceId,
            ),
          );
    }
  }

  ContextLevel? _levelOf(ContextState state, String fieldKey) {
    for (final ContextLevel level in state.levels) {
      if (level.fieldKey == fieldKey) {
        return level;
      }
    }
    return null;
  }

  Future<List<ContextPreset>> _listPresets(String projectId) async {
    final List<sqlite.ContextPreset> rows =
        await (_db.select(_db.contextPresets)..where(
              (sqlite.$ContextPresetsTable tbl) =>
                  tbl.projectId.equals(projectId),
            ))
            .get();
    final List<ContextPreset> list = <ContextPreset>[
      for (final sqlite.ContextPreset row in rows)
        ContextMapper.presetFromRow(row),
    ];
    list.sort((ContextPreset a, ContextPreset b) {
      final DateTime? aAt = a.lastUsedAt;
      final DateTime? bAt = b.lastUsedAt;
      if (aAt == null && bAt == null) {
        return a.name.compareTo(b.name);
      }
      if (aAt == null) {
        return 1;
      }
      if (bAt == null) {
        return -1;
      }
      return bAt.compareTo(aAt);
    });
    return list;
  }

  Stream<void> _changes(String projectId) {
    return Stream<void>.multi((MultiStreamController<void> listener) {
      listener.add(null);
      final List<StreamSubscription<Object?>> subs =
          <StreamSubscription<Object?>>[
            (_db.select(_db.context)..where(
                  (sqlite.$ContextTable tbl) => tbl.projectId.equals(projectId),
                ))
                .watch()
                .listen((_) => listener.add(null)),
            (_db.select(_db.contextState)..where(
                  (sqlite.$ContextStateTable tbl) =>
                      tbl.projectId.equals(projectId),
                ))
                .watch()
                .listen((_) => listener.add(null)),
          ];
      listener.onCancel = () async {
        for (final StreamSubscription<Object?> sub in subs) {
          await sub.cancel();
        }
      };
    });
  }

  Stream<void> _presetChanges(String projectId) {
    return Stream<void>.multi((MultiStreamController<void> listener) {
      listener.add(null);
      final StreamSubscription<Object?> sub =
          (_db.select(_db.contextPresets)..where(
                (sqlite.$ContextPresetsTable tbl) =>
                    tbl.projectId.equals(projectId),
              ))
              .watch()
              .listen((_) => listener.add(null));
      listener.onCancel = sub.cancel;
    });
  }
}

/// Default stub — [main] overrides with [ContextRepositoryImpl].
final Provider<ContextRepository> contextRepositoryProvider =
    Provider<ContextRepository>((Ref _) {
      return _EmptyContextRepository();
    });

final class _EmptyContextRepository implements ContextRepository {
  @override
  Stream<ContextState> watch(String projectId) =>
      Stream<ContextState>.value(const ContextState());

  @override
  Future<Result<ContextState>> load(String projectId) async =>
      const Success<ContextState>(ContextState());

  @override
  Future<Result<ContextState>> saveHierarchy(
    String projectId,
    List<ContextLevel> levels,
  ) async => const FailureResult<ContextState>(_unavailable);

  @override
  Future<Result<ContextState>> setLevelValue({
    required String projectId,
    required String fieldKey,
    required String value,
    bool clearBelow = true,
  }) async => const FailureResult<ContextState>(_unavailable);

  @override
  Future<Result<ContextState>> savePinned(
    String projectId,
    Map<String, String> pinned,
  ) async => const FailureResult<ContextState>(_unavailable);

  @override
  Future<Result<ContextState>> applyPreset(
    String projectId,
    ContextPreset preset,
  ) async => const FailureResult<ContextState>(_unavailable);

  @override
  Stream<List<ContextPreset>> watchPresets(String projectId) =>
      Stream<List<ContextPreset>>.value(const <ContextPreset>[]);

  @override
  Future<Result<ContextPreset>> savePreset({
    required String projectId,
    required String name,
    required Map<String, String> values,
    required Map<String, String> pinned,
    bool overwrite = false,
  }) async => const FailureResult<ContextPreset>(_unavailable);

  @override
  Future<Result<void>> deletePreset(
    String id, {
    required String reason,
  }) async => const FailureResult<void>(_unavailable);

  @override
  Future<Result<List<String>>> recentValues({
    required String projectId,
    required String fieldKey,
  }) async => const Success<List<String>>(<String>[]);
}

const StorageFailure _unavailable = StorageFailure(
  message: 'Context is not available yet.',
  recoveryAction: 'Restart the app and try again.',
);

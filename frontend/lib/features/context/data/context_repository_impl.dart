import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/context.dart'
    show
        clearContextStateForProject,
        deleteContextDefinition,
        deleteContextPreset,
        liveContextDefinitions,
        liveContextPresets,
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
  /// Opens against [_db] with stamp sources. Recents are kept in the same
  /// database ([ContextPersistence]), so they survive a restart.
  ContextRepositoryImpl({
    required this._db,
    required this._clock,
    required this._deviceId,
    required this._ids,
  });

  final sqlite.AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;
  late final ContextPersistence _persistence = ContextPersistence(
    db: _db,
    clock: _clock,
    deviceId: _deviceId,
  );
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
      // Every definition this project ever had, deleted ones included: a
      // field key keeps its row, so a level that comes back is restored.
      final List<sqlite.ContextData> existing =
          await (_db.select(_db.context)..where(
                (sqlite.$ContextTable tbl) => tbl.projectId.equals(projectId),
              ))
              .get();
      final Set<String> live = <String>{
        for (final sqlite.ContextData row in await liveContextDefinitions(
          _db,
          projectId: projectId,
        ).get())
          row.id,
      };
      final List<ContextLevel> ordered = List<ContextLevel>.of(levels);
      final Set<String> keys = <String>{
        for (final ContextLevel level in ordered) level.fieldKey,
      };
      for (final sqlite.ContextData row in existing) {
        if (live.contains(row.id) && !keys.contains(row.fieldKey)) {
          await deleteContextDefinition(
            _db,
            id: row.id,
            reason: 'Context hierarchy replaced.',
            clock: _clock,
            deviceId: _deviceId,
          );
        }
      }
      final Map<String, sqlite.ContextData> byKey =
          <String, sqlite.ContextData>{
            for (final sqlite.ContextData row in existing) row.fieldKey: row,
          };
      final DateTime now = _clock.nowUtc();
      for (final ContextLevel level in ordered) {
        final sqlite.ContextData? row = byKey[level.fieldKey];
        final String label = ContextMapper.encodeLabel(level);
        if (row == null) {
          await _db
              .into(_db.context)
              .insert(
                ContextMapper.definitionToRow(
                  projectId: projectId,
                  level: level,
                ).copyWith(
                  id: Value<String>(_ids.newId()),
                  createdAt: Value<DateTime>(now),
                  updatedAt: Value<DateTime>(now),
                  updatedByDevice: Value<String>(_deviceId),
                ),
              );
          continue;
        }
        final bool restored = !live.contains(row.id);
        if (restored) {
          await removeTombstone(
            _db,
            entityType: _db.context.actualTableName,
            entityId: row.id,
          );
        }
        if (restored || row.level != level.order + 1 || row.label != label) {
          await (_db.update(
            _db.context,
          )..where((sqlite.$ContextTable tbl) => tbl.id.equals(row.id))).write(
            sqlite.ContextCompanion(
              level: Value<int>(level.order + 1),
              label: Value<String>(label),
              updatedAt: Value<DateTime>(now),
              updatedByDevice: Value<String>(_deviceId),
              rev: Value<int>(row.rev + 1),
            ),
          );
        }
      }
      // Drop values whose field keys are no longer levels.
      final ContextState current = await _load(projectId);
      final Map<String, String> nextValues = <String, String>{
        for (final MapEntry<String, String> e in current.values.entries)
          if (keys.contains(e.key)) e.key: e.value,
      };
      await _writeValues(
        projectId,
        ContextState(
          levels: ordered,
          values: nextValues,
          pinned: current.pinned,
        ),
      );
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
        throw ValidationFailure(
          localizedMessage: Copy.messages.failureThatFieldIsNotAContextLevel,
          localizedRecovery: Copy.messages.failurePickALevelFromTheHierarchyAnd,
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
      await _writeValues(projectId, next);
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
      await _writeValues(projectId, current.copyWith(pinned: pinned));
      // A pin's picker offers its recent values first, as a level's does.
      for (final MapEntry<String, String> pin in pinned.entries) {
        if (current.pinned[pin.key] != pin.value) {
          await _persistence.rememberRecent(
            projectId: projectId,
            fieldKey: pin.key,
            value: pin.value,
          );
        }
      }
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
      await _writeValues(
        projectId,
        current.copyWith(values: nextValues, pinned: preset.pinned),
      );
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
      return FailureResult<ContextPreset>(
        ValidationFailure(
          localizedMessage: Copy.messages.failureAPresetNeedsAName,
          localizedRecovery: Copy.messages.failureEnterANameAndTryAgain,
        ),
      );
    }
    try {
      final sqlite.ContextPreset? existing =
          await (liveContextPresets(_db, projectId: projectId)
                ..where(
                  (sqlite.$ContextPresetsTable tbl) => tbl.name.equals(trimmed),
                )
                ..limit(1))
              .getSingleOrNull();
      if (existing != null && !overwrite) {
        return FailureResult<ContextPreset>(presetNameTaken);
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
      return FailureResult<void>(
        StorageFailure(
          localizedMessage: Copy.messages.failureADeleteNeedsAnIdAndA,
          localizedRecovery: Copy.messages.failureTryAgain,
        ),
      );
    }
    return runInTransaction(_db, () async {
      await deleteContextPreset(
        _db,
        id: id,
        reason: reason,
        clock: _clock,
        deviceId: _deviceId,
      );
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
    final List<sqlite.ContextData> definitions = await liveContextDefinitions(
      _db,
      projectId: projectId,
    ).get();
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

  /// Replaces the project's value and pin rows with [state]'s, in the
  /// caller's transaction. Recents rows (below level 0) are kept.
  Future<void> _writeValues(String projectId, ContextState state) async {
    await clearContextStateForProject(_db, projectId: projectId);
    for (final sqlite.ContextStateCompanion row in ContextMapper.stateToRows(
      projectId: projectId,
      state: state,
      now: _clock.nowUtc(),
      deviceId: _deviceId,
    )) {
      await _db.into(_db.contextState).insert(row);
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
    final List<sqlite.ContextPreset> rows = await liveContextPresets(
      _db,
      projectId: projectId,
    ).get();
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
            liveContextDefinitions(
              _db,
              projectId: projectId,
            ).watch().listen((_) => listener.add(null)),
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
      final StreamSubscription<Object?> sub = liveContextPresets(
        _db,
        projectId: projectId,
      ).watch().listen((_) => listener.add(null));
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
  ) async => FailureResult<ContextState>(_unavailable);

  @override
  Future<Result<ContextState>> setLevelValue({
    required String projectId,
    required String fieldKey,
    required String value,
    bool clearBelow = true,
  }) async => FailureResult<ContextState>(_unavailable);

  @override
  Future<Result<ContextState>> savePinned(
    String projectId,
    Map<String, String> pinned,
  ) async => FailureResult<ContextState>(_unavailable);

  @override
  Future<Result<ContextState>> applyPreset(
    String projectId,
    ContextPreset preset,
  ) async => FailureResult<ContextState>(_unavailable);

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
  }) async => FailureResult<ContextPreset>(_unavailable);

  @override
  Future<Result<void>> deletePreset(
    String id, {
    required String reason,
  }) async => FailureResult<void>(_unavailable);

  @override
  Future<Result<List<String>>> recentValues({
    required String projectId,
    required String fieldKey,
  }) async => const Success<List<String>>(<String>[]);
}

final StorageFailure _unavailable = StorageFailure(
  localizedMessage: Copy.messages.failureContextIsNotAvailableYet,
  localizedRecovery: Copy.messages.failureRestartTheAppAndTryAgain,
);

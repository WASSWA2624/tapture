import 'dart:async';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/context/domain/context_repository.dart';
import 'package:tapture/features/context/domain/context_state.dart';

/// In-memory [ContextRepository] for widget tests.
final class FakeContextRepository implements ContextRepository {
  final Map<String, ContextState> _states = <String, ContextState>{};
  final Map<String, List<ContextPreset>> _presets =
      <String, List<ContextPreset>>{};
  final Map<String, List<String>> _recents = <String, List<String>>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _next = 0;

  /// Releases streams.
  void dispose() {
    _changes.close();
  }

  @override
  Stream<ContextState> watch(String projectId) {
    return _watch(() => _states[projectId] ?? const ContextState());
  }

  @override
  Future<Result<ContextState>> load(String projectId) async {
    return Success<ContextState>(_states[projectId] ?? const ContextState());
  }

  @override
  Future<Result<ContextState>> saveHierarchy(
    String projectId,
    List<ContextLevel> levels,
  ) async {
    final ContextState current = _states[projectId] ?? const ContextState();
    final ContextState next = current.copyWith(
      levels: <ContextLevel>[
        for (int i = 0; i < levels.length; i++) levels[i].copyWith(order: i),
      ],
    );
    _states[projectId] = next;
    _emit();
    return Success<ContextState>(next);
  }

  @override
  Future<Result<ContextState>> setLevelValue({
    required String projectId,
    required String fieldKey,
    required String value,
    bool clearBelow = true,
  }) async {
    final ContextState current = _states[projectId] ?? const ContextState();
    final Map<String, String> values = Map<String, String>.of(current.values);
    values[fieldKey] = value;
    if (clearBelow) {
      final List<ContextLevel> ordered = List<ContextLevel>.of(current.levels)
        ..sort((ContextLevel a, ContextLevel b) => a.order.compareTo(b.order));
      final int index = ordered.indexWhere(
        (ContextLevel l) => l.fieldKey == fieldKey,
      );
      for (final ContextLevel level in ordered.skip(index + 1)) {
        values.remove(level.fieldKey);
      }
    }
    final ContextState next = current.copyWith(values: values);
    _states[projectId] = next;
    final String key = '$projectId::$fieldKey';
    final List<String> recents = List<String>.of(
      _recents[key] ?? const <String>[],
    );
    recents.remove(value);
    recents.insert(0, value);
    _recents[key] = recents;
    _emit();
    return Success<ContextState>(next);
  }

  @override
  Future<Result<ContextState>> savePinned(
    String projectId,
    Map<String, String> pinned,
  ) async {
    final ContextState current = _states[projectId] ?? const ContextState();
    final ContextState next = current.copyWith(pinned: pinned);
    _states[projectId] = next;
    _emit();
    return Success<ContextState>(next);
  }

  @override
  Future<Result<ContextState>> applyPreset(
    String projectId,
    ContextPreset preset,
  ) async {
    final ContextState current = _states[projectId] ?? const ContextState();
    final Map<String, String> values = <String, String>{};
    for (final ContextLevel level in current.levels) {
      final String? value = preset.values[level.fieldKey];
      if (value != null) {
        values[level.fieldKey] = value;
      }
    }
    final ContextState next = current.copyWith(
      values: values,
      pinned: preset.pinned,
    );
    _states[projectId] = next;
    _emit();
    return Success<ContextState>(next);
  }

  @override
  Stream<List<ContextPreset>> watchPresets(String projectId) {
    return _watch(() => _presets[projectId] ?? const <ContextPreset>[]);
  }

  @override
  Future<Result<ContextPreset>> savePreset({
    required String projectId,
    required String name,
    required Map<String, String> values,
    required Map<String, String> pinned,
    bool overwrite = false,
  }) async {
    final List<ContextPreset> list = List<ContextPreset>.of(
      _presets[projectId] ?? const <ContextPreset>[],
    );
    final int existing = list.indexWhere(
      (ContextPreset p) => p.name == name.trim(),
    );
    if (existing >= 0 && !overwrite) {
      return const FailureResult<ContextPreset>(
        ValidationFailure(
          message: 'A preset with that name already exists.',
          recoveryAction: 'Choose another name, or confirm overwrite.',
        ),
      );
    }
    final ContextPreset preset = ContextPreset(
      id: existing >= 0 ? list[existing].id : 'preset-${_next++}',
      name: name.trim(),
      values: values,
      pinned: pinned,
      lastUsedAt: DateTime.utc(2026, 9, 22),
    );
    if (existing >= 0) {
      list[existing] = preset;
    } else {
      list.add(preset);
    }
    _presets[projectId] = list;
    _emit();
    return Success<ContextPreset>(preset);
  }

  @override
  Future<Result<void>> deletePreset(String id, {required String reason}) async {
    for (final String projectId in _presets.keys.toList()) {
      _presets[projectId] = <ContextPreset>[
        for (final ContextPreset p in _presets[projectId]!)
          if (p.id != id) p,
      ];
    }
    _emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<List<String>>> recentValues({
    required String projectId,
    required String fieldKey,
  }) async {
    return Success<List<String>>(
      List<String>.of(_recents['$projectId::$fieldKey'] ?? const <String>[]),
    );
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  Stream<T> _watch<T>(T Function() snapshot) {
    return Stream<T>.multi((MultiStreamController<T> listener) {
      listener.add(snapshot());
      final StreamSubscription<void> sub = _changes.stream.listen((_) {
        listener.add(snapshot());
      });
      listener.onCancel = sub.cancel;
    });
  }
}

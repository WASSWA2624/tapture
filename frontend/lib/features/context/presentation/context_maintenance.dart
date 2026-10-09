import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';

import '../context.dart' show contextRepositoryProvider;
import '../domain/context_auto_clear.dart';
import '../domain/context_state.dart';
import 'context_providers.dart';

/// Runs optional idle clearing, removing only the lowest level with undo.
/// Movement preferences are retained as inert compatibility data (task 164).
class ContextMaintenance extends ConsumerStatefulWidget {
  /// Creates the host. It paints nothing.
  const ContextMaintenance({super.key, this.child = const SizedBox.shrink()});

  /// Application content whose pointer and keyboard activity resets idle time.
  final Widget child;

  @override
  ConsumerState<ContextMaintenance> createState() => _ContextMaintenanceState();
}

class _ContextMaintenanceState extends ConsumerState<ContextMaintenance> {
  Timer? _timer;
  StreamSubscription<SettingKey<Object?>>? _settings;
  DateTime? _lastActivity;
  bool _fired = false;
  bool _clearing = false;
  String _signature = '';

  @override
  void initState() {
    super.initState();
    _settings = ref
        .read(projectSettingsStoreProvider)
        .changes()
        .listen((_) => _syncTimer());
    _syncTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_settings?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(currentProjectProvider, (String? _, String? next) {
      _signature = '';
      _fired = false;
      _lastActivity = ref.read(contextClockProvider).nowUtc();
      if (next != null && next.isNotEmpty) {
        unawaited(ref.read(contextRepositoryProvider).load(next));
      }
    });
    // Keeps the open project's context live for the checks below, whether
    // or not a context bar is on screen.
    ref.listen<AsyncValue<ContextState>>(
      openProjectContextProvider,
      (AsyncValue<ContextState>? _, AsyncValue<ContextState> _) {},
    );
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _activity(),
      onPointerSignal: (_) => _activity(),
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (_, _) {
          _activity();
          return KeyEventResult.ignored;
        },
        child: widget.child,
      ),
    );
  }

  void _activity() {
    _lastActivity = ref.read(contextClockProvider).nowUtc();
    _fired = false;
  }

  void _syncTimer() {
    if (!mounted) {
      return;
    }
    final SettingsStore store = ref.read(projectSettingsStoreProvider);
    final bool on = store.read(SettingKeys.contextAutoClearEnabled);
    if (!on) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(AppConstants.context.checkEvery, (_) {
      unawaited(_tick());
    });
  }

  Future<void> _tick() async {
    if (!mounted) {
      return;
    }
    final String? projectId = ref.read(currentProjectProvider);
    if (projectId == null || projectId.isEmpty) {
      return;
    }
    final ContextState? state = ref
        .read(openProjectContextProvider)
        .asData
        ?.value;
    if (state == null) {
      return;
    }
    _noteActivity(state);
    if (!_clearing) {
      _clearing = true;
      try {
        await _autoClear(projectId, state);
      } finally {
        _clearing = false;
      }
    }
  }

  void _noteActivity(ContextState state) {
    final String signature = <String>[
      for (final MapEntry<String, String> entry in state.values.entries)
        '${entry.key}=${entry.value}',
    ].join('|');
    if (signature == _signature) {
      _lastActivity ??= ref.read(contextClockProvider).nowUtc();
      return;
    }
    if (_signature.isNotEmpty) {
      _fired = false;
      _lastActivity = ref.read(contextClockProvider).nowUtc();
    }
    _signature = signature;
    _lastActivity ??= ref.read(contextClockProvider).nowUtc();
  }

  Future<void> _autoClear(String projectId, ContextState state) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final SettingsStore store = ref.read(projectSettingsStoreProvider);
    final bool enabled = store.read(SettingKeys.contextAutoClearEnabled);
    if (!enabled) {
      return;
    }
    final Clock clock = ref.read(contextClockProvider);
    final bool due = ContextAutoClear.shouldClear(
      enabled: enabled,
      idleInterval:
          AppConstants.second * store.read(SettingKeys.contextAutoClearSeconds),
      lastActivity: _lastActivity ?? clock.nowUtc(),
      now: clock.nowUtc(),
      alreadyFiredThisPeriod: _fired,
    );
    if (!due) {
      return;
    }
    final ({ContextState next, String? fieldKey, String? value}) cleared =
        ContextAutoClear.clearLowest(state);
    final String? fieldKey = cleared.fieldKey;
    final String? value = cleared.value;
    if (fieldKey == null || value == null) {
      _fired = true;
      return;
    }
    final Result<ContextState> written = await ref
        .read(contextRepositoryProvider)
        .setLevelValue(
          projectId: projectId,
          fieldKey: fieldKey,
          value: '',
          clearBelow: false,
        );
    if (!mounted || written is FailureResult<ContextState>) {
      return;
    }
    _fired = true;
    final String label = _label(state, fieldKey);
    showAppSnack(
      context,
      localCopy.contextAutoClearMessage(label),
      undoLabel: localCopy.contextAutoClearUndo,
      onUndo: () => unawaited(_undo(projectId, fieldKey, value)),
    );
  }

  /// Puts the cleared value back exactly; a failed write says why.
  Future<void> _undo(String projectId, String fieldKey, String value) async {
    _fired = false;
    _lastActivity = ref.read(contextClockProvider).nowUtc();
    final Result<ContextState> restored = await ref
        .read(contextRepositoryProvider)
        .setLevelValue(
          projectId: projectId,
          fieldKey: fieldKey,
          value: value,
          clearBelow: false,
        );
    if (!mounted) {
      return;
    }
    if (restored case FailureResult<ContextState>(:final Failure failure)) {
      showAppSnack(
        context,
        failure.message,
        tone: SnackTone.error,
        localizedMessage: failure.explanation,
      );
    }
  }

  String _label(ContextState state, String fieldKey) {
    for (final ContextLevel level in state.levels) {
      if (level.fieldKey == fieldKey) {
        return level.label.isEmpty ? level.fieldKey : level.label;
      }
    }
    return fieldKey;
  }
}

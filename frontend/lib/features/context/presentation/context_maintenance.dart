import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/location/location_service.dart';
import 'package:tapture/core/permissions/permissions_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';

import '../context.dart' show contextRepositoryProvider;
import '../domain/context_auto_clear.dart';
import '../domain/context_movement_prompt.dart';
import '../domain/context_state.dart';
import 'context_providers.dart';

/// Runs the two optional context settings. Both stay inert while off.
///
/// Auto-clear removes only the lowest level and offers one undo.
/// The movement prompt asks for confirmation and never writes context.
/// No location read and no permission request happen while it is off.
class ContextMaintenance extends ConsumerStatefulWidget {
  /// Creates the host. It paints nothing.
  const ContextMaintenance({super.key});

  @override
  ConsumerState<ContextMaintenance> createState() => _ContextMaintenanceState();
}

class _ContextMaintenanceState extends ConsumerState<ContextMaintenance> {
  Timer? _timer;
  StreamSubscription<SettingKey<Object?>>? _settings;
  DateTime? _lastActivity;
  bool _fired = false;
  bool _busy = false;
  ({double latitude, double longitude})? _origin;
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
      _origin = null;
      _lastActivity = ref.read(contextClockProvider).nowUtc();
      if (next != null && next.isNotEmpty) {
        unawaited(ref.read(contextRepositoryProvider).load(next));
      }
    });
    return const SizedBox.shrink();
  }

  void _syncTimer() {
    if (!mounted) {
      return;
    }
    final SettingsStore store = ref.read(projectSettingsStoreProvider);
    final bool on =
        store.read(SettingKeys.contextAutoClearEnabled) ||
        store.read(SettingKeys.contextMovementPromptEnabled);
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
    if (!mounted || _busy) {
      return;
    }
    final String? projectId = ref.read(currentProjectProvider);
    if (projectId == null || projectId.isEmpty) {
      return;
    }
    final ContextState? state = ref
        .read(projectContextProvider(projectId))
        .asData
        ?.value;
    if (state == null) {
      return;
    }
    _noteActivity(state);
    await _autoClear(projectId, state);
    if (!mounted) {
      return;
    }
    await _movement();
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
    _fired = true;
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
    final String label = _label(state, fieldKey);
    showAppSnack(
      context,
      Copy.contextAutoClearMessage(label),
      undoLabel: Copy.contextAutoClearUndo,
      onUndo: () => unawaited(_undo(projectId, fieldKey, value)),
    );
  }

  Future<void> _undo(String projectId, String fieldKey, String value) async {
    _fired = false;
    _lastActivity = ref.read(contextClockProvider).nowUtc();
    await ref
        .read(contextRepositoryProvider)
        .setLevelValue(
          projectId: projectId,
          fieldKey: fieldKey,
          value: value,
          clearBelow: false,
        );
  }

  Future<void> _movement() async {
    final SettingsStore store = ref.read(projectSettingsStoreProvider);
    final bool enabled = store.read(SettingKeys.contextMovementPromptEnabled);
    final bool gps = store.read(SettingKeys.gpsEnabled);
    if (!enabled || !gps) {
      return;
    }
    final PermissionState status = await ref
        .read(contextPermissionsProvider)
        .status(AppPermission.location);
    if (status != PermissionState.granted || !mounted) {
      return;
    }
    final Result<GeoFix?> fix = await ref
        .read(locationServiceProvider)
        .currentFix();
    if (!mounted || fix is! Success<GeoFix?>) {
      return;
    }
    final GeoFix? here = fix.value;
    if (here == null) {
      return;
    }
    final ({double latitude, double longitude}) current = (
      latitude: here.latitude,
      longitude: here.longitude,
    );
    final ({double latitude, double longitude})? origin = _origin;
    _origin = current;
    if (origin == null) {
      return;
    }
    final double metres = ContextMovementPrompt.metresBetween(origin, current);
    final bool ask = ContextMovementPrompt.shouldPrompt(
      enabled: enabled,
      gpsEnabled: gps,
      locationGranted: true,
      distanceMetres: metres,
      thresholdMetres: store.read(SettingKeys.contextMovementMetres).toDouble(),
    );
    if (!ask || !mounted) {
      return;
    }
    _busy = true;
    await showAppConfirm(
      context,
      title: Copy.contextMovementTitle,
      message: Copy.contextMovementMessage,
      confirmLabel: Copy.ok,
    );
    _busy = false;
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

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/network/connectivity_service.dart';
import 'package:tapture/features/settings/settings.dart';

import '../domain/auto_process.dart';
import '../domain/background_ocr.dart';

/// The two unattended paths: automatic processing when a connection appears,
/// and on-device reading while the device charges and sits idle.
///
/// Each is off until its setting is on, and each asks [AutoProcess] or
/// [BackgroundOcr], which go through `BackgroundPolicy`, so nothing starts
/// while the app is in front. A resume stops whichever is running at once;
/// so do losing the network during automatic processing and unplugging
/// during on-device reading. Work already finished is kept.
final class UnattendedProcessing {
  /// Creates the paths over their signals. [processAll] runs a full batch,
  /// [readOnDevice] a batch that stops after on-device reading, and
  /// [cancel] stops either. [underCap] says whether today's online budget
  /// still has room.
  UnattendedProcessing({
    required this._network,
    required this._lifecycle,
    required this._charging,
    required this._settings,
    required this._underCap,
    required this._processAll,
    required this._readOnDevice,
    required this._cancel,
    Duration? idleAfter,
  }) : _idleAfter = idleAfter ?? AppConstants.processing.idleAfter;

  final Stream<NetworkState> _network;
  final Stream<AppLifecycleState> _lifecycle;
  final Stream<bool> _charging;
  final SettingsStore _settings;
  final Future<bool> Function() _underCap;
  final Future<void> Function() _processAll;
  final Future<void> Function() _readOnDevice;
  final void Function() _cancel;
  final Duration _idleAfter;

  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];
  Timer? _idleTimer;
  NetworkState? _net;
  bool _foreground = true;
  bool _idle = false;
  bool _pluggedIn = false;
  UnattendedRun _running = UnattendedRun.none;

  /// Which path is running now.
  UnattendedRun get running => _running;

  /// Starts listening. The app starts in front, so nothing runs until it
  /// goes to the background.
  void start() {
    _subscriptions
      ..add(_network.listen(_onNetwork))
      ..add(_lifecycle.listen(_onLifecycle))
      ..add(_charging.listen(_onCharging));
  }

  /// Stops listening and stops any run.
  Future<void> dispose() async {
    _idleTimer?.cancel();
    _stop();
    for (final StreamSubscription<Object?> subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  void _onLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _foreground = true;
        _idle = false;
        _idleTimer?.cancel();
        // Nothing unattended runs while the app is in front.
        _stop();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (!_foreground) {
          return;
        }
        _foreground = false;
        _idleTimer?.cancel();
        _idleTimer = Timer(_idleAfter, () {
          _idle = true;
          _maybeReadOnDevice();
        });
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  void _onNetwork(NetworkState next) {
    final NetworkState? previous = _net;
    _net = next;
    if (_running == UnattendedRun.automatic && !_networkAllowed(next)) {
      _stop();
      return;
    }
    unawaited(_maybeProcess(previous, next));
  }

  void _onCharging(bool charging) {
    _pluggedIn = charging;
    if (!charging && _running == UnattendedRun.onDevice) {
      _stop();
      return;
    }
    _maybeReadOnDevice();
  }

  Future<void> _maybeProcess(NetworkState? previous, NetworkState next) async {
    if (_running != UnattendedRun.none) {
      return;
    }
    final bool enabled = _settings.read(SettingKeys.aiAutoProcess);
    if (!enabled || _foreground) {
      return;
    }
    final bool underCap = await _underCap();
    final bool start = AutoProcess.shouldStart(
      enabled: enabled,
      wifiOnly: _settings.read(SettingKeys.aiWifiOnly),
      previous: previous,
      next: next,
      foreground: _foreground,
      underCap: underCap,
    );
    if (start && _running == UnattendedRun.none) {
      await _run(UnattendedRun.automatic, _processAll);
    }
  }

  void _maybeReadOnDevice() {
    if (_running != UnattendedRun.none) {
      return;
    }
    final bool run = BackgroundOcr.shouldRun(
      enabled: _settings.read(SettingKeys.aiOpportunisticOcr),
      charging: _pluggedIn,
      idle: _idle,
      foreground: _foreground,
    );
    if (run) {
      unawaited(_run(UnattendedRun.onDevice, _readOnDevice));
    }
  }

  Future<void> _run(UnattendedRun kind, Future<void> Function() body) async {
    _running = kind;
    try {
      await body();
    } finally {
      _running = UnattendedRun.none;
    }
  }

  bool _networkAllowed(NetworkState net) {
    if (net == NetworkState.offline) {
      return false;
    }
    return !_settings.read(SettingKeys.aiWifiOnly) ||
        net == NetworkState.online;
  }

  void _stop() {
    if (_running != UnattendedRun.none) {
      _cancel();
    }
  }
}

/// Which unattended path is running.
enum UnattendedRun {
  /// Neither.
  none,

  /// Processing started by a connection gain.
  automatic,

  /// On-device reading while charging and idle.
  onDevice,
}

/// The app's unattended paths. Null until the app wires its signals, as it
/// does outside tests; the shell keeps it alive.
final Provider<UnattendedProcessing?> unattendedProcessingProvider =
    Provider<UnattendedProcessing?>((Ref _) => null);

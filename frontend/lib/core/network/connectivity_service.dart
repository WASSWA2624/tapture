import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Combined radio and override signal every outbound path must honour.
///
/// The platform plugin is reached only here. Tests pass [ConnectivityService.fake]
/// so they never touch the radio (FE-STR-11, FE-TEST-03).
abstract interface class ConnectivityService {
  /// Watches the device radio and an optional [offlineOverride].
  ///
  /// When [offlineOverride] is omitted the override is off. The stored flag is
  /// fed through that stream; this service is the only reader of it.
  factory ConnectivityService({Stream<bool>? offlineOverride}) {
    return _ConnectivityService(
      source: _platformRadio(),
      offlineOverride: offlineOverride ?? const Stream<bool>.empty(),
    );
  }

  /// A hand-written stand-in driven by [source], so tests never open the plugin.
  factory ConnectivityService.fake({
    required Stream<NetworkState> source,
    Stream<bool>? offlineOverride,
  }) {
    return _ConnectivityService(
      source: source,
      offlineOverride: offlineOverride ?? const Stream<bool>.empty(),
    );
  }

  /// Online, metered or offline. Offline whenever the override is on, whatever
  /// the radio says.
  Stream<NetworkState> watch();

  /// Cancels the radio and override subscriptions and closes [watch].
  Future<void> dispose();
}

/// Reachability later features use to decide whether an upload may start.
enum NetworkState {
  /// An unmetered path is available (Wi-Fi, ethernet, VPN or similar).
  online,

  /// Only a metered or constrained path is available (cellular, satellite).
  metered,

  /// No path, or the operator has forced offline.
  offline,
}

final class _ConnectivityService implements ConnectivityService {
  _ConnectivityService({
    required Stream<NetworkState> source,
    required Stream<bool> offlineOverride,
  }) {
    // Sync so a listener that just flipped the override cannot still see online.
    _output = StreamController<NetworkState>.broadcast(
      onListen: _replay,
      sync: true,
    );
    _radioSub = source.listen(_onRadio);
    _overrideSub = offlineOverride.listen(_onOverride);
  }

  late final StreamSubscription<NetworkState> _radioSub;
  late final StreamSubscription<bool> _overrideSub;
  late final StreamController<NetworkState> _output;

  NetworkState? _radio;
  bool _forced = false;
  NetworkState? _last;
  bool _closed = false;

  @override
  Stream<NetworkState> watch() => _output.stream;

  void _replay() {
    final NetworkState? last = _last;
    if (last != null && !_output.isClosed) {
      _output.add(last);
    }
  }

  void _onRadio(NetworkState next) {
    _radio = next;
    _emit();
  }

  void _onOverride(bool next) {
    _forced = next;
    _emit();
  }

  void _emit() {
    if (_closed) {
      return;
    }
    final NetworkState? radio = _radio;
    if (radio == null) {
      return;
    }
    final NetworkState next = _forced ? NetworkState.offline : radio;
    if (_last == next) {
      return;
    }
    _last = next;
    _output.add(next);
  }

  @override
  Future<void> dispose() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _radioSub.cancel();
    await _overrideSub.cancel();
    await _output.close();
  }
}

/// The plugin's radio stream, mapped into [NetworkState].
///
/// Satellite is treated as metered so a later upload can defer it without a
/// second check. A plugin error is offline — outbound work must not proceed
/// when the radio cannot be read (FE-SEC-04).
Stream<NetworkState> _platformRadio() {
  final Connectivity connectivity = Connectivity();
  late final StreamController<NetworkState> controller;
  StreamSubscription<List<ConnectivityResult>>? changes;
  controller = StreamController<NetworkState>(
    onListen: () {
      unawaited(
        connectivity.checkConnectivity().then(
          (List<ConnectivityResult> results) {
            if (!controller.isClosed) {
              controller.add(_mapRadio(results));
            }
          },
          onError: (Object _, StackTrace _) {
            if (!controller.isClosed) {
              controller.add(NetworkState.offline);
            }
          },
        ),
      );
      changes = connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          if (!controller.isClosed) {
            controller.add(_mapRadio(results));
          }
        },
        onError: (Object _, StackTrace _) {
          if (!controller.isClosed) {
            controller.add(NetworkState.offline);
          }
        },
      );
    },
    onCancel: () async {
      await changes?.cancel();
    },
  );
  return controller.stream;
}

NetworkState _mapRadio(List<ConnectivityResult> results) {
  var unmetered = false;
  var metered = false;
  for (final ConnectivityResult result in results) {
    switch (result) {
      case ConnectivityResult.none:
        break;
      case ConnectivityResult.mobile:
      case ConnectivityResult.satellite:
        metered = true;
      case ConnectivityResult.wifi:
      case ConnectivityResult.ethernet:
      case ConnectivityResult.vpn:
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.other:
        unmetered = true;
    }
  }
  if (unmetered) {
    return NetworkState.online;
  }
  if (metered) {
    return NetworkState.metered;
  }
  return NetworkState.offline;
}

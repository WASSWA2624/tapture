import 'dart:async';

import 'connectivity_service.dart';

/// Outbound work that honours [NetworkState] so no call leaves while
/// offline (FE-SEC-04).
///
/// [send] is the recording or platform boundary. This type never imports
/// an HTTP client; allowed egress folders pass theirs in.
class OutboundQueue {
  /// Creates a queue over [network]. Offline work waits; an online or
  /// metered transition drains. A return to offline stops a drain.
  OutboundQueue({required Stream<NetworkState> network, required this._send}) {
    _sub = network.listen(_onNetwork);
  }

  final Future<void> Function(String path, String body) _send;
  late final StreamSubscription<NetworkState> _sub;

  final List<({String path, String body})> _queued =
      <({String path, String body})>[];
  NetworkState? _state;
  bool _draining = false;

  /// Sends [path] and [body] now, or holds them until the network allows it.
  Future<void> submit({required String path, required String body}) async {
    if (_canSend) {
      await _send(path, body);
      return;
    }
    _queued.add((path: path, body: body));
  }

  /// How many calls are waiting. Tests read this; features do not cache it.
  int get pending => _queued.length;

  /// Stops listening to the network. Pending work is left unsent.
  Future<void> dispose() => _sub.cancel();

  bool get _canSend {
    return _state == NetworkState.online || _state == NetworkState.metered;
  }

  void _onNetwork(NetworkState next) {
    _state = next;
    if (_canSend) {
      unawaited(_drain());
    }
  }

  Future<void> _drain() async {
    if (_draining) {
      return;
    }
    _draining = true;
    try {
      while (_queued.isNotEmpty && _canSend) {
        final ({String path, String body}) call = _queued.removeAt(0);
        await _send(call.path, call.body);
      }
    } finally {
      _draining = false;
    }
  }
}

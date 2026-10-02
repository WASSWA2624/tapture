import 'dart:io';
import 'dart:isolate';

import 'cancellation_token.dart';

/// Native bridge for cancellation of workers that must close file handles.
final class CooperativeCancellation {
  /// Connects cancellation without killing the worker before its cleanup.
  CooperativeCancellation(this._cancel, {this._signal}) {
    _replies.listen((Object? message) {
      if (message is SendPort) {
        _worker = message;
        if (_cancel.isCancelled) {
          _worker?.send(null);
        }
      }
    });
    _detachCancellation = _cancel.register(() {
      if (!_closed) {
        // Only the caller owns its synchronous worker signal. It runs before
        // the control message so both synchronous and asynchronous work stop.
        try {
          _signal?.call();
        } on FileSystemException {
          // The control message still reaches the asynchronous checkpoint.
        }
        _worker?.send(null);
      }
    });
  }

  final CancellationToken _cancel;
  final void Function()? _signal;
  final ReceivePort _replies = ReceivePort();
  SendPort? _worker;
  bool _closed = false;
  late final void Function() _detachCancellation;

  /// Passes through the isolate job as its cancellation handshake port.
  SendPort get handshake => _replies.sendPort;

  /// Releases the parent port after the worker has finished or failed.
  void close() {
    _closed = true;
    _detachCancellation();
    _replies.close();
  }
}

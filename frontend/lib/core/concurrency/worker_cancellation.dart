import 'dart:io';
import 'dart:isolate';

import 'package:tapture/core/errors/failure.dart';

/// Worker end of cooperative cancellation for a native file operation.
final class WorkerCancellation {
  /// Announces the control port to the parent's handshake.
  WorkerCancellation(SendPort handshake, {this._lease}) {
    _requests.listen((Object? _) => _cancelled = true);
    handshake.send(_requests.sendPort);
  }

  final ReceivePort _requests = ReceivePort();
  final File? _lease;
  bool _cancelled = false;

  /// Checks during streaming; throwing closes the file subscription.
  void check() {
    if (_cancelled) {
      throw const CancelledFailure();
    }
    final File? lease = _lease;
    if (lease != null) {
      try {
        if (!lease.existsSync()) {
          throw const CancelledFailure();
        }
      } on FileSystemException {
        throw const CancelledFailure();
      }
    }
  }

  /// Allows control messages between entries, then checks cancellation.
  Future<void> checkpoint() async {
    await Future<void>.delayed(Duration.zero);
    check();
  }

  /// Closes the control port once all resources have been released.
  void close() => _requests.close();
}

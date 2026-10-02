import 'dart:async';

import 'package:tapture/core/errors/result.dart';

import 'document_picker.dart';
import 'incoming_bundle_service_stub.dart'
    if (dart.library.io) 'incoming_bundle_service_io.dart'
    as platform;

/// User-opened packages delivered by the operating system. Delivery opens the
/// normal inspection/preview flow; it never applies an import automatically.
abstract interface class IncomingBundleService {
  /// The mobile bridge, or an empty service on unsupported hosts.
  factory IncomingBundleService() => platform.platformIncomingBundleService();

  /// The native channel boundary, also usable with a test binary messenger.
  factory IncomingBundleService.channel() =>
      platform.channelIncomingBundleService();

  /// A queued source for app routing tests.
  factory IncomingBundleService.fake({List<Result<PickedDocument>> pending}) =
      _FakeIncomingBundleService;

  /// A single subscription. Pausing stops native dequeueing until it resumes.
  /// Cold-start packages drain on first listen; later user opens arrive here.
  Stream<Result<PickedDocument>> watch();

  /// Releases the channel subscription and any undelivered sandbox copies.
  Future<void> dispose();
}

final class _FakeIncomingBundleService implements IncomingBundleService {
  _FakeIncomingBundleService({List<Result<PickedDocument>> pending = const []})
    : _pending = List<Result<PickedDocument>>.of(pending) {
    _events = StreamController<Result<PickedDocument>>(
      sync: true,
      onListen: _drain,
      onResume: _drain,
    );
  }

  final List<Result<PickedDocument>> _pending;
  late final StreamController<Result<PickedDocument>> _events;
  bool _closed = false;

  void _drain() => scheduleMicrotask(() {
    while (!_closed && !_events.isPaused && _pending.isNotEmpty) {
      _events.add(_pending.removeAt(0));
    }
  });

  @override
  Stream<Result<PickedDocument>> watch() => _events.stream;

  @override
  Future<void> dispose() async {
    _closed = true;
    for (final Result<PickedDocument> document in _pending) {
      if (document case Success<PickedDocument>(:final PickedDocument value)) {
        await discardPickedCopy(value);
      }
    }
    _pending.clear();
    unawaited(_events.close());
  }
}

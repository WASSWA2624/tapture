import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'document_picker.dart';
import 'incoming_bundle_service.dart';
import 'incoming_bundle_service_stub.dart' as stub;

const MethodChannel _channel = MethodChannel('com.tapture.app/files');

/// Native mobile launches and document opens are queued until Flutter listens.
IncomingBundleService platformIncomingBundleService() =>
    Platform.isAndroid || Platform.isIOS
    ? channelIncomingBundleService()
    : stub.platformIncomingBundleService();

/// Channel implementation shared with deterministic messenger tests.
IncomingBundleService channelIncomingBundleService() => _ChannelIncoming();

final class _ChannelIncoming implements IncomingBundleService {
  _ChannelIncoming() {
    _events = StreamController<Result<PickedDocument>>(
      sync: true,
      onListen: _listen,
      onResume: _listen,
    );
  }

  late final StreamController<Result<PickedDocument>> _events;
  Future<void>? _draining;
  final List<Result<PickedDocument>> _pending = [];
  var _closed = false;
  var _registered = false;
  var _signal = false;

  @override
  Stream<Result<PickedDocument>> watch() => _events.stream;

  void _listen() {
    if (!_registered) {
      _registered = true;
      _channel.setMethodCallHandler((MethodCall call) async {
        if (call.method != 'incomingBundleAvailable') {
          return;
        }
        if (call.arguments case {'error': final String error}) {
          _deliver(FailureResult<PickedDocument>(_failure(error)));
        }
        unawaited(_drain());
      });
    }
    while (!_events.isPaused && _pending.isNotEmpty) {
      _events.add(_pending.removeAt(0));
    }
    unawaited(_drain());
  }

  Future<void> _drain() {
    _signal = true;
    return _draining ??= _poll().whenComplete(() {
      _draining = null;
      if (_signal && !_closed && _events.hasListener && !_events.isPaused) {
        unawaited(_drain());
      }
    });
  }

  Future<void> _poll() async {
    while (!_closed && _events.hasListener && !_events.isPaused) {
      _signal = false;
      try {
        final Object? payload = await _channel
            .invokeMethod<Object>('takeIncomingBundle')
            .timeout(AppConstants.imports.incomingBridgeTimeout);
        if (payload == null) {
          if (!_signal) {
            return;
          }
          continue;
        }
        final Result<PickedDocument> document =
            await Result.captureAsync<PickedDocument>(() => _document(payload));
        if (_closed) {
          await _discard(document);
        } else {
          _deliver(document);
        }
      } on MissingPluginException {
        return;
      } on Object {
        if (!_closed) {
          _deliver(FailureResult<PickedDocument>(_unreadable));
        }
        return;
      }
    }
  }

  void _deliver(Result<PickedDocument> document) {
    if (_closed) {
      return;
    }
    if (_events.hasListener && !_events.isPaused) {
      _events.add(document);
    } else if (_pending.length < 2) {
      _pending.add(document);
    } else {
      unawaited(_discard(document));
    }
  }

  Future<PickedDocument> _document(Object payload) async {
    if (payload case {'error': final String error}) {
      throw _failure(error);
    }
    if (payload case {
      'path': final String path,
      'name': final String name,
      'byteLength': final int length,
    }) {
      // Only a generated copy under the app's temporary directory is owned.
      final File file = File(path);
      final String resolved = await file.resolveSymbolicLinks();
      final String temporary = await Directory.systemTemp
          .resolveSymbolicLinks();
      final String separator = Platform.pathSeparator;
      final String root = temporary.endsWith(separator)
          ? temporary
          : '$temporary$separator';
      if (!resolved.startsWith(root) ||
          File(resolved).parent.path.split(separator).last !=
              'incoming-bundles' ||
          resolved.split(separator).last.startsWith('incoming-') == false) {
        throw _unreadable;
      }
      if (length < 0 ||
          length > AppConstants.bundles.nativeMaxBytes ||
          await file.length() != length) {
        await file.delete();
        throw ValidationFailure(
          localizedMessage:
              Copy.messages.failureThisPackageIsTooLargeOrIncomplete,
        );
      }
      return PickedFile(file, name, length, isCopy: true);
    }
    throw _unreadable;
  }

  Future<void> _discard(Result<PickedDocument> document) async {
    if (document case Success<PickedDocument>(:final PickedDocument value)) {
      await discardPickedCopy(value);
    }
  }

  @override
  Future<void> dispose() async {
    _closed = true;
    if (_registered) {
      _channel.setMethodCallHandler(null);
    }
    await _draining;
    try {
      await _channel
          .invokeMethod<void>('discardIncomingBundles')
          .timeout(AppConstants.imports.incomingBridgeTimeout);
    } on Object {
      // Activity teardown also releases its bounded native queue.
    }
    for (final Result<PickedDocument> document in _pending) {
      await _discard(document);
    }
    _pending.clear();
    unawaited(_events.close());
  }
}

Failure _failure(String code) => code == 'busy'
    ? ValidationFailure(
        localizedMessage:
            Copy.messages.failureFinishTheCurrentPackageBeforeOpeningAnother,
      )
    : code == 'too_large'
    ? ValidationFailure(
        localizedMessage: Copy.messages.failureThisPackageIsTooLargeToOpen,
      )
    : _unreadable;

final StorageFailure _unreadable = StorageFailure(
  localizedMessage: Copy.messages.failureThisPackageCouldNotBeOpened,
  localizedRecovery: Copy.messages.failureOpenTheFileAgainFromItsOriginal,
);

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';

@JS('globalThis.crypto.subtle')
external _SubtleCrypto? get _subtle;

extension type _SubtleCrypto(JSObject _) implements JSObject {
  external JSPromise<JSObject> importKey(
    JSString format,
    JSUint8Array keyData,
    JSObject algorithm,
    JSBoolean extractable,
    JSArray<JSString> keyUsages,
  );

  external JSPromise<JSArrayBuffer> sign(
    JSObject algorithm,
    JSObject key,
    JSUint8Array bytes,
  );
}

/// The browser authenticates large ciphertext away from the Flutter event loop.
Future<Uint8List> sign(
  Uint8List key,
  Uint8List bytes, {
  CancellationToken? cancel,
}) async {
  if (cancel?.isCancelled ?? false) {
    throw const CancelledFailure();
  }
  Future<Uint8List> work() async {
    final _SubtleCrypto? crypto = _subtle;
    if (crypto == null) {
      throw const FormatException('Browser cryptography is unavailable.');
    }
    final JSObject algorithm =
        <String, String>{'name': 'HMAC', 'hash': 'SHA-256'}.jsify()!
            as JSObject;
    final JSObject imported = await crypto
        .importKey(
          'raw'.toJS,
          key.toJS,
          algorithm,
          false.toJS,
          <JSString>['sign'.toJS].toJS,
        )
        .toDart;
    if (cancel?.isCancelled ?? false) {
      throw const CancelledFailure();
    }
    final JSArrayBuffer mac = await crypto
        .sign(
          <String, String>{'name': 'HMAC'}.jsify()! as JSObject,
          imported,
          bytes.toJS,
        )
        .toDart;
    return mac.toDart.asUint8List();
  }

  return cancel == null
      ? work()
      : cancel.race<Uint8List>(
          work(),
          onCancel: () => throw const CancelledFailure(),
        );
}

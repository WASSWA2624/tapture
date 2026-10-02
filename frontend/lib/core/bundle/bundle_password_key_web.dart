import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
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

  external JSPromise<JSArrayBuffer> deriveBits(
    JSObject algorithm,
    JSObject baseKey,
    JSNumber length,
  );
}

/// WebCrypto PBKDF2 does not run the password loop on the Flutter UI thread.
Future<Uint8List> derive(
  String password,
  Uint8List salt,
  int iterations, {
  CancellationToken? cancel,
}) async {
  if (cancel?.isCancelled ?? false) {
    throw const CancelledFailure();
  }
  Future<Uint8List> work() async {
    final _SubtleCrypto? crypto = _subtle;
    if (crypto == null) {
      throw StorageFailure(
        localizedMessage:
            Copy.messages.failurePasswordProtectionNeedsBrowserCryptography,
        localizedRecovery:
            Copy.messages.failureOpenTheAppThroughASecureConnection,
      );
    }
    final JSObject key = await crypto
        .importKey(
          'raw'.toJS,
          Uint8List.fromList(utf8.encode(password)).toJS,
          <String, String>{'name': 'PBKDF2'}.jsify()! as JSObject,
          false.toJS,
          <JSString>['deriveBits'.toJS].toJS,
        )
        .toDart;
    final JSArrayBuffer bits = await crypto
        .deriveBits(
          <String, Object>{
                'name': 'PBKDF2',
                'salt': salt.toJS,
                'iterations': iterations,
                'hash': 'SHA-256',
              }.jsify()!
              as JSObject,
          key,
          256.toJS,
        )
        .toDart;
    return bits.toDart.asUint8List();
  }

  return cancel == null
      ? work()
      : cancel.race<Uint8List>(
          work(),
          onCancel: () => throw const CancelledFailure(),
        );
}

import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';

@JS('fetch')
external JSPromise<_Response> _fetch(JSString url, JSObject options);

@JS('AbortController')
extension type _AbortController._(JSObject _) implements JSObject {
  external factory _AbortController();
  external JSObject get signal;
  external void abort();
}

extension type _Response._(JSObject _) implements JSObject {
  external int get status;
  external JSPromise<JSString> text();
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

/// Uses fetch without cookies or redirects; timeouts abort the request.
Future<({int status, String body})> send({
  required Uri uri,
  required String method,
  required Map<String, String> headers,
  String? body,
  CancellationToken? cancellationToken,
}) async {
  final response = await sendBytes(
    uri: uri,
    method: method,
    headers: headers,
    body: body == null ? null : Uint8List.fromList(utf8.encode(body)),
    cancellationToken: cancellationToken,
  );
  return (status: response.status, body: utf8.decode(response.body));
}

/// Transfers ciphertext without converting bytes through a text encoding.
Future<({int status, Uint8List body})> sendBytes({
  required Uri uri,
  required String method,
  required Map<String, String> headers,
  Uint8List? body,
  CancellationToken? cancellationToken,
}) async {
  if (cancellationToken?.isCancelled == true) throw const CancelledFailure();
  final _AbortController controller = _AbortController();
  final void Function()? detach = cancellationToken?.register(
    () => controller.abort(),
  );
  try {
    final Future<({int status, Uint8List body})> pending = (() async {
      final _Response response = await _fetch(
        uri.toString().toJS,
        <String, Object?>{
              'method': method,
              'headers': headers,
              'credentials': 'omit',
              'redirect': 'error',
              'signal': controller.signal,
              'body': ?body?.toJS,
            }.jsify()!
            as JSObject,
      ).toDart;
      final Uint8List bytes = (await response.arrayBuffer().toDart).toDart
          .asUint8List();
      if (bytes.length > AppConstants.imports.bundleMaxBytes) {
        throw const FormatException('Response too large.');
      }
      return (status: response.status, body: bytes);
    })().timeout(AppConstants.backend.proxyTimeout);
    return await (cancellationToken?.race(
          pending,
          onCancel: () => throw const CancelledFailure(),
        ) ??
        pending);
  } finally {
    detach?.call();
    controller.abort();
  }
}

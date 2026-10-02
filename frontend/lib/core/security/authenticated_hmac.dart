import 'dart:typed_data';

import 'package:tapture/core/concurrency/cancellation_token.dart';

import 'authenticated_hmac_stub.dart'
    if (dart.library.js_interop) 'authenticated_hmac_web.dart'
    as platform;

/// Computes a bundle MAC through asynchronous browser cryptography when present.
Future<Uint8List> authenticatedHmac(
  Uint8List key,
  Uint8List bytes, {
  CancellationToken? cancel,
}) => platform.sign(key, bytes, cancel: cancel);

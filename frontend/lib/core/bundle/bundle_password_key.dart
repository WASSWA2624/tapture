import 'dart:typed_data';

import 'package:tapture/core/concurrency/cancellation_token.dart';

import 'bundle_password_key_stub.dart'
    if (dart.library.io) 'bundle_password_key_io.dart'
    if (dart.library.js_interop) 'bundle_password_key_web.dart'
    as platform;

/// Derives a bundle key away from the UI thread, or through browser WebCrypto.
Future<Uint8List> bundlePasswordKey(
  String password,
  Uint8List salt,
  int iterations, {
  CancellationToken? cancel,
}) => platform.derive(password, salt, iterations, cancel: cancel);

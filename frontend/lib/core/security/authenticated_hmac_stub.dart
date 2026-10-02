import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';

/// Native byte callers run the complete envelope on a worker isolate.
Future<Uint8List> sign(
  Uint8List key,
  Uint8List bytes, {
  CancellationToken? cancel,
}) async {
  if (cancel?.isCancelled ?? false) {
    throw const CancelledFailure();
  }
  return Uint8List.fromList(Hmac(sha256, key).convert(bytes).bytes);
}

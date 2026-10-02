import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// RFC 8018 PBKDF2-HMAC-SHA256 using the approved standard HMAC implementation.
/// Native callers run this on a worker; [check] interrupts synchronous file
/// workers every 1,024 rounds so their own native handles can close in finally.
Uint8List bundlePbkdf2(
  String password,
  Uint8List salt,
  int iterations, {
  void Function()? check,
}) {
  if (iterations < 1) {
    throw ArgumentError.value(iterations, 'iterations');
  }
  check?.call();
  final Hmac hmac = Hmac(sha256, utf8.encode(password));
  List<int> round = hmac.convert(<int>[...salt, 0, 0, 0, 1]).bytes;
  final Uint8List key = Uint8List.fromList(round);
  for (int index = 1; index < iterations; index++) {
    if ((index & 1023) == 0) {
      check?.call();
    }
    round = hmac.convert(round).bytes;
    for (int byte = 0; byte < key.length; byte++) {
      key[byte] ^= round[byte];
    }
  }
  check?.call();
  return key;
}

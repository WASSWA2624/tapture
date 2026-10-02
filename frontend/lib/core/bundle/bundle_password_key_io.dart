import 'dart:typed_data';

import 'package:tapture/core/concurrency/isolate_runner.dart';

import 'bundle_pbkdf2.dart';

/// Executes the bounded work factor on the standard cancellable worker.
Future<Uint8List> derive(
  String password,
  Uint8List salt,
  int iterations, {
  CancellationToken? cancel,
}) async => (await runIsolate<(String, Uint8List, int), Uint8List>(_derive, (
  password,
  salt,
  iterations,
), cancel: cancel)).getOrThrow();

Uint8List _derive((String, Uint8List, int) input) =>
    bundlePbkdf2(input.$1, input.$2, input.$3);

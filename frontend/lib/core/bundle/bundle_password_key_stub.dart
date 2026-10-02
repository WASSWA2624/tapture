import 'dart:typed_data';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';

/// Refuses encryption when the host cannot supply a supported crypto runtime.
Future<Uint8List> derive(
  String password,
  Uint8List salt,
  int iterations, {
  CancellationToken? cancel,
}) async => throw StorageFailure(
  localizedMessage:
      Copy.messages.failurePasswordProtectionIsUnavailableOnThisDevice,
  localizedRecovery: Copy.messages.failureOpenThisPackageOnASupportedDevice,
);

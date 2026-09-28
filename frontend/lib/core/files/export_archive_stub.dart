import 'dart:typed_data';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'file_writer.dart';
import 'storage_root.dart';

/// Non-native callers select the bounded browser encoder in ExportArchive.
Future<Result<WrittenFile>> writeArchive({
  required StorageRoot storageRoot,
  required String target,
  required Map<String, String> sources,
  required Uint8List manifest,
  required CancellationToken cancel,
  void Function(double)? onProgress,
}) async => const FailureResult<WrittenFile>(
  StorageFailure(message: 'A native file system is unavailable.'),
);

import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'capture_staging.dart';

/// Neither a file system nor a browser: a take cannot be staged on disk.
Future<Result<CaptureStaging>> openCaptureStaging({
  required StorageRoot root,
  required FileWriter writer,
  required String relativePath,
}) async {
  return FailureResult<CaptureStaging>(
    ProviderFailure(
      kind: ProviderFailureKind.unavailable,
      localizedMessage: Copy.messages.audioRecorderUnavailable,
    ),
  );
}

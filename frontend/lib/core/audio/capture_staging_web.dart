import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/file_writer_web.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'blob_capture_staging.dart';
import 'capture_staging.dart';

/// A browser has no file to append to: the take is staged as chunks in the
/// project files' IndexedDB store, where [writer] also publishes it, capped
/// at `AppConstants.speechSession.webMaxSessionDuration`. [root] is a
/// device concern and is not read here.
Future<Result<CaptureStaging>> openCaptureStaging({
  required StorageRoot root,
  required FileWriter writer,
  required String relativePath,
}) async {
  final Result<BlobCaptureStaging> opened = await BlobCaptureStaging.open(
    store: projectFileStore(),
    writer: writer,
    relativePath: relativePath,
  );
  return opened.map((BlobCaptureStaging staging) => staging);
}

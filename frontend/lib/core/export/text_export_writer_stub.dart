import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'export_manifest.dart';
import 'export_request.dart';

/// Browser text output uses the bounded platform file store through the renderer.
Future<Result<Map<String, WrittenFile>>> writeText(
  StorageRoot root,
  ExportRequest request,
  String folder,
  CancellationToken cancel,
  void Function(double)? onProgress, {
  ExportManifest? manifest,
}) async => FailureResult<Map<String, WrittenFile>>(
  StorageFailure(
    localizedMessage:
        Copy.messages.failureStreamingTextExportNeedsNativeStorage,
  ),
);

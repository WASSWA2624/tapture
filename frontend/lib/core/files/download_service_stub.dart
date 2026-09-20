import 'dart:typed_data';

import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';

import 'download_service.dart';

/// Neither a file system nor a browser: every save reports a failure.
DownloadService platformDownloads() => const _NoDownloads();

final class _NoDownloads implements DownloadService {
  const _NoDownloads();

  @override
  String? get destination => null;

  @override
  bool get canOpenFolder => false;

  @override
  bool get canChooseLocation => false;

  @override
  Future<Result<String?>> saveAs({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    return FailureResult<String?>(downloadFailure(fileName));
  }

  @override
  Future<Result<void>> openFolder() async {
    return FailureResult<void>(openFolderFailure(Copy.downloadsTaptureFolder));
  }

  @override
  Future<Result<String?>> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    return FailureResult<String?>(downloadFailure(fileName));
  }

  @override
  bool get canOpenExternally => false;

  @override
  bool get canDownloadCopy => false;

  @override
  Future<Result<void>> openExternally({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    return FailureResult<void>(openExternallyFailure(fileName));
  }
}

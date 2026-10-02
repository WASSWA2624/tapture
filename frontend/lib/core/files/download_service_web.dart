import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'download_service.dart';

/// A browser download through a temporary object URL. A stored export is
/// read back from the project-file store it was written to.
DownloadService platformDownloads({StorageRoot? storageRoot}) {
  return _BrowserDownloads(
    FileReader(storageRoot: storageRoot ?? StorageRoot()),
  );
}

final class _BrowserDownloads implements DownloadService {
  const _BrowserDownloads(this._files);

  final FileReader _files;

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
  bool get canOpenExternally => false;

  @override
  bool get canDownloadCopy => true;

  @override
  bool get canShareToApps => false;

  @override
  Future<Result<void>> openExternally({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final Result<String?> saved = await save(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
    return saved.fold(
      FailureResult<void>.new,
      (String? _) => const Success<void>(null),
    );
  }

  @override
  Future<Result<String?>> save({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? subfolder,
  }) async {
    try {
      final _Blob blob = _Blob(
        <JSAny>[bytes.toJS].toJS,
        _BlobOptions(type: mimeType),
      );
      final String url = _createObjectUrl(blob);
      final _Element anchor = _document.createElement('a')
        ..href = url
        ..download = fileName;
      _document.body.append(anchor);
      anchor
        ..click()
        ..remove();
      // Revoking at once can cancel the download in some browsers, so the
      // URL is released once the browser has had time to take the bytes.
      Timer(AppConstants.userFeedback.objectUrlLifetime, () {
        _revokeObjectUrl(url);
      });
      return const Success<String?>(null);
    } on Object {
      return FailureResult<String?>(downloadFailure(fileName));
    }
  }

  // A browser keeps each export in its project-file store (task 076), so a
  // stored export downloads again from there.
  @override
  Future<Result<String?>> saveStored({
    required String relativePath,
    required String fileName,
    required String mimeType,
    String? subfolder,
  }) async {
    if (!isStoredExport(relativePath)) {
      return FailureResult<String?>(downloadFailure(fileName));
    }
    final Result<Uint8List> stored = await _files.read(relativePath);
    switch (stored) {
      case FailureResult<Uint8List>():
        return FailureResult<String?>(downloadFailure(fileName));
      case Success<Uint8List>(:final Uint8List value):
        return save(fileName: fileName, bytes: value, mimeType: mimeType);
    }
  }

  @override
  Future<Result<void>> openStoredExternally({
    required String relativePath,
    required String fileName,
    required String mimeType,
  }) async {
    final Result<String?> saved = await saveStored(
      relativePath: relativePath,
      fileName: fileName,
      mimeType: mimeType,
    );
    return saved.fold(
      (_) => FailureResult<void>(openExternallyFailure(fileName)),
      (String? _) => const Success<void>(null),
    );
  }
}

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external factory _Blob(JSArray<JSAny> parts, _BlobOptions options);
}

extension type _BlobOptions._(JSObject _) implements JSObject {
  external factory _BlobOptions({String type});
}

@JS('URL.createObjectURL')
external String _createObjectUrl(_Blob blob);

@JS('URL.revokeObjectURL')
external void _revokeObjectUrl(String url);

@JS('document')
external _Document get _document;

extension type _Document._(JSObject _) implements JSObject {
  external _Element createElement(String tag);
  external _Element get body;
}

extension type _Element._(JSObject _) implements JSObject {
  external set href(String value);
  external set download(String value);
  external void append(_Element child);
  external void click();
  external void remove();
}

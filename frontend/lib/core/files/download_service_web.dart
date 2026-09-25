import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';

import 'download_service.dart';

/// A browser download through a temporary object URL.
DownloadService platformDownloads() => const _BrowserDownloads();

final class _BrowserDownloads implements DownloadService {
  const _BrowserDownloads();

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

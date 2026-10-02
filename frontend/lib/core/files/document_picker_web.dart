import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'document_picker.dart';

/// The browser's file input. The chosen file is read into memory, so a file
/// larger than the caller's ceiling is refused before it is read.
DocumentPicker platformDocumentPicker() => const _WebDocumentPicker();

final class _WebDocumentPicker implements DocumentPicker {
  const _WebDocumentPicker();

  @override
  bool get canPick => true;

  @override
  Future<Result<PickedDocument>> pick({
    required List<String> extensions,
    required String mimeType,
    int? maxBytes,
  }) async {
    try {
      final _File? file = await _choose(extensions, mimeType);
      if (file == null) {
        return const FailureResult<PickedDocument>(CancelledFailure());
      }
      final int? ceiling = maxBytes;
      if (ceiling != null && file.size > ceiling) {
        return FailureResult<PickedDocument>(
          ValidationFailure(
            localizedMessage: Copy.messages.documentTooLarge(
              file.size,
              ceiling,
            ),
            localizedRecovery: Copy.messages.documentTooLargeRecovery,
          ),
        );
      }
      final JSArrayBuffer buffer = await file.arrayBuffer().toDart;
      return Success<PickedDocument>(
        PickedBytes(Uint8List.view(buffer.toDart), file.name),
      );
    } on Object {
      return FailureResult<PickedDocument>(
        StorageFailure(
          localizedMessage: Copy.messages.documentPickFailed,
          localizedRecovery: Copy.messages.tryAgain,
        ),
      );
    }
  }
}

/// Opens the browser's file chooser and completes with the chosen file, or
/// null when the operator closes it.
Future<_File?> _choose(List<String> extensions, String mimeType) {
  final Completer<_File?> done = Completer<_File?>();
  final _Input input = _document.createElement('input');
  input.type = 'file';
  input.accept = <String>[
    for (final String extension in extensions) '.$extension',
    mimeType,
  ].join(',');
  input.addEventListener(
    'change',
    ((JSAny _) {
      final _FileList? files = input.files;
      if (!done.isCompleted) {
        done.complete(
          files == null || files.length == 0 ? null : files.item(0),
        );
      }
    }).toJS,
  );
  input.addEventListener(
    'cancel',
    ((JSAny _) {
      if (!done.isCompleted) {
        done.complete(null);
      }
    }).toJS,
  );
  input.click();
  return done.future;
}

@JS('document')
external _Document get _document;

extension type _Document._(JSObject _) implements JSObject {
  external _Input createElement(String tag);
}

extension type _Input._(JSObject _) implements JSObject {
  external set type(String value);
  external set accept(String value);
  external _FileList? get files;
  external void click();
  external void addEventListener(String type, JSFunction listener);
}

extension type _FileList._(JSObject _) implements JSObject {
  external int get length;
  external _File? item(int index);
}

extension type _File._(JSObject _) implements JSObject {
  external String get name;
  external int get size;
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

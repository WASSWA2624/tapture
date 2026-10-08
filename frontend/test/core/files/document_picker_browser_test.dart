@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/files/document_picker_web.dart';

void main() {
  late JSFunction createElement;
  late _Input input;
  _File? selected;

  setUp(() {
    selected = null;
    createElement = _document.getProperty<JSFunction>('createElement'.toJS);
    _document.setProperty(
      'createElement'.toJS,
      ((JSString tag) {
        final JSObject element =
            createElement.callAsFunction(_document, tag)! as JSObject;
        if (tag.toDart == 'input') {
          input = _Input._(element);
          // Deliver actual DOM files/events without opening an unattended OS dialog.
          element.setProperty(
            'click'.toJS,
            (() {
              final _DataTransfer transfer = _DataTransfer();
              final _File? file = selected;
              if (file != null) transfer.items.add(file);
              input.files = transfer.files;
              input.dispatchEvent(_Event(file == null ? 'cancel' : 'change'));
            }).toJS,
          );
        }
        return element;
      }).toJS,
    );
  });
  tearDown(() => _document.setProperty('createElement'.toJS, createElement));

  test(
    'project picker uses one ZIP file and returns identical browser bytes',
    () async {
      final Uint8List bytes = Uint8List.fromList(<int>[80, 75, 3, 4, 5]);
      selected = _File(<JSAny>[bytes.toJS].toJS, 'site.zip'.toJS);
      final Result<PickedDocument> result = await platformDocumentPicker().pick(
        extensions: const <String>['zip'],
        mimeType: 'application/zip',
        maxBytes: 10,
      );
      expect(input.type, 'file');
      expect(input.accept, '.zip,application/zip');
      expect(input.multiple, isFalse);
      expect(input.webkitdirectory, isFalse);
      final PickedBytes document =
          (result as Success<PickedDocument>).value as PickedBytes;
      expect(document.name, 'site.zip');
      expect(document.bytes, bytes);
    },
  );

  test(
    'browser cancellation is a typed failure without a selected document',
    () async {
      final Result<PickedDocument> result = await platformDocumentPicker().pick(
        extensions: const <String>['zip'],
        mimeType: 'application/zip',
      );
      expect(
        (result as FailureResult<PickedDocument>).failure,
        isA<CancelledFailure>(),
      );
    },
  );

  test('browser checks size before reading the chosen file', () async {
    selected = _File(<JSAny>[Uint8List(11).toJS].toJS, 'large.zip'.toJS);
    final Result<PickedDocument> result = await platformDocumentPicker().pick(
      extensions: const <String>['zip'],
      mimeType: 'application/zip',
      maxBytes: 10,
    );
    expect(
      (result as FailureResult<PickedDocument>).failure,
      isA<ValidationFailure>(),
    );
  });

  test(
    'provider filter fallback returns evidence for importer validation',
    () async {
      selected = _File(<JSAny>['unrelated'.toJS].toJS, 'other.txt'.toJS);
      final Result<PickedDocument> result = await platformDocumentPicker().pick(
        extensions: const <String>['zip'],
        mimeType: 'application/zip',
      );
      expect((result as Success<PickedDocument>).value.name, 'other.txt');
    },
  );
}

@JS('document')
external JSObject get _document;

extension type _Input._(JSObject _) implements JSObject {
  external String get type;
  external String get accept;
  external bool get multiple;
  external bool get webkitdirectory;
  external set files(JSObject value);
  external bool dispatchEvent(_Event event);
}

@JS('DataTransfer')
extension type _DataTransfer._(JSObject _) implements JSObject {
  external factory _DataTransfer();
  external _TransferItems get items;
  external JSObject get files;
}

extension type _TransferItems._(JSObject _) implements JSObject {
  external void add(_File file);
}

@JS('File')
extension type _File._(JSObject _) implements JSObject {
  external factory _File(JSArray<JSAny> parts, JSString name);
}

@JS('Event')
extension type _Event._(JSObject _) implements JSObject {
  external factory _Event(String type);
}

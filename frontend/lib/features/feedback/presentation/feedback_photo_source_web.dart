import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'feedback_photo_source.dart';

/// A hidden file input: the library, or the camera when the browser offers it.
FeedbackPhotoSource platformPhotoSource() => const _BrowserPhotos();

final class _BrowserPhotos implements FeedbackPhotoSource {
  const _BrowserPhotos();

  @override
  Future<Result<List<Uint8List>>> pick({required bool camera}) async {
    final Completer<Result<List<Uint8List>>> done =
        Completer<Result<List<Uint8List>>>();
    final _Input input = _document.createElement('input') as _Input;
    input
      ..type = 'file'
      ..accept = 'image/*'
      ..multiple = !camera;
    if (camera) {
      input.capture = 'environment';
    }

    void finish(Result<List<Uint8List>> result) {
      if (!done.isCompleted) {
        done.complete(result);
      }
    }

    input.onchange = (JSAny _) {
      unawaited(
        _read(input).then(finish).catchError((Object _) {
          finish(
            const FailureResult<List<Uint8List>>(
              ValidationFailure(
                message: Copy.feedbackPhotoFailed,
                recoveryAction: 'Choose another photo or attach a screenshot.',
              ),
            ),
          );
        }),
      );
    }.toJS;
    _document.body.append(input);
    input.click();
    input.remove();
    Timer(const Duration(milliseconds: 400), () {
      if (!done.isCompleted && (input.files?.length ?? 0) == 0) {
        // A cancel does not fire change; treat a quiet picker as none chosen.
      }
    });
    return done.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () => const Success<List<Uint8List>>(<Uint8List>[]),
    );
  }
}

Future<Result<List<Uint8List>>> _read(_Input input) async {
  final _FileList? files = input.files;
  if (files == null || files.length == 0) {
    return const Success<List<Uint8List>>(<Uint8List>[]);
  }
  final List<Uint8List> images = <Uint8List>[];
  for (int index = 0; index < files.length; index++) {
    final _File? file = files.item(index);
    if (file == null) {
      continue;
    }
    final JSArrayBuffer buffer = await file.arrayBuffer().toDart;
    images.add(Uint8List.view(buffer.toDart));
  }
  return Success<List<Uint8List>>(images);
}

@JS('document')
external _Document get _document;

extension type _Document._(JSObject _) implements JSObject {
  external JSObject createElement(String tag);
  external _Element get body;
}

extension type _Element._(JSObject _) implements JSObject {
  external void append(JSObject child);
}

extension type _Input._(JSObject _) implements JSObject {
  external set type(String value);
  external set accept(String value);
  external set multiple(bool value);
  external set capture(String value);
  external set onchange(JSFunction value);
  external _FileList? get files;
  external void click();
  external void remove();
}

extension type _FileList._(JSObject _) implements JSObject {
  external int get length;
  external _File? item(int index);
}

extension type _File._(JSObject _) implements JSObject {
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

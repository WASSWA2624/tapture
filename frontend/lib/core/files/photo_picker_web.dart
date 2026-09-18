import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/result.dart';

import 'photo_picker.dart';

/// Library photos through the plugin; a webcam still through getUserMedia,
/// never the file-input fallback desktop Chrome treats as camera.
PhotoPicker platformPhotoPicker() => _WebPhotoPicker(ImagePicker());

final class _WebPhotoPicker implements PhotoPicker {
  _WebPhotoPicker(this._picker);

  final ImagePicker _picker;

  @override
  bool get canTakePhoto => PhotoPicker.cameraSessionAvailable(
    pluginSupportsCamera: _picker.supportsImageSource(ImageSource.camera),
    cameraWouldBrowse: !_hasGetUserMedia,
  );

  @override
  Future<Result<List<Uint8List>>> choose({
    required int limit,
    required int longEdge,
  }) {
    final double edge = longEdge.toDouble();
    return readPickedPhotos(
      () => _picker.pickMultiImage(
        maxWidth: edge,
        maxHeight: edge,
        limit: limit,
        requestFullMetadata: false,
      ),
    );
  }

  @override
  Future<Result<List<Uint8List>>> take({required int longEdge}) async {
    final _MediaDevices? devices = _navigator.mediaDevices;
    if (devices == null) {
      return FailureResult<List<Uint8List>>(
        photoPickerFailure(const _NamedError('NotFoundError')),
      );
    }
    _MediaStream? stream;
    try {
      stream = await devices
          .getUserMedia(_GumConstraints(video: true, audio: false))
          .toDart;
      final Uint8List bytes = await _snapshot(stream, longEdge);
      return Success<List<Uint8List>>(<Uint8List>[bytes]);
    } on Object catch (error) {
      return FailureResult<List<Uint8List>>(photoPickerFailure(error));
    } finally {
      stream?.stop();
    }
  }
}

bool get _hasGetUserMedia {
  try {
    return _navigator.mediaDevices != null;
  } on Object {
    return false;
  }
}

Future<Uint8List> _snapshot(_MediaStream stream, int longEdge) async {
  final _Video video = _Video._(_document.createElement('video'));
  video
    ..muted = true
    ..autoplay = true
    ..srcObject = stream
    ..setAttribute('playsinline', 'true');
  video.style
    ..position = 'fixed'
    ..width = '1px'
    ..height = '1px'
    ..opacity = '0'
    ..pointerEvents = 'none';
  _document.body.append(video);
  try {
    await video.play().toDart;
    await _frameReady(video);
    final int sourceWidth = video.videoWidth;
    final int sourceHeight = video.videoHeight;
    if (sourceWidth <= 0 || sourceHeight <= 0) {
      throw const _NamedError('NotFoundError');
    }
    final int longest = sourceWidth > sourceHeight ? sourceWidth : sourceHeight;
    final double scale = longest > longEdge ? longEdge / longest : 1;
    final int width = (sourceWidth * scale).round().clamp(1, longEdge);
    final int height = (sourceHeight * scale).round().clamp(1, longEdge);
    final _Canvas canvas = _Canvas._(_document.createElement('canvas'))
      ..width = width
      ..height = height;
    canvas.context.drawImage(video, 0, 0, width, height);
    final String dataUrl = canvas.toDataURL(
      'image/jpeg',
      AppConstants.images.quality / 100,
    );
    final int comma = dataUrl.indexOf(',');
    if (comma < 0) {
      throw const _NamedError('EncodingError');
    }
    return Uint8List.fromList(base64Decode(dataUrl.substring(comma + 1)));
  } finally {
    video
      ..srcObject = null
      ..remove();
  }
}

Future<void> _frameReady(_Video video) async {
  if (video.videoWidth > 0) {
    return;
  }
  final Completer<void> ready = Completer<void>();
  video.addEventListener(
    'loadeddata',
    (JSAny _) {
      if (!ready.isCompleted) {
        ready.complete();
      }
    }.toJS,
  );
  await ready.future.timeout(
    AppConstants.userFeedback.cameraReady,
    onTimeout: () {},
  );
}

final class _NamedError implements Exception {
  const _NamedError(this.name);

  final String name;

  @override
  String toString() => name;
}

@JS('navigator')
external _Navigator get _navigator;

extension type _Navigator._(JSObject _) implements JSObject {
  external _MediaDevices? get mediaDevices;
}

extension type _MediaDevices._(JSObject _) implements JSObject {
  external JSPromise<_MediaStream> getUserMedia(_GumConstraints constraints);
}

extension type _GumConstraints._(JSObject _) implements JSObject {
  external factory _GumConstraints({bool video, bool audio});
}

extension type _MediaStream._(JSObject _) implements JSObject {
  external JSArray<_MediaStreamTrack> getTracks();

  void stop() {
    for (final _MediaStreamTrack track in getTracks().toDart) {
      track.stop();
    }
  }
}

extension type _MediaStreamTrack._(JSObject _) implements JSObject {
  external void stop();
}

@JS('document')
external _Document get _document;

extension type _Document._(JSObject _) implements JSObject {
  external JSObject createElement(String tag);
  external _Element get body;
}

extension type _Element._(JSObject _) implements JSObject {
  external _CssStyle get style;
  external void append(JSObject child);
  external void remove();
  external void setAttribute(String name, String value);
}

extension type _CssStyle._(JSObject _) implements JSObject {
  external set position(String value);
  external set width(String value);
  external set height(String value);
  external set opacity(String value);
  external set pointerEvents(String value);
}

extension type _Video._(JSObject _) implements _Element {
  external set muted(bool value);
  external set autoplay(bool value);
  external set srcObject(JSObject? stream);
  external int get videoWidth;
  external int get videoHeight;
  external JSPromise<JSAny?> play();
  external void addEventListener(String type, JSFunction listener);
}

extension type _Canvas._(JSObject _) implements JSObject {
  external set width(int value);
  external set height(int value);
  @JS('getContext')
  external _Context2D? _getContext(String id);
  external String toDataURL(String type, [num quality]);

  _Context2D get context {
    final _Context2D? current = _getContext('2d');
    if (current == null) {
      throw const _NamedError('EncodingError');
    }
    return current;
  }
}

extension type _Context2D._(JSObject _) implements JSObject {
  external void drawImage(JSObject image, num dx, num dy, num dw, num dh);
}

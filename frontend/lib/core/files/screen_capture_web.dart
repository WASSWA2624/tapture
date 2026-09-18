import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/result.dart';

import 'screen_capture.dart';

/// A still of another tab or OS window through getDisplayMedia, then the
/// stream is dropped. Audio is never requested.
ScreenCapture platformScreenCapture() => const _BrowserScreenCapture();

final class _BrowserScreenCapture implements ScreenCapture {
  const _BrowserScreenCapture();

  @override
  bool get canCapture {
    try {
      return _navigator.mediaDevices != null && _getDisplayMedia != null;
    } on Object {
      return false;
    }
  }

  @override
  Future<Result<Uint8List>> capture({required int longEdge}) async {
    final _MediaDevices? devices = _navigator.mediaDevices;
    if (devices == null || _getDisplayMedia == null) {
      return Success<Uint8List>(Uint8List(0));
    }
    _MediaStream? stream;
    try {
      stream = await devices
          .getDisplayMedia(_DisplayConstraints(video: true, audio: false))
          .toDart;
      final Uint8List bytes = await _snapshot(stream, longEdge);
      return Success<Uint8List>(bytes);
    } on Object catch (error) {
      if (screenCaptureCancelled(error)) {
        return Success<Uint8List>(Uint8List(0));
      }
      return FailureResult<Uint8List>(screenCaptureFailure(error));
    } finally {
      stream?.stop();
    }
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
    final String dataUrl = canvas.toDataURL('image/png');
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

@JS('navigator.mediaDevices.getDisplayMedia')
external JSFunction? get _getDisplayMedia;

extension type _Navigator._(JSObject _) implements JSObject {
  external _MediaDevices? get mediaDevices;
}

extension type _MediaDevices._(JSObject _) implements JSObject {
  external JSPromise<_MediaStream> getDisplayMedia(
    _DisplayConstraints constraints,
  );
}

extension type _DisplayConstraints._(JSObject _) implements JSObject {
  external factory _DisplayConstraints({bool video, bool audio});
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
  external String toDataURL(String type);

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

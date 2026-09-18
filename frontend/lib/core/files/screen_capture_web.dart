import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/result.dart';

import 'screen_capture.dart';

/// A still of another tab or OS window through getDisplayMedia. The
/// stream and hidden video stay until [ScreenCapture.stop]. Audio is
/// never requested.
ScreenCapture platformScreenCapture() => _BrowserScreenCapture();

final class _BrowserScreenCapture implements ScreenCapture {
  _MediaStream? _stream;
  _Video? _video;
  _MediaStreamTrack? _track;
  JSFunction? _endedListener;
  bool _sharing = false;
  final StreamController<void> _ended = StreamController<void>.broadcast();

  @override
  bool get canCapture {
    try {
      return _navigator.mediaDevices != null && _getDisplayMedia != null;
    } on Object {
      return false;
    }
  }

  @override
  bool get isSharing => _sharing;

  @override
  Stream<void> get ended => _ended.stream;

  @override
  Future<Result<bool>> start() async {
    if (_sharing) {
      return const Success<bool>(true);
    }
    final _MediaDevices? devices = _navigator.mediaDevices;
    if (devices == null || _getDisplayMedia == null) {
      return const Success<bool>(false);
    }
    try {
      final _CaptureController? controller = _focusController();
      final _MediaStream stream =
          await (controller == null
                  ? devices.getDisplayMedia(
                      _DisplayConstraints(video: true, audio: false),
                    )
                  : devices.getDisplayMedia(
                      _DisplayConstraints(
                        video: true,
                        audio: false,
                        controller: controller,
                      ),
                    ))
              .toDart;
      final _Video video = _attachVideo(stream);
      try {
        await video.play().toDart.timeout(
          AppConstants.userFeedback.cameraReady,
        );
        await _frameReady(video);
        if (video.videoWidth <= 0 || video.videoHeight <= 0) {
          throw const _NamedError('NotFoundError');
        }
      } on Object {
        video
          ..srcObject = null
          ..remove();
        stream.stop();
        rethrow;
      }
      _stream = stream;
      _video = video;
      _watch(stream);
      _sharing = true;
      return const Success<bool>(true);
    } on Object catch (error) {
      if (screenCaptureCancelled(error)) {
        return const Success<bool>(false);
      }
      return FailureResult<bool>(screenCaptureFailure(error));
    }
  }

  @override
  Future<Result<Uint8List>> still({required int longEdge}) async {
    final _Video? video = _video;
    if (!_sharing || video == null) {
      return Success<Uint8List>(Uint8List(0));
    }
    try {
      return Success<Uint8List>(await _encodeFrame(video, longEdge));
    } on Object catch (error) {
      return FailureResult<Uint8List>(screenCaptureFailure(error));
    }
  }

  @override
  void stop() {
    _release(announce: _sharing);
  }

  void _watch(_MediaStream stream) {
    final List<_MediaStreamTrack> tracks = stream.getTracks().toDart;
    _MediaStreamTrack? track;
    for (final _MediaStreamTrack candidate in tracks) {
      if (candidate.kind == 'video') {
        track = candidate;
        break;
      }
    }
    if (track == null && tracks.isNotEmpty) {
      track = tracks.first;
    }
    if (track == null) {
      return;
    }
    _track = track;
    _endedListener = ((JSAny _) {
      _release(announce: true);
    }).toJS;
    track.addEventListener('ended', _endedListener!);
  }

  void _release({required bool announce}) {
    final bool shouldAnnounce = announce && _sharing;
    _sharing = false;
    final JSFunction? listener = _endedListener;
    final _MediaStreamTrack? track = _track;
    if (listener != null && track != null) {
      track.removeEventListener('ended', listener);
    }
    _endedListener = null;
    _track = null;
    final _MediaStream? stream = _stream;
    _stream = null;
    stream?.stop();
    final _Video? video = _video;
    _video = null;
    if (video != null) {
      video
        ..srcObject = null
        ..remove();
    }
    if (shouldAnnounce) {
      _ended.add(null);
    }
  }
}

_CaptureController? _focusController() {
  try {
    if (_captureControllerCtor == null) {
      return null;
    }
    return _CaptureController()..setFocusBehavior('no-focus-change');
  } on Object {
    return null;
  }
}

_Video _attachVideo(_MediaStream stream) {
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
  return video;
}

Future<Uint8List> _encodeFrame(_Video video, int longEdge) async {
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

@JS('CaptureController')
external JSFunction? get _captureControllerCtor;

@JS('CaptureController')
extension type _CaptureController._(JSObject _) implements JSObject {
  external factory _CaptureController();
  external void setFocusBehavior(String behavior);
}

extension type _Navigator._(JSObject _) implements JSObject {
  external _MediaDevices? get mediaDevices;
}

extension type _MediaDevices._(JSObject _) implements JSObject {
  external JSPromise<_MediaStream> getDisplayMedia(
    _DisplayConstraints constraints,
  );
}

extension type _DisplayConstraints._(JSObject _) implements JSObject {
  external factory _DisplayConstraints({
    bool video,
    bool audio,
    JSObject? controller,
  });
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
  external String get kind;
  external void stop();
  external void addEventListener(String type, JSFunction listener);
  external void removeEventListener(String type, JSFunction listener);
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

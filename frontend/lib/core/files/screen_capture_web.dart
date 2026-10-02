import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/result.dart';

import 'screen_capture.dart';
import 'web_media.dart';

/// A still of another tab or OS window through getDisplayMedia. The
/// stream and hidden video stay until [ScreenCapture.stop]. Audio is
/// never requested.
ScreenCapture platformScreenCapture() => _BrowserScreenCapture();

final class _BrowserScreenCapture implements ScreenCapture {
  WebMediaStream? _stream;
  WebVideo? _video;
  WebMediaStreamTrack? _track;
  JSFunction? _endedListener;
  bool _sharing = false;
  final StreamController<void> _ended = StreamController<void>.broadcast();

  @override
  bool get canCapture {
    try {
      return webNavigator.mediaDevices != null && _getDisplayMedia != null;
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
    final WebMediaDevices? devices = webNavigator.mediaDevices;
    if (devices == null || _getDisplayMedia == null) {
      return const Success<bool>(false);
    }
    try {
      final _CaptureController? controller = _focusController();
      final WebMediaStream stream =
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
      final WebVideo video = WebMedia.attachHiddenVideo(stream);
      try {
        await video.play().toDart.timeout(
          AppConstants.userFeedback.cameraReady,
        );
        await WebMedia.frameReady(video);
        if (video.videoWidth <= 0 || video.videoHeight <= 0) {
          throw WebMedia.namedError('NotFoundError');
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
    final WebVideo? video = _video;
    if (!_sharing || video == null) {
      return Success<Uint8List>(Uint8List(0));
    }
    try {
      return Success<Uint8List>(
        await WebMedia.encodeFrame(
          video,
          longEdge: longEdge,
          type: 'image/png',
        ),
      );
    } on Object catch (error) {
      return FailureResult<Uint8List>(screenCaptureFailure(error));
    }
  }

  @override
  void stop() {
    _release(announce: _sharing);
  }

  void _watch(WebMediaStream stream) {
    final List<WebMediaStreamTrack> tracks = stream.getTracks().toDart;
    WebMediaStreamTrack? track;
    for (final WebMediaStreamTrack candidate in tracks) {
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
    final WebMediaStreamTrack? track = _track;
    if (listener != null && track != null) {
      track.removeEventListener('ended', listener);
    }
    _endedListener = null;
    _track = null;
    final WebMediaStream? stream = _stream;
    _stream = null;
    stream?.stop();
    final WebVideo? video = _video;
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

@JS('navigator.mediaDevices.getDisplayMedia')
external JSFunction? get _getDisplayMedia;

@JS('CaptureController')
external JSFunction? get _captureControllerCtor;

@JS('CaptureController')
extension type _CaptureController._(JSObject _) implements JSObject {
  external factory _CaptureController();
  external void setFocusBehavior(String behavior);
}

extension type _DisplayConstraints._(JSObject _) implements JSObject {
  external factory _DisplayConstraints({
    bool video,
    bool audio,
    JSObject? controller,
  });
}

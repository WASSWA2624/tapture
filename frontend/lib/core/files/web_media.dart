import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';

/// Browser media the web photo picker and the web screen capture share: a
/// hidden video for a media stream, the wait for its first frame, and one
/// frame encoded through a canvas. The one copy of this interop in `core/`
/// (FE-CONS-01); only `*_web.dart` files import it.
abstract final class WebMedia {
  /// Plays [stream] in a hidden, muted, 1px video attached to the page, so a
  /// frame can be read from it. The caller removes it when done.
  static WebVideo attachHiddenVideo(WebMediaStream stream) {
    final WebVideo video = WebVideo._(webDocument.createElement('video'));
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
    webDocument.body.append(video);
    return video;
  }

  /// Completes once [video] has a frame, or after the camera-ready wait.
  static Future<void> frameReady(WebVideo video) async {
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

  /// [video]'s current frame, scaled so neither side passes [longEdge] and
  /// encoded as [type] (at [quality] where the type takes one).
  static Future<Uint8List> encodeFrame(
    WebVideo video, {
    required int longEdge,
    required String type,
    num? quality,
  }) async {
    await frameReady(video);
    final int sourceWidth = video.videoWidth;
    final int sourceHeight = video.videoHeight;
    if (sourceWidth <= 0 || sourceHeight <= 0) {
      throw const _NamedError('NotFoundError');
    }
    final int longest = sourceWidth > sourceHeight ? sourceWidth : sourceHeight;
    final double scale = longest > longEdge ? longEdge / longest : 1;
    final int width = (sourceWidth * scale).round().clamp(1, longEdge);
    final int height = (sourceHeight * scale).round().clamp(1, longEdge);
    final _Canvas canvas = _Canvas._(webDocument.createElement('canvas'))
      ..width = width
      ..height = height;
    canvas.context.drawImage(video, 0, 0, width, height);
    final String dataUrl = quality == null
        ? canvas.toDataURL(type)
        : canvas.toDataURL(type, quality);
    final int comma = dataUrl.indexOf(',');
    if (comma < 0) {
      throw const _NamedError('EncodingError');
    }
    return Uint8List.fromList(base64Decode(dataUrl.substring(comma + 1)));
  }

  /// An error that reads as the browser's own [name] (`NotFoundError`,
  /// `EncodingError`), which the failure mapping recognises.
  static Exception namedError(String name) => _NamedError(name);
}

final class _NamedError implements Exception {
  const _NamedError(this.name);

  final String name;

  @override
  String toString() => name;
}

/// The page's `navigator`.
@JS('navigator')
external WebNavigator get webNavigator;

/// The page's `document`.
@JS('document')
external WebDocument get webDocument;

/// `navigator`, as far as media needs it.
extension type WebNavigator._(JSObject _) implements JSObject {
  /// The camera and screen source, or null where the browser has none.
  external WebMediaDevices? get mediaDevices;
}

/// `navigator.mediaDevices`.
extension type WebMediaDevices._(JSObject _) implements JSObject {
  /// A camera stream for [constraints].
  external JSPromise<WebMediaStream> getUserMedia(JSObject constraints);

  /// A tab, window or screen stream for [constraints].
  external JSPromise<WebMediaStream> getDisplayMedia(JSObject constraints);
}

/// A live media stream.
extension type WebMediaStream._(JSObject _) implements JSObject {
  /// Its tracks.
  external JSArray<WebMediaStreamTrack> getTracks();

  /// Stops every track, releasing the camera or the shared screen.
  void stop() {
    for (final WebMediaStreamTrack track in getTracks().toDart) {
      track.stop();
    }
  }
}

/// One track of a [WebMediaStream].
extension type WebMediaStreamTrack._(JSObject _) implements JSObject {
  /// `video` or `audio`.
  external String get kind;

  /// Stops the track.
  external void stop();

  /// Listens for [type], such as `ended`.
  external void addEventListener(String type, JSFunction listener);

  /// Stops listening for [type].
  external void removeEventListener(String type, JSFunction listener);
}

/// `document`, as far as media needs it.
extension type WebDocument._(JSObject _) implements JSObject {
  /// A new element named [tag].
  external JSObject createElement(String tag);

  /// The page body.
  external WebElement get body;
}

/// A page element.
extension type WebElement._(JSObject _) implements JSObject {
  /// Its inline style.
  external WebCssStyle get style;

  /// Adds [child] as its last child.
  external void append(JSObject child);

  /// Takes it off the page.
  external void remove();

  /// Sets the attribute [name].
  external void setAttribute(String name, String value);
}

/// An element's inline style.
extension type WebCssStyle._(JSObject _) implements JSObject {
  /// CSS `position`.
  external set position(String value);

  /// CSS `width`.
  external set width(String value);

  /// CSS `height`.
  external set height(String value);

  /// CSS `opacity`.
  external set opacity(String value);

  /// CSS `pointer-events`.
  external set pointerEvents(String value);
}

/// A `<video>` element playing a stream.
extension type WebVideo._(JSObject _) implements WebElement {
  /// Mutes it.
  external set muted(bool value);

  /// Plays as soon as it can.
  external set autoplay(bool value);

  /// The stream it plays, or null to release it.
  external set srcObject(JSObject? stream);

  /// The frame width, zero before the first frame.
  external int get videoWidth;

  /// The frame height, zero before the first frame.
  external int get videoHeight;

  /// Starts playback.
  external JSPromise<JSAny?> play();

  /// Listens for [type], such as `loadeddata`.
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

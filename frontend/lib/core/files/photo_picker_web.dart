import 'dart:js_interop';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/result.dart';

import 'photo_picker.dart';
import 'web_media.dart';

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
    return readPickedPhotos(
      () => _picker.pickMultiImage(limit: limit, requestFullMetadata: false),
    );
  }

  @override
  Future<Result<List<Uint8List>>> take({required int longEdge}) async {
    final WebMediaDevices? devices = webNavigator.mediaDevices;
    if (devices == null) {
      return FailureResult<List<Uint8List>>(
        photoPickerFailure(WebMedia.namedError('NotFoundError')),
      );
    }
    WebMediaStream? stream;
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
    return webNavigator.mediaDevices != null;
  } on Object {
    return false;
  }
}

Future<Uint8List> _snapshot(WebMediaStream stream, int longEdge) async {
  final WebVideo video = WebMedia.attachHiddenVideo(stream);
  try {
    await video.play().toDart;
    return await WebMedia.encodeFrame(
      video,
      longEdge: longEdge,
      type: 'image/jpeg',
      quality: AppConstants.images.quality / 100,
    );
  } finally {
    video
      ..srcObject = null
      ..remove();
  }
}

extension type _GumConstraints._(JSObject _) implements JSObject {
  external factory _GumConstraints({bool video, bool audio});
}

import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:tapture/core/errors/result.dart';

import 'photo_picker.dart';

/// The plugin picker: a real camera session on Android and iOS, the library
/// alone on desktop.
PhotoPicker platformPhotoPicker() => _PluginPhotoPicker(ImagePicker());

final class _PluginPhotoPicker implements PhotoPicker {
  _PluginPhotoPicker(this._picker);

  final ImagePicker _picker;

  @override
  bool get canTakePhoto => PhotoPicker.cameraSessionAvailable(
    pluginSupportsCamera: _picker.supportsImageSource(ImageSource.camera),
    cameraWouldBrowse: false,
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
  Future<Result<List<Uint8List>>> take({required int longEdge}) {
    final double edge = longEdge.toDouble();
    return readPickedPhotos(() async {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: edge,
        maxHeight: edge,
        requestFullMetadata: false,
      );
      return <XFile>[?photo];
    });
  }
}


import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// Photos from the device camera or library. The picker plugin is reached
/// only here (FE-STR-11); tests use [PhotoPicker.fake].
abstract interface class PhotoPicker {
  /// The platform picker: camera and library on Android, iOS and the web,
  /// the library alone on desktop.
  factory PhotoPicker() => _PluginPhotoPicker(ImagePicker());

  /// A stand-in that hands back [photos] on every pick, or [failure].
  const factory PhotoPicker.fake({
    List<Uint8List> photos,
    Failure? failure,
    bool canTakePhoto,
  }) = _FakePhotoPicker;

  /// Whether this device has a camera the picker can open.
  bool get canTakePhoto;

  /// Up to [limit] photos from the library, scaled so neither side passes
  /// [longEdge] where the platform can. Empty when the operator cancels.
  Future<Result<List<Uint8List>>> choose({
    required int limit,
    required int longEdge,
  });

  /// One photo from the camera, or empty when the operator cancels.
  Future<Result<List<Uint8List>>> take({required int longEdge});
}

final class _PluginPhotoPicker implements PhotoPicker {
  _PluginPhotoPicker(this._picker);

  final ImagePicker _picker;

  @override
  bool get canTakePhoto => _picker.supportsImageSource(ImageSource.camera);

  @override
  Future<Result<List<Uint8List>>> choose({
    required int limit,
    required int longEdge,
  }) {
    final double edge = longEdge.toDouble();
    return _read(
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
    return _read(() async {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: edge,
        maxHeight: edge,
        requestFullMetadata: false,
      );
      return <XFile>[?photo];
    });
  }

  Future<Result<List<Uint8List>>> _read(
    Future<List<XFile>> Function() pick,
  ) async {
    try {
      final List<XFile> files = await pick();
      return Success<List<Uint8List>>(<Uint8List>[
        for (final XFile file in files) await file.readAsBytes(),
      ]);
    } on PlatformException catch (error) {
      return FailureResult<List<Uint8List>>(_failureFor(error.code));
    } on Object {
      return const FailureResult<List<Uint8List>>(
        ProviderFailure(message: Copy.photoPickFailed),
      );
    }
  }
}

/// Maps the plugin's error codes onto catalogue copy.
Failure _failureFor(String code) {
  if (code.contains('access_denied')) {
    return const PermissionFailure(message: Copy.photoNoAccess);
  }
  if (code == 'no_available_camera') {
    return const ProviderFailure(message: Copy.photoNoCamera);
  }
  return const ProviderFailure(message: Copy.photoPickFailed);
}

final class _FakePhotoPicker implements PhotoPicker {
  const _FakePhotoPicker({
    this.photos = const <Uint8List>[],
    this.failure,
    this.canTakePhoto = true,
  });

  final List<Uint8List> photos;
  final Failure? failure;

  @override
  final bool canTakePhoto;

  @override
  Future<Result<List<Uint8List>>> choose({
    required int limit,
    required int longEdge,
  }) async {
    return _result(photos.take(limit).toList());
  }

  @override
  Future<Result<List<Uint8List>>> take({required int longEdge}) async {
    return _result(photos.take(1).toList());
  }

  Result<List<Uint8List>> _result(List<Uint8List> picked) {
    final Failure? failure = this.failure;
    return failure == null
        ? Success<List<Uint8List>>(picked)
        : FailureResult<List<Uint8List>>(failure);
  }
}

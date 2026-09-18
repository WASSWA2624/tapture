import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'photo_picker_stub.dart'
    if (dart.library.io) 'photo_picker_io.dart'
    if (dart.library.js_interop) 'photo_picker_web.dart'
    as platform;

/// Photos from the device camera or library. The picker plugin and the
/// browser camera are reached only here (FE-STR-11); tests use
/// [PhotoPicker.fake].
abstract interface class PhotoPicker {
  /// The platform picker: a camera session where the OS or browser can open
  /// one, and the library everywhere. Camera never falls through to a file
  /// browser.
  factory PhotoPicker() => platform.platformPhotoPicker();

  /// A stand-in that hands back [photos] on every pick, or [failure].
  const factory PhotoPicker.fake({
    List<Uint8List> photos,
    Failure? failure,
    bool canTakePhoto,
  }) = _FakePhotoPicker;

  /// Whether the camera control should show.
  ///
  /// A plugin may claim camera support while the platform would only open a
  /// file browser; that is not a camera session.
  static bool cameraSessionAvailable({
    required bool pluginSupportsCamera,
    required bool cameraWouldBrowse,
  }) {
    return pluginSupportsCamera && !cameraWouldBrowse;
  }

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

/// Reads [pick] into bytes, mapping plugin errors to catalogue copy.
Future<Result<List<Uint8List>>> readPickedPhotos(
  Future<List<XFile>> Function() pick,
) async {
  try {
    final List<XFile> files = await pick();
    return Success<List<Uint8List>>(<Uint8List>[
      for (final XFile file in files) await file.readAsBytes(),
    ]);
  } on Object catch (error) {
    return FailureResult<List<Uint8List>>(photoPickerFailure(error));
  }
}

/// Maps a picker or camera error onto catalogue copy.
Failure photoPickerFailure(Object error) {
  if (error is PlatformException) {
    final String code = error.code;
    if (code.contains('access_denied')) {
      return const PermissionFailure(message: Copy.photoNoAccess);
    }
    if (code == 'no_available_camera') {
      return const ProviderFailure(message: Copy.photoNoCamera);
    }
    return const ProviderFailure(message: Copy.photoPickFailed);
  }
  final String text = error.toString().toLowerCase();
  if (text.contains('notallowed') ||
      text.contains('permissiondenied') ||
      text.contains('securityerror')) {
    return const PermissionFailure(message: Copy.photoNoAccess);
  }
  if (text.contains('notfound') ||
      text.contains('devicesnotfound') ||
      text.contains('overconstrained') ||
      text.contains('no_available_camera')) {
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

import 'dart:typed_data';

import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'screen_capture_stub.dart'
    if (dart.library.io) 'screen_capture_io.dart'
    if (dart.library.js_interop) 'screen_capture_web.dart'
    as platform;

/// A still of another window or OS surface the operator picks. The browser
/// display picker is reached only here (FE-STR-11); tests use
/// [ScreenCapture.fake]. Native Android, iOS and desktop hide the control.
abstract interface class ScreenCapture {
  /// The service for this platform.
  factory ScreenCapture() => platform.platformScreenCapture();

  /// A stand-in that hands back [frame] on capture, or [failure]. Empty
  /// [frame] is a cancel. Tests never open a display picker (FE-TEST-03).
  const factory ScreenCapture.fake({
    Uint8List? frame,
    Failure? failure,
    bool canCapture,
  }) = _FakeScreenCapture;

  /// Whether the Add another window control should show.
  bool get canCapture;

  /// One PNG of the chosen window, scaled so neither side passes
  /// [longEdge] where the platform can. Empty bytes when the operator
  /// cancels.
  Future<Result<Uint8List>> capture({required int longEdge});
}

/// Maps a display-picker error onto catalogue copy.
Failure screenCaptureFailure(Object error) {
  final String text = error.toString().toLowerCase();
  if (text.contains('notallowed') ||
      text.contains('permissiondenied') ||
      text.contains('securityerror')) {
    return const PermissionFailure(message: Copy.displayNoAccess);
  }
  return const ProviderFailure(message: Copy.displayCaptureFailed);
}

/// Whether a rejected picker is a cancel rather than a refusal.
bool screenCaptureCancelled(Object error) {
  return error.toString().toLowerCase().contains('aborterror');
}

final class _FakeScreenCapture implements ScreenCapture {
  const _FakeScreenCapture({this.frame, this.failure, this.canCapture = false});

  final Uint8List? frame;
  final Failure? failure;

  @override
  final bool canCapture;

  @override
  Future<Result<Uint8List>> capture({required int longEdge}) async {
    final Failure? failure = this.failure;
    if (failure != null) {
      return FailureResult<Uint8List>(failure);
    }
    final Uint8List bytes = frame ?? Uint8List(0);
    return Success<Uint8List>(bytes);
  }
}

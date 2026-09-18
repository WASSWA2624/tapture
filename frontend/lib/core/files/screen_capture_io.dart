import 'dart:typed_data';

import 'package:tapture/core/errors/result.dart';

import 'screen_capture.dart';

/// Native Android, iOS and desktop cannot share another process's pixels
/// without a plugin this task does not add.
ScreenCapture platformScreenCapture() => const _NoScreenCapture();

final class _NoScreenCapture implements ScreenCapture {
  const _NoScreenCapture();

  @override
  bool get canCapture => false;

  @override
  Future<Result<Uint8List>> capture({required int longEdge}) async {
    return Success<Uint8List>(Uint8List(0));
  }
}

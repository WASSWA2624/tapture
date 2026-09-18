import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/screen_capture.dart';

void main() {
  final Uint8List frame = Uint8List.fromList(<int>[1, 2, 3]);

  test('the fake hands back one frame', () async {
    final ScreenCapture capture = ScreenCapture.fake(
      canCapture: true,
      frame: frame,
    );
    final Result<Uint8List> still = await capture.capture(longEdge: 100);
    expect((still as Success<Uint8List>).value, frame);
  });

  test('an empty frame is a cancel', () async {
    const ScreenCapture capture = ScreenCapture.fake(canCapture: true);
    final Result<Uint8List> still = await capture.capture(longEdge: 100);
    expect((still as Success<Uint8List>).value, isEmpty);
  });

  test('a refusal comes back as a failure with catalogue copy', () async {
    const ScreenCapture capture = ScreenCapture.fake(
      canCapture: true,
      failure: PermissionFailure(message: Copy.displayNoAccess),
    );
    final Result<Uint8List> still = await capture.capture(longEdge: 100);
    expect(
      (still as FailureResult<Uint8List>).failure.message,
      Copy.displayNoAccess,
    );
  });

  test('a device that cannot share a display says so', () {
    expect(const ScreenCapture.fake().canCapture, isFalse);
  });

  test('native capture is hidden', () {
    expect(ScreenCapture().canCapture, isFalse);
  });

  test('a refused picker maps onto catalogue copy', () {
    expect(
      screenCaptureFailure(Exception('NotAllowedError')).message,
      Copy.displayNoAccess,
    );
    expect(
      screenCaptureFailure(Exception('EncodingError')).message,
      Copy.displayCaptureFailed,
    );
    expect(screenCaptureCancelled(Exception('AbortError')), isTrue);
  });

  test('the web capture is wired through a conditional import', () {
    final String source = File(
      'lib/core/files/screen_capture.dart',
    ).readAsStringSync();
    expect(
      source.contains("if (dart.library.js_interop) 'screen_capture_web.dart'"),
      isTrue,
    );
    expect(File('lib/core/files/screen_capture_web.dart').existsSync(), isTrue);
    expect(File('lib/core/files/screen_capture_io.dart').existsSync(), isTrue);
    final String web = File(
      'lib/core/files/screen_capture_web.dart',
    ).readAsStringSync();
    expect(web.contains('getDisplayMedia'), isTrue);
    expect(web.contains('audio: false'), isTrue);
    expect(web.contains('stream?.stop()'), isTrue);
    expect(
      File('lib/main.dart').readAsStringSync().contains(
        'feedbackScreenCaptureProvider.overrideWith((Ref _) => ScreenCapture())',
      ),
      isTrue,
    );
  });
}

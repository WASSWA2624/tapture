import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/screen_capture.dart';

void main() {
  final Uint8List first = Uint8List.fromList(<int>[1, 2, 3]);
  final Uint8List second = Uint8List.fromList(<int>[4, 5]);
  final Uint8List third = Uint8List.fromList(<int>[6]);

  test('the fake hands out successive frames from one session', () async {
    final ScreenCapture capture = ScreenCapture.fake(
      canCapture: true,
      frames: <Uint8List>[first, second, third],
    );
    expect((await capture.start() as Success<bool>).value, isTrue);
    expect(capture.isSharing, isTrue);
    expect(
      (await capture.still(longEdge: 100) as Success<Uint8List>).value,
      first,
    );
    expect(
      (await capture.still(longEdge: 100) as Success<Uint8List>).value,
      second,
    );
    expect(
      (await capture.still(longEdge: 100) as Success<Uint8List>).value,
      third,
    );
    capture.stop();
    expect(capture.isSharing, isFalse);
  });

  test('cancel returns false and is not sharing', () async {
    const ScreenCapture capture = ScreenCapture.fake(canCapture: true);
    expect((await capture.start() as Success<bool>).value, isFalse);
    expect(capture.isSharing, isFalse);
  });

  test('a refusal maps onto catalogue copy', () async {
    const ScreenCapture capture = ScreenCapture.fake(
      canCapture: true,
      failure: PermissionFailure(message: Copy.displayNoAccess),
    );
    expect(
      (await capture.start() as FailureResult<bool>).failure.message,
      Copy.displayNoAccess,
    );
    expect(capture.isSharing, isFalse);
  });

  test('stop ends the session and fires ended', () async {
    final ScreenCapture capture = ScreenCapture.fake(
      canCapture: true,
      frames: <Uint8List>[first],
    );
    expect((await capture.start() as Success<bool>).value, isTrue);
    final Future<void> ended = capture.ended.first;
    capture.stop();
    await ended;
    expect(capture.isSharing, isFalse);
    expect(capture.stops, 1);
    capture.stop();
    expect(capture.stops, 1);
  });

  test('a mid-session end stops sharing and fires ended', () async {
    final ScreenCapture capture = ScreenCapture.fake(
      canCapture: true,
      frames: <Uint8List>[first],
    );
    expect((await capture.start() as Success<bool>).value, isTrue);
    final Future<void> ended = capture.ended.first;
    capture.end();
    await ended;
    expect(capture.isSharing, isFalse);
    expect(capture.stops, 0);
  });

  test('native is hidden and start returns false', () async {
    final ScreenCapture capture = ScreenCapture();
    expect(capture.canCapture, isFalse);
    expect((await capture.start() as Success<bool>).value, isFalse);
    expect(capture.isSharing, isFalse);
    capture.stop();
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
    expect(web.contains('no-focus-change'), isTrue);
    expect(web.contains('CaptureController'), isTrue);
    expect(web.contains("addEventListener('ended'"), isTrue);
    expect(web.contains('stream?.stop()'), isTrue);
    expect(
      File('lib/main.dart').readAsStringSync().contains(
        'feedbackScreenCaptureProvider.overrideWith((Ref _) => ScreenCapture())',
      ),
      isTrue,
    );
  });
}

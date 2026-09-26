import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ocr_block.dart';
import 'package:tapture/core/ai/ocr_result.dart';
import 'package:tapture/core/ai/ocr_service.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';

void main() {
  late Directory directory;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('tapture_ocr_service_');
  });

  tearDown(() {
    try {
      directory.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows can still hold a file the reader just closed.
    }
  });

  String plate(String name, String text) {
    final File file = File('${directory.path}/$name.png')
      ..writeAsBytesSync(paintOcrPlate(text));
    return file.path;
  }

  /// Runs [body] with every HTTP client refused, so a read that reached for
  /// the network would fail.
  Future<T> offline<T>(Future<T> Function() body) {
    return HttpOverrides.runZoned<Future<T>>(
      body,
      createHttpClient: (SecurityContext? _) =>
          throw const SocketException('The network is off in this test.'),
    );
  }

  test('a plate with known text is read with the network off', () async {
    final String path = plate('serial', 'SN458923');

    final OcrResult result = await offline(() => OcrService().recognise(path));

    expect(result.text, 'SN458923');
    expect(result.blocks, isNotEmpty);
    final OcrBlock block = result.blocks.first;
    expect(block.text, 'SN458923');
    expect(block.bounds.width, greaterThan(0));
    expect(block.bounds.height, greaterThan(0));
    expect(block.confidence, inInclusiveRange(0, 1));
  });

  test('each plate line is its own block, top to bottom', () async {
    final String path = plate('lines', 'GRUNDFOS\nSN458923');

    final OcrResult result = await offline(() => OcrService().recognise(path));

    expect(result.blocks.map((OcrBlock b) => b.text), <String>[
      'GRUNDFOS',
      'SN458923',
    ]);
    expect(
      result.blocks.last.bounds.top,
      greaterThan(result.blocks.first.bounds.top),
    );
  });

  test('a photo that is not on the device is a validation failure', () async {
    await expectLater(
      OcrService().recognise('${directory.path}/missing.png'),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('a cancelled read throws before any work', () async {
    final CancellationToken token = CancellationToken()..cancel();

    await expectLater(
      OcrService().recognise(plate('serial', 'SN1'), cancel: token),
      throwsA(isA<CancelledFailure>()),
    );
  });
}

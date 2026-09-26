import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/ai/ocr_result.dart';
import 'package:tapture/core/ai/ocr_service.dart';
import 'package:tapture/core/hash/perceptual_hash.dart';
import 'package:tapture/features/processing/domain/image_preprocess.dart';

void main() {
  test('preprocessing leaves the original bytes unchanged', () {
    final Uint8List original = paintOcrPlate('SN458923');
    final Uint8List before = Uint8List.fromList(original);
    final Uint8List prepared = ImagePreprocess.prepare(original);
    expect(original, before);
    expect(prepared, isNotEmpty);
    expect(prepared, isNot(equals(original)));
  });

  test('a plate photo is read on device with the network denied', () async {
    final io.Directory directory = io.Directory.systemTemp.createTempSync(
      'tapture_ocr_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    final io.File plate = io.File('${directory.path}/plate.png');
    await plate.writeAsBytes(paintOcrPlate('SN458923'));
    final OcrResult result = await OcrService().recognise(plate.path);
    expect(result.text, 'SN458923');
    expect(result.blocks, isNotEmpty);
    expect(result.blocks.first.bounds.width, greaterThan(0));
  });

  test('a resized copy matches and an unrelated photo does not', () {
    final img.Image base = img.Image(width: 32, height: 32);
    img.fill(base, color: img.ColorRgb8(20, 20, 20));
    img.fillRect(
      base,
      x1: 4,
      y1: 4,
      x2: 20,
      y2: 24,
      color: img.ColorRgb8(220, 220, 220),
    );
    final img.Image resized = img.copyResize(base, width: 16, height: 16);
    final img.Image other = img.Image(width: 32, height: 32);
    for (var y = 0; y < 32; y++) {
      for (var x = 0; x < 32; x++) {
        final bool on = ((x ~/ 4) + (y ~/ 4)).isEven;
        other.setPixel(
          x,
          y,
          img.ColorRgb8(on ? 0 : 255, on ? 0 : 255, on ? 0 : 255),
        );
      }
    }
    final String left = PerceptualHash.ofBytes(
      Uint8List.fromList(img.encodePng(base)),
    );
    final String right = PerceptualHash.ofBytes(
      Uint8List.fromList(img.encodePng(resized)),
    );
    final String far = PerceptualHash.ofBytes(
      Uint8List.fromList(img.encodePng(other)),
    );
    expect(PerceptualHash.matches(left, right), isTrue);
    expect(PerceptualHash.matches(left, far), isFalse);
    expect(PerceptualHash.distance(left, far), greaterThan(10));
  });
}

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/features/feedback/presentation/feedback_shot_fit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final int edge = AppConstants.userFeedback.screenshotLongEdge;

  test(
    'a large landscape photo is scaled to the long edge, not squashed',
    () async {
      final Uint8List capped = await FeedbackShotFit.cap(
        await _png(edge * 2, edge),
      );
      final ({int width, int height}) size = await _size(capped);
      expect(size.width, edge);
      expect(size.height, edge ~/ 2);
    },
  );

  test('a large portrait photo is scaled on its height', () async {
    final Uint8List capped = await FeedbackShotFit.cap(
      await _png(edge ~/ 2, edge * 2),
    );
    final ({int width, int height}) size = await _size(capped);
    expect(size.height, edge);
    expect(size.width, edge ~/ 4);
  });

  test('a photo that already fits is returned untouched', () async {
    final Uint8List small = await _png(40, 20);
    expect(identical(await FeedbackShotFit.cap(small), small), isTrue);
  });

  test('bytes that are not an image are kept as they are', () async {
    final Uint8List junk = Uint8List.fromList(<int>[1, 2, 3]);
    expect(await FeedbackShotFit.cap(junk), junk);
  });
}

Future<Uint8List> _png(int width, int height) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const Color(0xFF336699),
  );
  final ui.Image image = await recorder.endRecording().toImage(width, height);
  final ByteData? bytes = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  image.dispose();
  return bytes!.buffer.asUint8List();
}

Future<({int width, int height})> _size(Uint8List bytes) async {
  final ui.Codec codec = await ui.instantiateImageCodec(bytes);
  final ui.Image image = (await codec.getNextFrame()).image;
  final ({int width, int height}) size = (
    width: image.width,
    height: image.height,
  );
  image.dispose();
  codec.dispose();
  return size;
}

import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/assets/assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('provider IDs resolve only official surface variants', () {
    expect(AiProviderAssets.forProvider('gemini'), AiProviderAssets.gemini);
    expect(
      AiProviderAssets.forProvider('gemini', inverse: true),
      AiProviderAssets.gemini,
    );
    expect(AiProviderAssets.forProvider('openai'), AiProviderAssets.openai);
    expect(
      AiProviderAssets.forProvider('openai', inverse: true),
      AiProviderAssets.openaiInverse,
    );
    expect(AiProviderAssets.forProvider('xai'), AiProviderAssets.xai);
    expect(
      AiProviderAssets.forProvider('xai', inverse: true),
      AiProviderAssets.xaiInverse,
    );
    expect(AiProviderAssets.forProvider('unknown'), isNull);
    expect(AiProviderAssets.forProvider(null), isNull);
  });

  test('every official variant is a bundled local PNG', () async {
    for (final String asset in <String>[
      AiProviderAssets.gemini,
      AiProviderAssets.openai,
      AiProviderAssets.openaiInverse,
      AiProviderAssets.xai,
      AiProviderAssets.xaiInverse,
    ]) {
      final ByteData bytes = await rootBundle.load(asset);
      expect(bytes.buffer.asUint8List(bytes.offsetInBytes, 8), <int>[
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
      ], reason: asset);
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ByteData pixels = (await frame.image.toByteData())!;
      bool opaque = false;
      for (int i = 3; i < pixels.lengthInBytes; i += 4) {
        if (pixels.getUint8(i) == 255) {
          opaque = true;
          break;
        }
      }
      frame.image.dispose();
      codec.dispose();
      expect(opaque, isTrue, reason: '$asset must render visible artwork');
    }
  });
}

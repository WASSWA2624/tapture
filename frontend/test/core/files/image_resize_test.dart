import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/image_resize.dart';

void main() {
  test(
    'a wide original becomes a proportional thumbnail without changing its bytes',
    () async {
      final Uint8List original = Uint8List.fromList(
        img.encodeJpg(img.Image(width: 400, height: 200)),
      );
      final List<int> before = original.toList();
      final Result<Uint8List> result = await ImageResize.fit(
        original,
        longEdge: 96,
        quality: 80,
      );
      final img.Image decoded = img.decodeJpg(
        (result as Success<Uint8List>).value,
      )!;
      expect((decoded.width, decoded.height), (96, 48));
      expect(original, before);
    },
  );

  test('cancel and corrupt bytes produce failures instead of images', () async {
    final CancellationToken cancel = CancellationToken()..cancel();
    expect(
      await ImageResize.fit(
        Uint8List(0),
        longEdge: 96,
        quality: 80,
        cancel: cancel,
      ),
      isA<FailureResult<Uint8List>>(),
    );
    expect(
      await ImageResize.fit(
        Uint8List.fromList(<int>[1, 2, 3]),
        longEdge: 96,
        quality: 80,
      ),
      isA<FailureResult<Uint8List>>(),
    );
  });
}

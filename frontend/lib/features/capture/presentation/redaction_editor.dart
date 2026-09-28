import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/errors/result.dart';

/// Marks rectangles on a photo. Marks are burned into a copy, not the original.
final class RedactionEditor extends StatelessWidget {
  /// Creates the editor.
  const RedactionEditor({
    required this.marks,
    required this.onChanged,
    this.failure,
    this.empty = false,
    super.key,
  });

  /// Marks already placed, in image pixels.
  final List<RedactionMark> marks;

  /// Called with the marks after a tap adds one.
  final ValueChanged<List<RedactionMark>> onChanged;

  /// Why the photo could not be shown.
  final String? failure;

  /// Whether there is no photo to mark.
  final bool empty;

  /// Burns [marks] into a copy of [original]. Pixels outside the marks match.
  static Future<Uint8List> burn(
    Uint8List original,
    List<RedactionMark> marks,
  ) async {
    final Result<Uint8List> burned = await runIsolate<List<Object>, Uint8List>(
      _burn,
      <Object>[
        original,
        <int>[
          for (final RedactionMark mark in marks) ...<int>[
            mark.x,
            mark.y,
            mark.width,
            mark.height,
          ],
        ],
      ],
    );
    return burned.fold(
      (_) => Uint8List.fromList(original),
      (Uint8List value) => value,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (failure != null) {
      return Text(failure!);
    }
    if (empty) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      key: const ValueKey<String>('redaction-surface'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (TapDownDetails details) {
        onChanged(<RedactionMark>[
          ...marks,
          (
            x: details.localPosition.dx.round(),
            y: details.localPosition.dy.round(),
            width: 8,
            height: 8,
          ),
        ]);
      },
      child: const SizedBox.expand(key: ValueKey<String>('redaction-photo')),
    );
  }
}

/// One obscured rectangle, in image pixels.
typedef RedactionMark = ({int x, int y, int width, int height});

Uint8List _burn(List<Object> message) {
  final Uint8List original = message[0] as Uint8List;
  final List<int> flat = message[1] as List<int>;
  final img.Image? decoded = img.decodeImage(original);
  if (decoded == null) {
    return Uint8List.fromList(original);
  }
  final img.Image copy = img.Image.from(decoded);
  final img.ColorRgb8 fill = img.ColorRgb8(0, 0, 0);
  for (var index = 0; index + 3 < flat.length; index += 4) {
    final int x = flat[index];
    final int y = flat[index + 1];
    final int width = flat[index + 2];
    final int height = flat[index + 3];
    for (var py = y; py < y + height && py < copy.height; py++) {
      for (var px = x; px < x + width && px < copy.width; px++) {
        if (px < 0 || py < 0) {
          continue;
        }
        copy.setPixel(px, py, fill);
      }
    }
  }
  return img.encodePng(copy);
}

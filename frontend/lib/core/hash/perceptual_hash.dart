import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/result.dart';

/// Difference hash for near-duplicate photos.
///
/// [distance] is the hamming distance of two hex hashes. A match inside
/// [AppConstants.processing.perceptualHashDistance] is the same photo.
final class PerceptualHash {
  /// 64-bit difference hash of [bytes], as 16 hex characters.
  static String ofBytes(Uint8List bytes) {
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return '';
    }
    return _ofImage(decoded);
  }

  /// Hashes [bytes] off the UI thread.
  static Future<Result<String>> ofBytesOffThread(Uint8List bytes) {
    return runIsolate(_hashBytes, bytes);
  }

  /// Hamming distance of two hashes. An empty hash is a full miss.
  static int distance(String left, String right) {
    if (left.isEmpty || right.isEmpty || left.length != right.length) {
      return AppConstants.processing.perceptualHashDistance + 1;
    }
    var bits = 0;
    for (var i = 0; i < left.length; i++) {
      final int a = int.parse(left[i], radix: 16);
      final int b = int.parse(right[i], radix: 16);
      var xor = a ^ b;
      while (xor != 0) {
        bits += xor & 1;
        xor >>= 1;
      }
    }
    return bits;
  }

  /// Whether [left] and [right] are the same photo under the app threshold.
  static bool matches(String left, String right) {
    return distance(left, right) <=
        AppConstants.processing.perceptualHashDistance;
  }
}

Future<String> _hashBytes(Uint8List bytes) async {
  return PerceptualHash.ofBytes(bytes);
}

String _ofImage(img.Image source) {
  final img.Image small = img.copyResize(
    source,
    width: 9,
    height: 8,
    interpolation: img.Interpolation.average,
  );
  final StringBuffer hex = StringBuffer();
  var nibble = 0;
  var filled = 0;
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      final num left = img.getLuminance(small.getPixel(x, y));
      final num right = img.getLuminance(small.getPixel(x + 1, y));
      nibble = (nibble << 1) | (left > right ? 1 : 0);
      filled++;
      if (filled == 4) {
        hex.write(nibble.toRadixString(16));
        nibble = 0;
        filled = 0;
      }
    }
  }
  return hex.toString();
}

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
    final img.Image? decoded = _decode(bytes);
    if (decoded == null) {
      return '';
    }
    return _ofImage(decoded);
  }

  /// Hashes [bytes] off the UI thread.
  ///
  /// [onProgress] hears 0 to 1 around the decode, the heavy part. [cancel]
  /// tears the isolate down and completes with a cancelled failure.
  static Future<Result<String>> ofBytesOffThread(
    Uint8List bytes, {
    CancellationToken? cancel,
    void Function(double)? onProgress,
  }) {
    return runIsolate(
      _hashBytes,
      bytes,
      cancel: cancel,
      onProgress: onProgress,
    );
  }

  /// The id of the stored hash nearest [probe] inside the app threshold.
  ///
  /// [stored] maps row ids to hashes. Null when none is close enough.
  static String? nearest(String probe, Map<String, String> stored) {
    String? best;
    var bestDistance = AppConstants.processing.perceptualHashDistance + 1;
    for (final MapEntry<String, String> entry in stored.entries) {
      final int gap = distance(probe, entry.value);
      if (gap < bestDistance) {
        best = entry.key;
        bestDistance = gap;
      }
    }
    return best;
  }

  /// [nearest], run off the UI thread so a large cache never blocks it.
  static Future<Result<String?>> nearestOffThread(
    String probe,
    Map<String, String> stored, {
    CancellationToken? cancel,
  }) {
    return runIsolate(_nearest, <Object?>[probe, stored], cancel: cancel);
  }

  /// Hamming distance of two hashes. An empty hash is a full miss.
  static int distance(String left, String right) {
    if (left.isEmpty || right.isEmpty || left.length != right.length) {
      return AppConstants.processing.perceptualHashDistance + 1;
    }
    var bits = 0;
    try {
      for (var i = 0; i < left.length; i++) {
        final int a = int.parse(left[i], radix: 16);
        final int b = int.parse(right[i], radix: 16);
        var xor = a ^ b;
        while (xor != 0) {
          bits += xor & 1;
          xor >>= 1;
        }
      }
    } on FormatException {
      return AppConstants.processing.perceptualHashDistance + 1;
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
  IsolateRunner.reportProgress(0);
  final img.Image? decoded = _decode(bytes);
  IsolateRunner.reportProgress(_decodedShare);
  final String hash = decoded == null ? '' : _ofImage(decoded);
  IsolateRunner.reportProgress(1);
  return hash;
}

Future<String?> _nearest(List<Object?> job) async {
  return PerceptualHash.nearest(
    job[0]! as String,
    (job[1]! as Map<Object?, Object?>).cast<String, String>(),
  );
}

/// Share of the hash job done once the image is decoded.
const double _decodedShare = 0.9;

/// The difference hash compares each pixel with its right neighbour on a
/// grid one column wider than it is tall, giving 64 bits.
const int _gridWidth = 9;
const int _gridHeight = 8;
const int _bitsPerHexDigit = 4;

String _ofImage(img.Image source) {
  final img.Image small = img.copyResize(
    source,
    width: _gridWidth,
    height: _gridHeight,
    interpolation: img.Interpolation.average,
  );
  final StringBuffer hex = StringBuffer();
  var nibble = 0;
  var filled = 0;
  for (var y = 0; y < _gridHeight; y++) {
    for (var x = 0; x < _gridWidth - 1; x++) {
      final num left = img.getLuminance(small.getPixel(x, y));
      final num right = img.getLuminance(small.getPixel(x + 1, y));
      nibble = (nibble << 1) | (left > right ? 1 : 0);
      filled++;
      if (filled == _bitsPerHexDigit) {
        hex.write(nibble.toRadixString(16));
        nibble = 0;
        filled = 0;
      }
    }
  }
  return hex.toString();
}

/// The decoded photo, or null for bytes that are not an image; some broken
/// files throw rather than return null.
img.Image? _decode(Uint8List bytes) {
  try {
    return img.decodeImage(bytes);
  } on Object {
    return null;
  }
}

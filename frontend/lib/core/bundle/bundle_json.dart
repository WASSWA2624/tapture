import 'dart:convert';
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';

/// JSON metadata encoding with a byte ceiling applied while the SDK encoder
/// emits chunks, before a complete JSON String or oversized byte buffer exists.
abstract final class BundleJson {
  /// Encodes [value] under [maximum], with optional human-readable indentation.
  static Uint8List encode(
    Object value, {
    required int maximum,
    bool indent = false,
  }) {
    final _BoundedJsonSink output = _BoundedJsonSink(maximum);
    final ChunkedConversionSink<Object?> encoder = JsonUtf8Encoder(
      indent ? '  ' : null,
      null,
      AppConstants.hashing.chunkBytes,
    ).startChunkedConversion(output);
    encoder.add(value);
    encoder.close();
    return output.bytes.takeBytes();
  }
}

final class _BoundedJsonSink implements Sink<List<int>> {
  _BoundedJsonSink(this.maximum);
  final int maximum;
  final BytesBuilder bytes = BytesBuilder(copy: false);
  int length = 0;
  @override
  void add(List<int> chunk) {
    length += chunk.length;
    if (length > maximum) {
      throw ValidationFailure(
        localizedMessage: Copy.messages.failureTheProjectMetadataIsTooLargeFor,
        localizedRecovery: Copy.messages.failureChooseASmallerPackageScope,
      );
    }
    bytes.add(chunk);
  }

  @override
  void close() {}
}

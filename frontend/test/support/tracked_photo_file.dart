import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:image_picker/image_picker.dart';

/// A real picked-file surface that records prefix and full reads.
final class TrackedPhotoFile extends XFile {
  TrackedPhotoFile({
    required Uint8List bytes,
    required String name,
    this.claimedLength,
    this.replacement,
  }) : _pickedName = name,
       super.fromData(bytes, name: name);

  final String _pickedName;

  @override
  String get name => _pickedName;

  final int? claimedLength;
  final Uint8List? replacement;
  int prefixReads = 0;
  int fullReads = 0;

  @override
  Future<int> length() async => claimedLength ?? await super.length();

  @override
  Stream<Uint8List> openRead([int? start, int? end]) {
    prefixReads++;
    return super.openRead(start, end);
  }

  @override
  Future<Uint8List> readAsBytes() async {
    fullReads++;
    return replacement ?? await super.readAsBytes();
  }
}

/// A small valid image for picker fixtures that preserve original bytes.
Uint8List pickedPhotoBytes() =>
    image.encodeJpg(image.Image(width: 2, height: 2));

/// JPEG, PNG and lossless WebP originals with distinct source dimensions.
Map<String, ({Uint8List bytes, int width, int height, String mimeType})>
pickedPhotoOriginals() =>
    <String, ({Uint8List bytes, int width, int height, String mimeType})>{
      'jpg': (
        bytes: image.encodeJpg(image.Image(width: 37, height: 19)),
        width: 37,
        height: 19,
        mimeType: 'image/jpeg',
      ),
      'png': (
        bytes: image.encodePng(image.Image(width: 29, height: 13)),
        width: 29,
        height: 13,
        mimeType: 'image/png',
      ),
      // 31×17 RGB lossless WebP. No encoder is needed in the app or tests.
      'webp': (
        bytes: base64Decode(
          'UklGRh4AAABXRUJQVlA4TBEAAAAvHgAEAAdQrXrUsv+BiOh/AAA=',
        ),
        width: 31,
        height: 17,
        mimeType: 'image/webp',
      ),
    };

import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/bundle/bundle_archive_stream.dart';

void main() {
  for (final bool compress in <bool>[false, true]) {
    test('checked offsets read the exact ${compress ? 'DEFLATE' : 'STORE'} '
        'payload without a second directory decode', () {
      final Uint8List encoded = _package(compress: compress);
      final Map<String, BundleZipEntry> inventory = _inventory(encoded);
      final BundleZipEntry entry = inventory['photo.bin']!;
      expect(entry.sourceLength, encoded.length);
      expect(entry.size, 4);
      expect(
        entry.compression,
        compress ? ZipFile.zipCompressionDeflate : ZipFile.zipCompressionStore,
      );
      expect(entry.compressedSize, greaterThan(0));
      expect(
        entry.dataOffset + entry.compressedSize,
        lessThanOrEqualTo(encoded.length),
      );
      expect(
        BundleArchiveStream.bytes(entry.open(InputMemoryStream(encoded))),
        <int>[1, 2, 3, 4],
      );
    });
  }

  test('a checked offset rejects changed metadata and truncated source', () {
    final Uint8List encoded = _package();
    final BundleZipEntry entry = _inventory(encoded)['photo.bin']!;
    final Uint8List changed = Uint8List.fromList(encoded)..[30] = 120;
    expect(() => entry.open(InputMemoryStream(changed)), throwsFormatException);
    expect(
      () =>
          entry.open(InputMemoryStream(encoded.sublist(0, encoded.length - 1))),
      throwsFormatException,
    );
  });

  test(
    'local path, flags, method, CRC and lengths must match central values',
    () {
      final Uint8List encoded = _package();
      for (final int offset in <int>[6, 8, 14, 18, 22, 30]) {
        final Uint8List changed = Uint8List.fromList(encoded);
        changed[offset] ^= 1;
        expect(
          () => _inventory(changed),
          throwsFormatException,
          reason: 'local metadata byte $offset must not override the directory',
        );
      }
    },
  );
}

Uint8List _package({bool compress = false}) {
  final ArchiveFile entry = ArchiveFile('photo.bin', 4, <int>[1, 2, 3, 4])
    ..compression = compress ? CompressionType.deflate : CompressionType.none;
  return Uint8List.fromList(
    ZipEncoder().encodeBytes(Archive()..addFile(entry)),
  );
}

Map<String, BundleZipEntry> _inventory(List<int> encoded) {
  final Map<String, BundleZipEntry> inventory = <String, BundleZipEntry>{};
  BundleArchiveStream.decode(InputMemoryStream(encoded), inventory: inventory);
  return inventory;
}

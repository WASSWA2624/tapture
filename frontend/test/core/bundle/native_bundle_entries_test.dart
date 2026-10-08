import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/bundle/bundle_archive_stream.dart';
import 'package:tapture/core/bundle/bundle_entry.dart';
import 'package:tapture/core/bundle/native_bundle_entries.dart';
import 'package:tapture/core/errors/result.dart';

void main() {
  test(
    'many attachments reuse one directory inventory and release each lease',
    () async {
      final Map<String, List<int>> payloads = <String, List<int>>{
        for (int index = 0; index < 120; index++)
          'photos/$index.bin': List<int>.filled(128, index),
      };
      final Archive archive = Archive();
      for (final MapEntry<String, List<int>> entry in payloads.entries) {
        archive.addFile(
          ArchiveFile(entry.key, entry.value.length, entry.value),
        );
      }
      final ({File file, Directory scratch}) fixture = await _fixture(
        ZipEncoder().encodeBytes(archive),
      );
      final NativeBundleEntries owner = NativeBundleEntries(
        source: fixture.file.path,
        scratch: fixture.scratch,
        entries: _manifest(payloads),
      );
      try {
        for (final MapEntry<String, List<int>> entry in payloads.entries) {
          expect(await _read(owner, entry.key), entry.value);
          expect(await fixture.scratch.list().toList(), isEmpty);
        }
        expect(owner.debugDirectoryReads, 1);
      } finally {
        await owner.close();
      }
      expect(await fixture.file.exists(), isTrue);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'inspection offsets transfer without any later directory decoding',
    () async {
      final List<int> payload = <int>[1, 2, 3, 4];
      final ({File file, Directory scratch}) fixture = await _fixture(
        _storedZip('photos/p.bin', payload),
      );
      final Map<String, BundleZipEntry> inventory = _inventory(fixture.file);
      final NativeBundleEntries owner = NativeBundleEntries(
        source: fixture.file.path,
        scratch: fixture.scratch,
        entries: _manifest(<String, List<int>>{'photos/p.bin': payload}),
        inventory: inventory,
      );
      // The parent owns an immutable copy rather than the caller's mutable map.
      inventory.clear();
      try {
        expect(await _read(owner, 'photos/p.bin'), payload);
        expect(await _read(owner, 'photos/p.bin'), payload);
        expect(owner.debugDirectoryReads, 0);
      } finally {
        await owner.close();
      }
    },
  );

  test(
    'cached offsets reject a changed local path and clear failed output',
    () async {
      final List<int> payload = <int>[1, 2, 3, 4];
      final ({File file, Directory scratch}) fixture = await _fixture(
        _storedZip('photos/p.bin', payload),
      );
      final Map<String, BundleZipEntry> inventory = _inventory(fixture.file);
      final NativeBundleEntries owner = NativeBundleEntries(
        source: fixture.file.path,
        scratch: fixture.scratch,
        entries: _manifest(<String, List<int>>{'photos/p.bin': payload}),
        inventory: inventory,
      );
      final Uint8List changed = await fixture.file.readAsBytes();
      changed[30] = 'x'.codeUnitAt(0);
      await fixture.file.writeAsBytes(changed);
      try {
        expect(
          await owner.openEntry('photos/p.bin'),
          isA<FailureResult<Stream<List<int>>>>(),
        );
        expect(await fixture.scratch.list().toList(), isEmpty);
        expect(owner.debugDirectoryReads, 0);
      } finally {
        await owner.close();
      }
    },
  );

  test(
    'CRC mismatch is refused even when the manifest SHA matches the payload',
    () async {
      final List<int> payload = <int>[1, 2, 3, 4];
      final ({File file, Directory scratch}) fixture = await _fixture(
        _storedZip('photos/p.bin', payload, crc: getCrc32(payload) ^ 1),
      );
      final NativeBundleEntries owner = NativeBundleEntries(
        source: fixture.file.path,
        scratch: fixture.scratch,
        entries: _manifest(<String, List<int>>{'photos/p.bin': payload}),
      );
      try {
        expect(
          await owner.openEntry('photos/p.bin'),
          isA<FailureResult<Stream<List<int>>>>(),
        );
        expect(await fixture.scratch.list().toList(), isEmpty);
      } finally {
        await owner.close();
      }
    },
  );

  test(
    'cached offsets still verify damaged content and archive length',
    () async {
      final List<int> payload = <int>[1, 2, 3, 4];
      final ({File file, Directory scratch}) fixture = await _fixture(
        _storedZip('photos/p.bin', payload),
      );
      final Map<String, BundleZipEntry> inventory = _inventory(fixture.file);
      final NativeBundleEntries owner = NativeBundleEntries(
        source: fixture.file.path,
        scratch: fixture.scratch,
        entries: _manifest(<String, List<int>>{'photos/p.bin': payload}),
        inventory: inventory,
      );
      final Uint8List original = await fixture.file.readAsBytes();
      final Uint8List changed = Uint8List.fromList(original);
      changed[inventory['photos/p.bin']!.dataOffset] ^= 1;
      await fixture.file.writeAsBytes(changed);
      try {
        expect(
          await owner.openEntry('photos/p.bin'),
          isA<FailureResult<Stream<List<int>>>>(),
        );
        await fixture.file.writeAsBytes(
          original.sublist(0, original.length - 1),
        );
        expect(
          await owner.openEntry('photos/p.bin'),
          isA<FailureResult<Stream<List<int>>>>(),
        );
        expect(await fixture.scratch.list().toList(), isEmpty);
      } finally {
        await owner.close();
      }
    },
  );

  for (final bool zip64 in <bool>[false, true]) {
    for (final bool signature in <bool>[false, true]) {
      test('deferred sizes accept checked ${zip64 ? 'ZIP64' : 'ZIP32'} '
          'descriptors with signature=$signature', () async {
        final List<int> payload = <int>[1, 2, 3, 4];
        final ({File file, Directory scratch}) fixture = await _fixture(
          _storedZip(
            'photos/p.bin',
            payload,
            deferred: true,
            zip64: zip64,
            signature: signature,
          ),
        );
        final NativeBundleEntries owner = NativeBundleEntries(
          source: fixture.file.path,
          scratch: fixture.scratch,
          entries: _manifest(<String, List<int>>{'photos/p.bin': payload}),
        );
        try {
          expect(await _read(owner, 'photos/p.bin'), payload);
          expect(owner.debugDirectoryReads, 1);
        } finally {
          await owner.close();
        }
      });
    }
  }

  test(
    'unsafe paths are refused by the constructor inventory fallback',
    () async {
      final List<int> payload = <int>[1];
      final ({File file, Directory scratch}) fixture = await _fixture(
        _storedZip('../outside.bin', payload),
      );
      final NativeBundleEntries owner = NativeBundleEntries(
        source: fixture.file.path,
        scratch: fixture.scratch,
        entries: _manifest(<String, List<int>>{'../outside.bin': payload}),
      );
      try {
        expect(
          await owner.openEntry('../outside.bin'),
          isA<FailureResult<Stream<List<int>>>>(),
        );
        expect(await fixture.scratch.list().toList(), isEmpty);
      } finally {
        await owner.close();
      }
    },
  );
}

Future<({File file, Directory scratch})> _fixture(List<int> bytes) async {
  final Directory folder = await Directory.systemTemp.createTemp(
    'tapture-offset-test-',
  );
  addTearDown(() => folder.delete(recursive: true));
  return (
    file: await File('${folder.path}/package.zip').writeAsBytes(bytes),
    scratch: await Directory('${folder.path}/scratch').create(),
  );
}

List<BundleEntry> _manifest(Map<String, List<int>> payloads) => <BundleEntry>[
  for (final MapEntry<String, List<int>> entry in payloads.entries)
    BundleEntry(
      path: entry.key,
      byteLength: entry.value.length,
      sha256: crypto.sha256.convert(entry.value).toString(),
    ),
];

Map<String, BundleZipEntry> _inventory(File file) {
  final InputFileStream input = InputFileStream(file.path);
  try {
    final Map<String, BundleZipEntry> inventory = <String, BundleZipEntry>{};
    BundleArchiveStream.decode(input, inventory: inventory);
    return inventory;
  } finally {
    input.closeSync();
  }
}

Future<List<int>> _read(NativeBundleEntries owner, String path) async => <int>[
  await for (final List<int> chunk in (await owner.openEntry(
    path,
  )).getOrThrow())
    ...chunk,
];

// Real ZIP records include optional signed/unsigned and ZIP64 data descriptors.
List<int> _storedZip(
  String path,
  List<int> payload, {
  bool deferred = false,
  bool zip64 = false,
  bool signature = true,
  int? crc,
}) {
  final List<int> name = path.codeUnits;
  final int checksum = crc ?? getCrc32(payload);
  final OutputStream out = OutputMemoryStream();
  out.writeUint32(0x04034b50);
  out.writeUint16(zip64 ? 45 : 20);
  out.writeUint16(deferred ? 8 : 0);
  out.writeUint16(0);
  out.writeUint16(0);
  out.writeUint16(0);
  out.writeUint32(deferred ? 0 : checksum);
  out.writeUint32(
    zip64
        ? 0xffffffff
        : deferred
        ? 0
        : payload.length,
  );
  out.writeUint32(
    zip64
        ? 0xffffffff
        : deferred
        ? 0
        : payload.length,
  );
  out.writeUint16(name.length);
  out.writeUint16(zip64 ? 20 : 0);
  out.writeBytes(name);
  if (zip64) {
    out.writeUint16(1);
    out.writeUint16(16);
    out.writeUint64(payload.length);
    out.writeUint64(payload.length);
  }
  out.writeBytes(payload);
  if (deferred) {
    if (signature) out.writeUint32(0x08074b50);
    out.writeUint32(checksum);
    if (zip64) {
      out.writeUint64(payload.length);
      out.writeUint64(payload.length);
    } else {
      out.writeUint32(payload.length);
      out.writeUint32(payload.length);
    }
  }
  final int directory = out.length;
  out.writeUint32(0x02014b50);
  out.writeUint16(20);
  out.writeUint16(zip64 ? 45 : 20);
  out.writeUint16(deferred ? 8 : 0);
  out.writeUint16(0);
  out.writeUint16(0);
  out.writeUint16(0);
  out.writeUint32(checksum);
  out.writeUint32(payload.length);
  out.writeUint32(payload.length);
  out.writeUint16(name.length);
  out.writeUint16(0);
  out.writeUint16(0);
  out.writeUint16(0);
  out.writeUint16(0);
  out.writeUint32(0);
  out.writeUint32(0);
  out.writeBytes(name);
  final int directoryLength = out.length - directory;
  out.writeUint32(0x06054b50);
  out.writeUint16(0);
  out.writeUint16(0);
  out.writeUint16(1);
  out.writeUint16(1);
  out.writeUint32(directoryLength);
  out.writeUint32(directory);
  out.writeUint16(0);
  return out.getBytes();
}

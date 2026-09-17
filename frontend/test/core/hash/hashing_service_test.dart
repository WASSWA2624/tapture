import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/hash/hashing_service.dart';

void main() {
  test('sha256OfString matches the empty and abc vectors', () {
    expect(
      sha256OfString(''),
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );
    expect(
      sha256OfString('abc'),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  test(
    'sha256OfFile matches the same vectors and tears the isolate down',
    () async {
      final Directory directory = Directory.systemTemp.createTempSync(
        'tapture-hash-',
      );
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });

      final File empty = File('${directory.path}/empty')..writeAsStringSync('');
      final File abc = File('${directory.path}/abc')..writeAsStringSync('abc');

      final Result<String> emptyHash = await sha256OfFile(empty);
      final Result<String> abcHash = await sha256OfFile(abc);

      expect(
        emptyHash.fold((_) => '', (String value) => value),
        sha256OfString(''),
      );
      expect(
        abcHash.fold((_) => '', (String value) => value),
        sha256OfString('abc'),
      );
      expect(debugLiveIsolates, 0);
    },
  );

  test(
    'hashing a hundred-megabyte file holds memory flat',
    () async {
      final Directory directory = Directory.systemTemp.createTempSync(
        'tapture-hash-',
      );
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });

      final File file = File('${directory.path}/hundred');
      final RandomAccessFile handle = file.openSync(mode: FileMode.write);
      final Uint8List block = Uint8List(1024 * 1024);
      for (int index = 0; index < 100; index++) {
        handle.writeFromSync(block);
      }
      handle.closeSync();

      final int before = ProcessInfo.currentRss;
      final Result<String> hashed = await sha256OfFile(file);
      final int after = ProcessInfo.currentRss;
      final String digest = hashed.fold((_) => '', (String value) => value);

      expect(digest, hasLength(64));
      expect(digest, _hundredMegabyteZerosSha256);
      expect(after - before, lessThan(50 * 1024 * 1024));
      expect(AppConstants.hashing.chunkBytes, lessThan(1024 * 1024));
      expect(debugLiveIsolates, 0);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

/// SHA-256 of 100 MiB of zeros, computed once from the same chunked hasher.
const String _hundredMegabyteZerosSha256 =
    '20492a4d0d84f8beb1767f6616229f85d44c2827b64bdbfb260ee12fa1109e0e';

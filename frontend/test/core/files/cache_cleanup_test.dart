import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/cache_cleanup.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  test('prune by age then size never touches files outside .cache', () async {
    final Directory documents = Directory.systemTemp.createTempSync(
      'tapture-cleanup-',
    );
    addTearDown(() {
      if (documents.existsSync()) {
        documents.deleteSync(recursive: true);
      }
    });
    final DateTime now = DateTime.utc(2026, 9, 17, 12);
    final StorageRoot storage = StorageRoot.fake(documentsDirectory: documents);
    final Directory cache = _ok(await storage.cacheDir());
    final Directory tapture = _ok(await storage.resolve());

    final File stale = File('${cache.path}/thumbs/stale.bin')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(Uint8List(32));
    final File fresh = File('${cache.path}/thumbs/fresh.bin')
      ..writeAsBytesSync(Uint8List(32));
    final File oldest = File('${cache.path}/upload/oldest.bin')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(Uint8List(100));
    final File newer = File('${cache.path}/upload/newer.bin')
      ..writeAsBytesSync(Uint8List(100));
    final File insideProject = File('${tapture.path}/projects/keep.bin')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(const <int>[7, 7, 7]);
    final File outside = File('${documents.path}/outside.bin')
      ..writeAsBytesSync(const <int>[8, 8, 8]);

    stale.setLastModifiedSync(now.subtract(const Duration(days: 12)));
    fresh.setLastModifiedSync(now.subtract(const Duration(hours: 1)));
    oldest.setLastModifiedSync(now.subtract(const Duration(days: 3)));
    newer.setLastModifiedSync(now.subtract(const Duration(days: 1)));

    final CacheCleanup cleanup = CacheCleanup(
      storageRoot: storage,
      clock: FixedClock(now),
    );

    final int fromAge = _ok(
      await cleanup.prune(
        maxAge: const Duration(days: 10),
        maxBytes: 10 * 1024 * 1024,
      ),
    );
    expect(fromAge, 32);
    expect(stale.existsSync(), isFalse);
    expect(fresh.existsSync(), isTrue);
    expect(insideProject.existsSync(), isTrue);
    expect(outside.existsSync(), isTrue);
    expect(insideProject.readAsBytesSync(), const <int>[7, 7, 7]);
    expect(outside.readAsBytesSync(), const <int>[8, 8, 8]);

    final int fromSize = _ok(
      await cleanup.prune(maxAge: const Duration(days: 10), maxBytes: 150),
    );
    expect(fromSize, 100);
    expect(oldest.existsSync(), isFalse);
    expect(newer.existsSync(), isTrue);
    expect(fresh.existsSync(), isTrue);
    expect(insideProject.existsSync(), isTrue);
    expect(outside.existsSync(), isTrue);
  });
}

T _ok<T>(Result<T> result) {
  return result.fold((Failure failure) {
    fail('${failure.message} ${failure.recoveryAction}');
  }, (T value) => value);
}

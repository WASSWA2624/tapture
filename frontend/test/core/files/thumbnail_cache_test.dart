import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/files/thumbnail_cache.dart';
import 'package:tapture/core/hash/hashing_service.dart';

void main() {
  test(
    'a second thumbnail request does not decode the original again',
    () async {
      final _Harness harness = await _Harness.open();
      var decodes = 0;
      final ThumbnailCache cache = ThumbnailCache(
        storageRoot: harness.storage,
        decode:
            (String path, {required int longEdge, required int quality}) async {
              decodes += 1;
              expect(path, harness.source.path);
              expect(longEdge, AppConstants.images.thumbnailEdge);
              expect(quality, AppConstants.images.thumbnailQuality);
              File(path).readAsBytesSync();
              return Uint8List.fromList(<int>[1, 2, 3, 4]);
            },
      );

      final File first = _ok(
        await cache.thumbnail(
          harness.sha256,
          harness.source.path,
          edge: AppConstants.images.thumbnailEdge,
        ),
      );
      final File second = _ok(
        await cache.thumbnail(
          harness.sha256,
          harness.source.path,
          edge: AppConstants.images.thumbnailEdge,
        ),
      );

      expect(decodes, 1);
      expect(_slash(second.path), _slash(first.path));
      expect(first.existsSync(), isTrue);
      expect(_slash(first.path), contains('/.cache/thumbs/'));
      expect(first.path, contains('${harness.sha256}_'));
      expect(_ok(await sha256OfFile(harness.source)), harness.sha256);
    },
  );

  test('a missing cache entry is rebuilt on the next request', () async {
    final _Harness harness = await _Harness.open();
    var decodes = 0;
    final ThumbnailCache cache = ThumbnailCache(
      storageRoot: harness.storage,
      decode:
          (String path, {required int longEdge, required int quality}) async {
            decodes += 1;
            File(path).readAsBytesSync();
            return Uint8List.fromList(<int>[9, 8, 7]);
          },
    );

    final File first = _ok(
      await cache.thumbnail(
        harness.sha256,
        harness.source.path,
        edge: AppConstants.images.thumbnailEdge,
      ),
    );
    await first.delete();
    final File rebuilt = _ok(
      await cache.thumbnail(
        harness.sha256,
        harness.source.path,
        edge: AppConstants.images.thumbnailEdge,
      ),
    );

    expect(decodes, 2);
    expect(rebuilt.existsSync(), isTrue);
  });

  test('the default decoder fits a stored JPEG inside the edge', () async {
    final _Harness harness = await _Harness.open();
    final img.Image wide = img.Image(width: 400, height: 200)
      ..clear(img.ColorRgb8(30, 120, 200));
    harness.source.writeAsBytesSync(img.encodeJpg(wide));
    final ThumbnailCache cache = ThumbnailCache(storageRoot: harness.storage);

    final File thumb = _ok(
      await cache.thumbnail(
        harness.sha256,
        harness.source.path,
        edge: AppConstants.images.thumbnailEdge,
      ),
    );

    final img.Image? decoded = img.decodeImage(thumb.readAsBytesSync());
    expect(decoded, isNotNull);
    expect(decoded!.width, AppConstants.images.thumbnailEdge);
    expect(decoded.height, AppConstants.images.thumbnailEdge ~/ 2);
  });

  test('the default decoder turns a file that is not a photo away', () async {
    final _Harness harness = await _Harness.open();
    final ThumbnailCache cache = ThumbnailCache(storageRoot: harness.storage);

    final Result<File> result = await cache.thumbnail(
      harness.sha256,
      harness.source.path,
      edge: AppConstants.images.thumbnailEdge,
    );

    expect(
      result.fold((Failure failure) => failure.message, (File _) => 'ok'),
      'That photo could not be read as an image.',
    );
  });
}

final class _Harness {
  _Harness._({
    required this.documents,
    required this.storage,
    required this.source,
    required this.sha256,
  });

  final Directory documents;
  final StorageRoot storage;
  final File source;
  final String sha256;

  static Future<_Harness> open() async {
    final Directory documents = Directory.systemTemp.createTempSync(
      'tapture-thumbs-',
    );
    addTearDown(() {
      if (documents.existsSync()) {
        documents.deleteSync(recursive: true);
      }
    });
    final StorageRoot storage = StorageRoot.fake(documentsDirectory: documents);
    _ok(await storage.resolve());
    final File source = File('${documents.path}/original.bin')
      ..writeAsStringSync('original-pixels');
    final String sha256 = (await sha256OfFile(source)).fold(
      (Failure failure) => fail(failure.message),
      (String value) => value,
    );
    return _Harness._(
      documents: documents,
      storage: storage,
      source: source,
      sha256: sha256,
    );
  }
}

T _ok<T>(Result<T> result) {
  return result.fold((Failure failure) {
    fail('${failure.message} ${failure.recoveryAction}');
  }, (T value) => value);
}

String _slash(String path) => path.replaceAll(r'\', '/');

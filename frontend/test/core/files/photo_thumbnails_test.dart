import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_file_reader.dart';
import 'package:tapture/core/files/blob_file_writer.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/photo_thumbnails.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/files/thumbnail_cache.dart';

void main() {
  test(
    'browser thumbnails persist at their requested size and survive a new reader',
    () async {
      final Map<String, Uint8List> backing = <String, Uint8List>{};
      final BlobStore store = BlobStore.memory(backing: backing);
      final BlobFileWriter writer = BlobFileWriter(store);
      final BlobFileReader files = BlobFileReader(store);
      final StorageRoot inaccessible = StorageRoot.fake(
        documentsDirectory: Directory('unused-browser-root'),
        writable: false,
      );
      const String source = 'projects/site/photos/wide.jpg';
      final Uint8List original = Uint8List.fromList(
        img.encodeJpg(img.Image(width: 800, height: 400)),
      );
      await writer.write(Stream<List<int>>.value(original), source);
      final PhotoThumbnails first = PhotoThumbnails(
        storageRoot: inaccessible,
        files: files,
        writer: writer,
      );
      final Result<Uint8List> thumb = await first.bytesFor(
        sha256: 'wide',
        storagePath: source,
        edge: 96,
      );
      final img.Image image = img.decodeImage(
        (thumb as Success<Uint8List>).value,
      )!;
      expect((image.width, image.height), (96, 48));
      expect(backing[source], original);
      expect(backing['.cache/thumbs/wide_96'], thumb.value);
      // Reopening the service must use the persisted thumbnail, even if reading
      // the original is no longer possible.
      await store.remove(source);
      final PhotoThumbnails again = PhotoThumbnails(
        storageRoot: inaccessible,
        files: files,
        writer: writer,
      );
      final Result<Uint8List> repeated = await again.bytesFor(
        sha256: 'wide',
        storagePath: source,
        edge: 96,
      );
      expect((repeated as Success<Uint8List>).value, thumb.value);
      expect(
        await again.bytesFor(sha256: 'wide', storagePath: source, edge: 48),
        isA<FailureResult<Uint8List>>(),
      );
    },
  );

  late Directory documents;
  late StorageRoot storage;
  late PhotoThumbnails thumbnails;

  setUp(() async {
    documents = Directory.systemTemp.createTempSync('tapture-photo-thumbs-');
    storage = StorageRoot.fake(documentsDirectory: documents);
    thumbnails = PhotoThumbnails(
      storageRoot: storage,
      cache: ThumbnailCache(
        storageRoot: storage,
        decode:
            (String path, {required int longEdge, required int quality}) async {
              return Uint8List.fromList(<int>[1, 2, 3]);
            },
      ),
    );
  });

  tearDown(() {
    if (documents.existsSync()) {
      documents.deleteSync(recursive: true);
    }
  });

  test('a stored photo resolves to a cached thumbnail file', () async {
    final Directory root = switch (await storage.resolve()) {
      Success<Directory>(:final Directory value) => value,
      FailureResult<Directory>(:final Failure failure) => fail(failure.message),
    };
    File('${root.path}/projects/site/photos/a.jpg')
      ..createSync(recursive: true)
      ..writeAsStringSync('pixels');

    final Result<String> path = await thumbnails.pathFor(
      sha256: 'abc123',
      storagePath: 'projects/site/photos/a.jpg',
      edge: AppConstants.images.thumbnailEdge,
    );

    final String file = switch (path) {
      Success<String>(:final String value) => value,
      FailureResult<String>(:final Failure failure) => fail(failure.message),
    };
    expect(File(file).existsSync(), isTrue);
    expect(file.replaceAll(r'\', '/'), contains('/.cache/thumbs/abc123_'));
  });

  test('a photo whose file is gone fails with plain words', () async {
    final Result<String> path = await thumbnails.pathFor(
      sha256: 'abc123',
      storagePath: 'projects/site/photos/gone.jpg',
      edge: AppConstants.images.thumbnailEdge,
    );

    expect(path, isA<FailureResult<String>>());
    expect(
      (path as FailureResult<String>).failure.message,
      Copy.photoUnreadable,
    );
  });

  test('the fake serves only the paths it was given', () async {
    final PhotoThumbnails fake = PhotoThumbnails.fake(<String, String>{
      'projects/site/photos/a.jpg': '/cache/a_96',
    });

    expect(
      await fake.pathFor(
        sha256: 'a',
        storagePath: 'projects/site/photos/a.jpg',
        edge: 96,
      ),
      isA<Success<String>>(),
    );
    expect(
      await fake.pathFor(
        sha256: 'b',
        storagePath: 'projects/site/photos/b.jpg',
        edge: 96,
      ),
      isA<FailureResult<String>>(),
    );
  });
}

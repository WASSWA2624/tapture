import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/evidence_purge.dart';
import 'package:tapture/core/files/storage_root.dart';

const String _sha = 'a1b2c3';
const String _otherSha = 'd4e5f6';
const String _photoPath = 'projects/site-a/photos/p1.jpg';

PurgePhoto _photo({
  String photoId = 'p1',
  String sha256 = _sha,
  String storagePath = _photoPath,
  bool keepFile = false,
  bool keepCache = false,
}) {
  return (
    photoId: photoId,
    sha256: sha256,
    storagePath: storagePath,
    keepFile: keepFile,
    keepCache: keepCache,
  );
}

void main() {
  group('on device', () {
    test('a photo loses its stored file, every thumbnail, upload copy and '
        'capture copy, and nothing else', () async {
      final _Tree tree = await _Tree.open();
      final int thumb = AppConstants.images.thumbnailEdge;
      final int preview = AppConstants.images.previewEdge;
      final List<String> gone = <String>[
        _photoPath,
        '.cache/thumbs/${_sha}_$thumb',
        '.cache/thumbs/${_sha}_$preview',
        '.cache/thumbs/${_sha}_$thumb.part',
        '.cache/thumbs/p1_$thumb',
        '.cache/upload/${_sha}_${AppConstants.images.longEdge}',
        '.cache/capture-src/p1',
        '.cache/capture-src/p1.part',
      ];
      final List<String> kept = <String>[
        'projects/site-a/photos/p2.jpg',
        '.cache/thumbs/${_otherSha}_$thumb',
        '.cache/thumbs/p2_$thumb',
        '.cache/thumbs/$_sha',
        '.cache/thumbs/${_sha}_large',
        '.cache/thumbs/x${_sha}_$thumb',
        '.cache/capture-src/p2',
        '.cache/capture-src/p10',
        '.cache/upload/${_otherSha}_${AppConstants.images.longEdge}',
        'projects/site-a/documents/p1.pdf',
      ];
      tree.write(<String>[...gone, ...kept]);

      final int removed = _ok(
        await tree.purge.removePhotos(<PurgePhoto>[_photo()]),
      );

      expect(removed, gone.length);
      for (final String path in gone) {
        expect(tree.exists(path), isFalse, reason: path);
      }
      for (final String path in kept) {
        expect(tree.exists(path), isTrue, reason: path);
      }
    });

    test('a stored file that is already gone counts as removed', () async {
      final _Tree tree = await _Tree.open();
      tree.write(<String>['projects/site-a/photos/p2.jpg']);

      final int removed = _ok(
        await tree.purge.removePhotos(<PurgePhoto>[
          _photo(),
          _photo(
            photoId: 'p9',
            sha256: _otherSha,
            storagePath: 'projects/gone-folder/photos/p9.jpg',
          ),
        ]),
      );

      expect(removed, 2);
      expect(tree.exists('projects/site-a/photos/p2.jpg'), isTrue);
    });

    test('running the same purge twice removes nothing more and '
        'still succeeds', () async {
      final _Tree tree = await _Tree.open();
      tree.write(<String>[
        _photoPath,
        '.cache/thumbs/${_sha}_${AppConstants.images.thumbnailEdge}',
      ]);

      expect(_ok(await tree.purge.removePhotos(<PurgePhoto>[_photo()])), 2);
      expect(_ok(await tree.purge.removePhotos(<PurgePhoto>[_photo()])), 1);
      expect(tree.exists(_photoPath), isFalse);
    });

    test('a file another row still names is kept, and so are the copies of '
        'a hash another photo shares', () async {
      final _Tree tree = await _Tree.open();
      final int edge = AppConstants.images.thumbnailEdge;
      tree.write(<String>[
        _photoPath,
        '.cache/thumbs/${_sha}_$edge',
        '.cache/upload/${_sha}_${AppConstants.images.longEdge}',
        '.cache/thumbs/p1_$edge',
        '.cache/capture-src/p1',
      ]);

      final int removed = _ok(
        await tree.purge.removePhotos(<PurgePhoto>[
          _photo(keepFile: true, keepCache: true),
        ]),
      );

      expect(removed, 2);
      expect(tree.exists(_photoPath), isTrue);
      expect(tree.exists('.cache/thumbs/${_sha}_$edge'), isTrue);
      expect(
        tree.exists('.cache/upload/${_sha}_${AppConstants.images.longEdge}'),
        isTrue,
      );
      expect(tree.exists('.cache/thumbs/p1_$edge'), isFalse);
      expect(tree.exists('.cache/capture-src/p1'), isFalse);
    });

    test('a path outside a project folder is refused before anything is '
        'removed', () async {
      for (final String bad in <String>[
        '.cache/thumbs/${_sha}_96',
        'projects/site-a',
        'projects/../settings.json',
        '../outside.jpg',
        '/absolute/p1.jpg',
        'C:/Users/p1.jpg',
        'exports/site-a/p1.jpg',
        '',
      ]) {
        final _Tree tree = await _Tree.open();
        tree.write(<String>[_photoPath, '.cache/thumbs/${_sha}_96']);

        final Result<int> result = await tree.purge.removePhotos(<PurgePhoto>[
          _photo(),
          _photo(photoId: 'p2', sha256: _otherSha, storagePath: bad),
        ]);

        expect(_failure(result), isA<ValidationFailure>(), reason: bad);
        expect(tree.exists(_photoPath), isTrue, reason: bad);
        expect(tree.exists('.cache/thumbs/${_sha}_96'), isTrue, reason: bad);
      }
    });

    test('a photo whose id or hash could leave its cache folder is '
        'refused', () async {
      for (final PurgePhoto bad in <PurgePhoto>[
        _photo(sha256: '../thumbs'),
        _photo(sha256: r'a\b'),
        _photo(photoId: 'p1/..'),
      ]) {
        final _Tree tree = await _Tree.open();
        tree.write(<String>[_photoPath]);

        final Result<int> result = await tree.purge.removePhotos(<PurgePhoto>[
          bad,
        ]);

        expect(_failure(result), isA<ValidationFailure>());
        expect(tree.exists(_photoPath), isTrue);
      }
    });

    test('documents and audio go by path, and a missing one counts', () async {
      final _Tree tree = await _Tree.open();
      tree.write(<String>[
        'projects/site-a/documents/manual.pdf',
        'projects/site-a/audio/note.m4a',
        'projects/site-a/audio/other.m4a',
      ]);

      final int removed = _ok(
        await tree.purge.removeFiles(<String>[
          'projects/site-a/documents/manual.pdf',
          r'projects\site-a\audio\note.m4a',
          'projects/site-a/audio/never-written.m4a',
        ]),
      );

      expect(removed, 3);
      expect(tree.exists('projects/site-a/documents/manual.pdf'), isFalse);
      expect(tree.exists('projects/site-a/audio/note.m4a'), isFalse);
      expect(tree.exists('projects/site-a/audio/other.m4a'), isTrue);
      expect(
        _failure(await tree.purge.removeFiles(<String>['../escape.pdf'])),
        isA<ValidationFailure>(),
      );
    });

    test('a storage root that cannot be opened removes nothing and says '
        'why', () async {
      final Directory documents = _tempDir();
      final EvidencePurge purge = EvidencePurge(
        storageRoot: StorageRoot.fake(
          documentsDirectory: documents,
          writable: false,
        ),
      );

      expect(
        _failure(await purge.removePhotos(<PurgePhoto>[_photo()])),
        isA<StorageFailure>(),
      );
      expect(
        _failure(await purge.removeFiles(<String>[_photoPath])),
        isA<StorageFailure>(),
      );
    });

    test('a stored file the device refuses to delete stops the purge with a '
        'storage failure', () async {
      final _Tree tree = await _Tree.open();
      // A folder where the photo should be: the file system will not delete
      // it as a file.
      tree.write(<String>['$_photoPath/inside.bin']);

      final Result<int> result = await tree.purge.removePhotos(<PurgePhoto>[
        _photo(),
      ]);

      expect(_failure(result), isA<StorageFailure>());
      expect(tree.exists('$_photoPath/inside.bin'), isTrue);
    });

    test(
      'nothing asked, nothing removed, even without a storage root',
      () async {
        final EvidencePurge purge = EvidencePurge(
          storageRoot: StorageRoot.fake(
            documentsDirectory: _tempDir(),
            writable: false,
          ),
        );

        expect(_ok(await purge.removePhotos(const <PurgePhoto>[])), 0);
        expect(_ok(await purge.removeFiles(const <String>[])), 0);
      },
    );

    test('the provider purges under the process storage root', () async {
      final _Tree tree = await _Tree.open();
      tree.write(<String>[_photoPath]);
      final ProviderContainer container = ProviderContainer(
        overrides: [storageRootProvider.overrideWith((Ref _) => tree.storage)],
      );
      addTearDown(container.dispose);

      final EvidencePurge purge = container.read(evidencePurgeProvider);

      expect(_ok(await purge.removePhotos(<PurgePhoto>[_photo()])), 1);
      expect(tree.exists(_photoPath), isFalse);
    });
  });

  group('over a keyed store', () {
    test('a browser loses the photo, its thumbnails, upload copy and capture '
        'copy, and nothing else', () async {
      final int thumb = AppConstants.images.thumbnailEdge;
      final int preview = AppConstants.images.previewEdge;
      final List<String> gone = <String>[
        _photoPath,
        '.cache/thumbs/${_sha}_$thumb',
        '.cache/thumbs/${_sha}_$preview',
        '.cache/thumbs/p1_$thumb',
        '.cache/upload/${_sha}_${AppConstants.images.longEdge}',
        '.cache/capture-src/p1',
      ];
      final List<String> kept = <String>[
        'projects/site-a/photos/p2.jpg',
        '.cache/thumbs/${_otherSha}_$thumb',
        '.cache/capture-src/p2',
      ];
      final Map<String, Uint8List> backing = <String, Uint8List>{
        for (final String key in <String>[...gone, ...kept])
          key: Uint8List.fromList(<int>[1]),
      };
      final EvidencePurge purge = EvidencePurge.store(
        BlobStore.memory(backing: backing),
      );

      expect(_ok(await purge.removePhotos(<PurgePhoto>[_photo()])), 1);

      expect(backing.keys, unorderedEquals(kept));
    });

    test('a key that is not there removes as a success, and a shared file '
        'and hash stay', () async {
      final int thumb = AppConstants.images.thumbnailEdge;
      final Map<String, Uint8List> backing = <String, Uint8List>{
        _photoPath: Uint8List.fromList(<int>[1]),
        '.cache/thumbs/${_sha}_$thumb': Uint8List.fromList(<int>[1]),
        '.cache/capture-src/p1': Uint8List.fromList(<int>[1]),
      };
      final EvidencePurge purge = EvidencePurge.store(
        BlobStore.memory(backing: backing),
      );

      expect(
        _ok(
          await purge.removePhotos(<PurgePhoto>[
            _photo(keepFile: true, keepCache: true),
          ]),
        ),
        0,
      );
      expect(
        backing.keys,
        unorderedEquals(<String>[_photoPath, '.cache/thumbs/${_sha}_$thumb']),
      );
      expect(
        _ok(
          await purge.removeFiles(<String>[
            'projects/site-a/documents/never-written.pdf',
          ]),
        ),
        1,
      );
    });

    test('a store that refuses a removal fails the purge', () async {
      final EvidencePurge purge = EvidencePurge.store(
        BlobStore.memory(
          backing: <String, Uint8List>{
            _photoPath: Uint8List.fromList(<int>[1]),
          },
          failWrites: true,
        ),
      );

      expect(
        _failure(await purge.removePhotos(<PurgePhoto>[_photo()])),
        isA<StorageFailure>(),
      );
      expect(
        _failure(await purge.removeFiles(<String>[_photoPath])),
        isA<StorageFailure>(),
      );
    });

    test(
      'a path outside a project folder is refused by the store too',
      () async {
        final Map<String, Uint8List> backing = <String, Uint8List>{
          _photoPath: Uint8List.fromList(<int>[1]),
        };
        final EvidencePurge purge = EvidencePurge.store(
          BlobStore.memory(backing: backing),
        );

        final Result<int> result = await purge.removePhotos(<PurgePhoto>[
          _photo(),
          _photo(photoId: 'p2', storagePath: '.cache/thumbs/x_96'),
        ]);

        expect(_failure(result), isA<ValidationFailure>());
        expect(backing.keys, <String>[_photoPath]);
      },
    );
  });

  group('names', () {
    test('an evidence path stays inside a project folder', () {
      expect(
        EvidencePurge.evidencePath(r'projects\site-a\photos\p1.jpg'),
        _photoPath,
      );
      expect(
        () => EvidencePurge.evidencePath('projects/site-a'),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => EvidencePurge.evidencePath('.recycle/site-a/photos/p1.jpg'),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('a cached copy belongs to the key before its edge', () {
      expect(EvidencePurge.copyOwner('${_sha}_96'), _sha);
      expect(EvidencePurge.copyOwner('${_sha}_256.part'), _sha);
      expect(EvidencePurge.copyOwner('photo_id_96'), 'photo_id');
      expect(EvidencePurge.copyOwner(_sha), isNull);
      expect(EvidencePurge.copyOwner('${_sha}_'), isNull);
      expect(EvidencePurge.copyOwner('_96'), isNull);
      expect(EvidencePurge.copyOwner('${_sha}_96.jpg'), isNull);
    });

    test('a cache key has no separator or parent step', () {
      expect(EvidencePurge.cacheKey(_sha), _sha);
      for (final String bad in <String>['', 'a/b', r'a\b', '..', 'a..b']) {
        expect(
          () => EvidencePurge.cacheKey(bad),
          throwsA(isA<ValidationFailure>()),
          reason: bad,
        );
      }
    });
  });
}

/// A storage root over a temporary folder, removed after the test.
final class _Tree {
  _Tree._(this.storage, this.root)
    : purge = EvidencePurge(storageRoot: storage);

  final StorageRoot storage;
  final Directory root;
  final EvidencePurge purge;

  static Future<_Tree> open() async {
    final StorageRoot storage = StorageRoot.fake(
      documentsDirectory: _tempDir(),
    );
    final Directory root = _ok(await storage.resolve());
    return _Tree._(storage, root);
  }

  /// Writes a small file at each of [paths], relative to the root.
  void write(List<String> paths) {
    for (final String path in paths) {
      File('${root.path}/$path')
        ..createSync(recursive: true)
        ..writeAsBytesSync(<int>[1, 2, 3]);
    }
  }

  bool exists(String path) => File('${root.path}/$path').existsSync();
}

Directory _tempDir() {
  final Directory documents = Directory.systemTemp.createTempSync(
    'tapture-evidence-purge-',
  );
  addTearDown(() {
    if (documents.existsSync()) {
      documents.deleteSync(recursive: true);
    }
  });
  return documents;
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => fail(failure.message),
  };
}

Failure _failure<T>(Result<T> result) {
  return switch (result) {
    Success<T>() => fail('expected a failure'),
    FailureResult<T>(:final Failure failure) => failure,
  };
}

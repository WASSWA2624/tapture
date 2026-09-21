import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/features/settings/data/settings_store.dart';
import 'package:tapture/features/settings/domain/setting_keys.dart';

void main() {
  test(
    'resolve creates Tapture and .cache once and returns the same directory',
    () async {
      final Directory documents = _tempDocs();
      final StorageRoot storage = StorageRoot.fake(
        documentsDirectory: documents,
      );

      final Directory first = _ok(await storage.resolve());
      File('${first.path}/sentinel.txt').writeAsStringSync('kept');
      final Directory second = _ok(await storage.resolve());
      final Directory cache = _ok(await storage.cacheDir());

      expect(identical(first, second), isTrue);
      expect(_slash(second.path), _slash('${documents.path}/Tapture'));
      expect(_slash(cache.path), '${_slash(first.path)}/.cache');
      expect(first.existsSync(), isTrue);
      expect(cache.existsSync(), isTrue);
      expect(File('${first.path}/sentinel.txt').readAsStringSync(), 'kept');
      expect(_hasNomedia(first), isFalse);
    },
  );

  test('a missing or unwritable location is a StorageFailure with a recovery '
      'action', () async {
    final Directory documents = _tempDocs();
    File('${documents.path}/Tapture').writeAsStringSync('blocked');
    final StorageRoot missing = StorageRoot(
      documentsDirectory: () async => documents,
    );

    final Result<Directory> blocked = await missing.resolve();
    final Failure? blockedFailure = blocked.fold(
      (Failure failure) => failure,
      (_) => null,
    );

    expect(blockedFailure, isA<StorageFailure>());
    expect(blockedFailure?.message, contains(documents.path));
    expect(blockedFailure?.recoveryAction, isNotEmpty);

    final Directory readOnlyDocs = _tempDocs();
    final StorageRoot readOnly = StorageRoot.fake(
      documentsDirectory: readOnlyDocs,
      writable: false,
    );
    final Result<Directory> refused = await readOnly.resolve();
    final Failure? refusedFailure = refused.fold(
      (Failure failure) => failure,
      (_) => null,
    );

    expect(refusedFailure, isA<StorageFailure>());
    expect(refusedFailure?.message, contains('Tapture'));
    expect(refusedFailure?.recoveryAction, isNotEmpty);
    expect(Directory('${readOnlyDocs.path}/Tapture').existsSync(), isFalse);

    final Result<Directory> retried = await readOnly.resolve();
    expect(
      retried.fold((Failure failure) => failure, (_) => null),
      isA<StorageFailure>(),
    );
  });

  test('resolving the root never asks for a permission', () async {
    final Directory documents = _tempDocs();
    final StorageRoot storage = StorageRoot.fake(documentsDirectory: documents);

    final Directory root = _ok(await storage.resolve());

    expect(_slash(root.path), _slash('${documents.path}/Tapture'));
    expect(root.existsSync(), isTrue);
    expect(Directory('${root.path}/.cache').existsSync(), isTrue);
    expect(storageRootProvider, isA<Provider<StorageRoot>>());
  });

  test('the public folder is used when it is writable', () async {
    final Directory shared = _tempDocs();
    final Directory app = _tempDocs();
    final StorageRoot storage = StorageRoot(
      documentsDirectory: () async => app,
      publicDocuments: () async => shared,
    );

    final Directory root = _ok(await storage.resolve());
    final Directory again = _ok(await storage.resolve());

    expect(identical(root, again), isTrue);
    expect(_slash(root.path), _slash('${shared.path}/Tapture'));
    expect(root.existsSync(), isTrue);
    expect(Directory('${root.path}/.cache').existsSync(), isTrue);
    expect(Directory('${app.path}/Tapture').existsSync(), isFalse);
    expect(_hasNomedia(root), isFalse);
  });

  test('an unsupported public folder falls back to the app folder', () async {
    final Directory app = _tempDocs();
    final StorageRoot storage = StorageRoot(
      documentsDirectory: () async => app,
      publicDocuments: () async {
        throw PlatformException(code: 'unsupported');
      },
    );

    final Directory root = _ok(await storage.resolve());

    expect(_slash(root.path), _slash('${app.path}/Tapture'));
    expect(root.existsSync(), isTrue);
  });

  test('an unwritable public folder falls back to the app folder', () async {
    final Directory shared = _tempDocs();
    final Directory app = _tempDocs();
    File('${shared.path}/Tapture').writeAsStringSync('blocked');
    final StorageRoot storage = StorageRoot(
      documentsDirectory: () async => app,
      publicDocuments: () async => shared,
    );

    final Directory root = _ok(await storage.resolve());

    expect(_slash(root.path), _slash('${app.path}/Tapture'));
    expect(root.existsSync(), isTrue);
    expect(File('${shared.path}/Tapture').existsSync(), isTrue);
    expect(File('${shared.path}/Tapture').readAsStringSync(), 'blocked');
  });

  test('both locations unwritable is a StorageFailure', () async {
    final Directory shared = _tempDocs();
    final Directory app = _tempDocs();
    File('${shared.path}/Tapture').writeAsStringSync('blocked');
    File('${app.path}/Tapture').writeAsStringSync('blocked');
    final StorageRoot storage = StorageRoot(
      documentsDirectory: () async => app,
      publicDocuments: () async => shared,
    );

    final Result<Directory> refused = await storage.resolve();
    final Failure? failure = refused.fold(
      (Failure value) => value,
      (_) => null,
    );

    expect(failure, isA<StorageFailure>());
    expect(failure?.message, contains(app.path));
    expect(failure?.recoveryAction, isNotEmpty);
    expect(File('${app.path}/Tapture').readAsStringSync(), 'blocked');
    expect(File('${shared.path}/Tapture').readAsStringSync(), 'blocked');
  });

  test('an empty preferred path uses the Documents fallback', () async {
    final Directory documents = _tempDocs();
    final StorageRoot storage = StorageRoot.fake(
      documentsDirectory: documents,
      preferredPath: '',
    );

    final Directory root = _ok(await storage.resolve());

    expect(_slash(root.path), _slash('${documents.path}/Tapture'));
  });

  test('a stored root path is what the next resolve returns', () async {
    final Directory documents = _tempDocs();
    final Directory chosen = _tempDocs();
    final SettingsStore store = SettingsStore.fake();
    await store.write(SettingKeys.storageRootPath, chosen.path);
    final StorageRoot storage = StorageRoot.fake(
      documentsDirectory: documents,
      preferredPath: store.read(SettingKeys.storageRootPath),
    );

    final Directory root = _ok(await storage.resolve());

    expect(_slash(root.path), _slash(chosen.path));
    expect(store.read(SettingKeys.storageRootPath), chosen.path);
  });

  test('a saved writable folder is the path resolve returns', () async {
    final Directory documents = _tempDocs();
    final Directory chosen = _tempDocs();
    final StorageRoot storage = StorageRoot.fake(
      documentsDirectory: documents,
      preferredPath: chosen.path,
    );

    final Directory root = _ok(await storage.resolve());

    expect(_slash(root.path), _slash(chosen.path));
    expect(Directory('${root.path}/.cache').existsSync(), isTrue);
    expect(Directory('${documents.path}/Tapture').existsSync(), isFalse);
  });

  test('a failed preferred probe falls back to Documents', () async {
    final Directory documents = _tempDocs();
    final Directory chosen = _tempDocs();
    final StorageRoot storage = StorageRoot.fake(
      documentsDirectory: documents,
      preferredPath: chosen.path,
      preferredWritable: false,
    );

    final Directory root = _ok(await storage.resolve());

    expect(_slash(root.path), _slash('${documents.path}/Tapture'));
    expect(chosen.listSync(), isEmpty);
  });

  test('openAt probes the path without falling back', () async {
    final Directory documents = _tempDocs();
    final Directory chosen = _tempDocs();
    final StorageRoot storage = StorageRoot.fake(documentsDirectory: documents);

    final Directory opened = _ok(await storage.openAt(chosen.path));
    expect(_slash(opened.path), _slash(chosen.path));

    final StorageRoot blocked = StorageRoot.fake(
      documentsDirectory: documents,
      preferredWritable: false,
    );
    final Result<Directory> refused = await blocked.openAt(chosen.path);
    expect(
      refused.fold((Failure failure) => failure, (_) => null),
      isA<StorageFailure>(),
    );
  });
}

Directory _tempDocs() {
  final Directory directory = Directory.systemTemp.createTempSync(
    'tapture-root-',
  );
  addTearDown(() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });
  return directory;
}

Directory _ok(Result<Directory> result) {
  return result.fold((Failure failure) {
    fail('${failure.message} ${failure.recoveryAction}');
  }, (Directory directory) => directory);
}

bool _hasNomedia(Directory root) {
  final File atRoot = File('${root.path}/.nomedia');
  if (atRoot.existsSync()) {
    return true;
  }
  for (final FileSystemEntity entity in root.listSync(recursive: true)) {
    final String name = entity.uri.pathSegments.isEmpty
        ? ''
        : entity.uri.pathSegments.last;
    if (name.toLowerCase() == '.nomedia') {
      return true;
    }
  }
  return false;
}

String _slash(String path) => path.replaceAll(r'\', '/');

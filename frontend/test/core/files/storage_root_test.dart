import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/permissions/permissions.dart';

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

  test(
    'a storage denial is a typed failure and leaves the app usable',
    () async {
      final Directory documents = _tempDocs();
      final StorageRoot storage = StorageRoot.fake(
        documentsDirectory: documents,
        permissions: PermissionsService.fake(
          states: const <AppPermission, PermissionState>{
            AppPermission.storage: PermissionState.denied,
          },
        ),
      );

      final Result<Directory> denied = await storage.resolve();
      final Failure? failure = denied.fold(
        (Failure value) => value,
        (_) => null,
      );

      expect(failure, isA<PermissionFailure>());
      expect(failure?.recoveryAction, isNotEmpty);
      expect(Directory('${documents.path}/Tapture').existsSync(), isFalse);
      expect(storageRootProvider, isA<Provider<StorageRoot>>());
    },
  );
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

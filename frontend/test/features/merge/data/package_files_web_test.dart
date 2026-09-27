@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/features/merge/data/package_files.dart';
import 'package:tapture/features/merge/data/package_files_web.dart';

/// Runs under `flutter test --platform chrome`; the VM skips it, since a
/// browser's project file store is IndexedDB.
void main() {
  test('a browser keeps package files in the project file store', () async {
    final PackageFiles files = openPackageFiles(storageRoot: StorageRoot());
    const String path = 'projects/web/photos/a.jpg';
    await files.write(path, Uint8List.fromList(<int>[6, 7]));
    expect(await files.exists(path), isTrue);
    await files.remove(path);
    expect(await files.exists(path), isFalse);
  });
}

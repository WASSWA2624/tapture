import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/features/merge/data/package_files.dart';
import 'package:tapture/features/merge/data/package_files_stub.dart';

void main() {
  test('with neither a file system nor a browser, files are held in the '
      'shared memory store', () async {
    final PackageFiles files = openPackageFiles(
      storageRoot: StorageRoot.fake(documentsDirectory: Directory.systemTemp),
    );
    const String path = 'projects/stub/photos/a.jpg';
    await files.write(path, Uint8List.fromList(<int>[4, 5]));
    expect(await files.exists(path), isTrue);
    await files.remove(path);
    expect(await files.exists(path), isFalse);
  });
}

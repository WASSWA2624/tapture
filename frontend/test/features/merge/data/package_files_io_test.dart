import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/features/merge/data/package_files_io.dart';

void main() {
  late Directory documents;
  late StorageRoot root;

  setUp(() {
    documents = Directory.systemTemp.createTempSync('tapture-package-files-');
    root = StorageRoot.fake(documentsDirectory: documents);
  });

  tearDown(() {
    if (documents.existsSync()) {
      documents.deleteSync(recursive: true);
    }
  });

  test('a device writes under the storage root, and removes a file or a '
      'whole folder', () async {
    final files = openPackageFiles(storageRoot: root);
    final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3]);
    const String path = 'projects/pumps/photos/a.jpg';

    expect(await files.exists('projects/pumps'), isFalse);
    expect(await files.write(path, bytes), isA<Success<WrittenFile>>());
    final File landed = File('${documents.path}/Tapture/$path');
    expect(landed.readAsBytesSync(), bytes);
    expect(await files.exists(path), isTrue);
    expect(await files.exists('projects/pumps'), isTrue);

    await files.remove(path);
    expect(landed.existsSync(), isFalse);
    await files.remove(path);

    await files.write('projects/pumps/audio/b.m4a', bytes);
    await files.removeFolder('projects/pumps');
    expect(
      Directory('${documents.path}/Tapture/projects/pumps').existsSync(),
      isFalse,
    );
  });

  test('a path that would leave the storage root is never touched', () async {
    final files = openPackageFiles(storageRoot: root);
    final File outside = File('${documents.path}/outside.txt')
      ..writeAsStringSync('keep');
    expect(await files.exists('../outside.txt'), isFalse);
    await files.remove('../outside.txt');
    await files.removeFolder('..');
    expect(outside.existsSync(), isTrue);
  });
}

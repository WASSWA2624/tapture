import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/project_tree_io.dart';
import 'package:tapture/core/files/storage_root.dart';

void main() {
  late Directory documents;
  late Directory chosen;
  late StorageRoot root;

  setUp(() {
    documents = Directory.systemTemp.createTempSync('tapture-tree-docs-');
    chosen = Directory.systemTemp.createTempSync('tapture-tree-chosen-');
    addTearDown(() {
      for (final Directory directory in <Directory>[documents, chosen]) {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      }
    });
    root = StorageRoot.fake(
      documentsDirectory: documents,
      preferredPath: chosen.path,
    );
  });

  test('a project tree is created under the chosen storage root', () async {
    _ok(
      await writeProjectTree(
        id: 'p1',
        name: 'Alpha',
        folderName: 'Alpha__000001',
        storageRoot: root,
      ),
    );

    expect(
      Directory('${chosen.path}/projects/Alpha__000001/photos').existsSync(),
      isTrue,
    );
    expect(
      Directory('${documents.path}/Tapture/projects').existsSync(),
      isFalse,
    );
  });

  test('a deleted project is recycled inside the chosen root', () async {
    _ok(
      await writeProjectTree(
        id: 'p1',
        name: 'Alpha',
        folderName: 'Alpha__000001',
        storageRoot: root,
      ),
    );
    File(
      '${chosen.path}/projects/Alpha__000001/photos/shot.jpg',
    ).writeAsBytesSync(<int>[1, 2, 3]);

    _ok(
      await recycleProjectTree(
        id: 'p1',
        name: 'Alpha',
        folderName: 'Alpha__000001',
        storageRoot: root,
      ),
    );

    expect(
      Directory('${chosen.path}/projects/Alpha__000001').existsSync(),
      isFalse,
    );
    expect(
      File(
        '${chosen.path}/.recycle/Alpha__000001/photos/shot.jpg',
      ).readAsBytesSync(),
      <int>[1, 2, 3],
    );
  });

  test(
    'restore adapter moves the chosen tree back with identical evidence',
    () async {
      _ok(
        await writeProjectTree(
          id: 'p1',
          name: 'Alpha',
          folderName: 'Alpha__000001',
          storageRoot: root,
        ),
      );
      final File evidence = File(
        '${chosen.path}/projects/Alpha__000001/audio/meeting.wav',
      );
      evidence.writeAsBytesSync(<int>[0, 255, 42], flush: true);
      _ok(
        await recycleProjectTree(
          id: 'p1',
          name: 'Alpha',
          folderName: 'Alpha__000001',
          storageRoot: root,
        ),
      );
      _ok(
        await restoreProjectTree(
          id: 'p1',
          name: 'Alpha',
          folderName: 'Alpha__000001',
          storageRoot: root,
        ),
      );
      expect(evidence.readAsBytesSync(), <int>[0, 255, 42]);
      expect(
        Directory('${chosen.path}/.recycle/Alpha__000001').existsSync(),
        isFalse,
      );
    },
  );

  test('a failed create is discarded from the chosen root', () async {
    _ok(
      await writeProjectTree(
        id: 'p2',
        name: 'Beta',
        folderName: 'Beta__000002',
        storageRoot: root,
      ),
    );

    _ok(
      await discardProjectTree(
        id: 'p2',
        name: 'Beta',
        folderName: 'Beta__000002',
        storageRoot: root,
      ),
    );

    expect(
      Directory('${chosen.path}/projects/Beta__000002').existsSync(),
      isFalse,
    );
  });
}

void _ok(Result<void> result) {
  result.fold((Failure failure) {
    fail('${failure.message} ${failure.recoveryAction}');
  }, (_) {});
}

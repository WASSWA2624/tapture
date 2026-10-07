import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/projects.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/project_folders.dart';
import 'package:tapture/core/files/storage_root.dart';

void main() {
  test(
    'create is idempotent and two same names get distinct folders',
    () async {
      final ProjectFolders folders = _folders();
      final Project first = _project(
        id: 'id-aaaaaa',
        name: 'Medical / Equipment 😀 Café ${'x' * 300}',
      );

      final Directory created = _ok(await folders.create(first));
      File('${created.path}/photos/keep.txt').writeAsStringSync('kept');
      final Directory again = _ok(await folders.create(first));
      final Project twin = _project(id: 'id-bbbbbb', name: first.name);
      final Directory other = _ok(await folders.create(twin));

      expect(_slash(again.path), _slash(created.path));
      expect(
        File('${created.path}/photos/keep.txt').readAsStringSync(),
        'kept',
      );
      expect(_slash(other.path), isNot(_slash(created.path)));
      expect(_slash(created.path), contains('/projects/'));
      expect(_basename(created.path), contains('__'));
      expect(_basename(created.path), isNot(contains('/')));
      expect(_basename(created.path).length, lessThanOrEqualTo(90));
      for (final String child in _tree) {
        expect(Directory('${created.path}/$child').existsSync(), isTrue);
      }
    },
  );

  test(
    'renaming the project does not move the folder or stored files',
    () async {
      final ProjectFolders folders = _folders();
      const String folderName = 'alpha__aaaaaa';
      final Project original = _project(
        id: 'id-aaaaaa',
        name: 'Alpha',
        folderName: folderName,
      );

      final Directory created = _ok(await folders.create(original));
      File('${created.path}/photos/keep.txt').writeAsStringSync('kept');
      final Directory resolved = _ok(
        await folders.resolve(
          _project(
            id: original.id,
            name: 'Alpha Renamed',
            folderName: folderName,
          ),
        ),
      );

      expect(_slash(resolved.path), _slash(created.path));
      expect(_basename(resolved.path), folderName);
      expect(
        File('${resolved.path}/photos/keep.txt').readAsStringSync(),
        'kept',
      );
    },
  );

  test('discard removes a partial tree and succeeds when missing', () async {
    final ProjectFolders folders = _folders();
    final Project project = _project(
      id: 'id-cccccc',
      name: 'Partial',
      folderName: 'partial__cccccc',
    );
    final Directory created = _ok(await folders.create(project));
    expect(created.existsSync(), isTrue);
    _okVoid(await folders.discard(project));
    expect(created.existsSync(), isFalse);
    _okVoid(await folders.discard(project));
  });

  test('recycle moves the folder and leaves the file on disk', () async {
    final ProjectFolders folders = _folders();
    final Project project = _project(
      id: 'id-dddddd',
      name: 'Done',
      folderName: 'done__dddddd',
    );
    final Directory created = _ok(await folders.create(project));
    File('${created.path}/photos/keep.txt').writeAsStringSync('kept');
    final Directory recycled = _ok(await folders.recycle(project));

    expect(created.existsSync(), isFalse);
    expect(recycled.existsSync(), isTrue);
    expect(_slash(recycled.path), contains('/.recycle/'));
    expect(File('${recycled.path}/photos/keep.txt').readAsStringSync(), 'kept');
    _ok(await folders.recycle(project));
  });
  test(
    'restore preserves bytes and supports a retry after the tree moved',
    () async {
      final ProjectFolders folders = _folders();
      final Project project = _project(
        id: 'id-restored',
        name: 'Restore',
        folderName: 'restore__123456',
      );
      final Directory created = _ok(await folders.create(project));
      final List<int> bytes = List<int>.generate(1024, (int i) => i % 256);
      File(
        '${created.path}/documents/evidence.bin',
      ).writeAsBytesSync(bytes, flush: true);
      final Directory recycled = _ok(await folders.recycle(project));
      final Directory restored = _ok(await folders.restore(project));
      expect(recycled.existsSync(), isFalse);
      expect(restored.path, created.path);
      expect(
        File('${restored.path}/documents/evidence.bin').readAsBytesSync(),
        bytes,
      );
      expect(_ok(await folders.restore(project)).path, restored.path);
    },
  );

  for (final bool file in <bool>[false, true]) {
    test(
      'restore refuses a live ${file ? 'file' : 'folder'} collision without changing either copy',
      () async {
        final ProjectFolders folders = _folders();
        final Project project = _project(
          id: 'id-collision',
          name: 'Collision',
          folderName: 'collision__123456',
        );
        final Directory created = _ok(await folders.create(project));
        File(
          '${created.path}/documents/kept.txt',
        ).writeAsStringSync('original');
        final Directory recycled = _ok(await folders.recycle(project));
        if (file) {
          File(created.path).writeAsStringSync('live file');
        } else {
          created.createSync();
          File('${created.path}/live.txt').writeAsStringSync('live folder');
        }
        expect(await folders.restore(project), isA<FailureResult<Directory>>());
        expect(
          File('${recycled.path}/documents/kept.txt').readAsStringSync(),
          'original',
        );
        expect(
          file
              ? File(created.path).readAsStringSync()
              : File('${created.path}/live.txt').readAsStringSync(),
          file ? 'live file' : 'live folder',
        );
      },
    );
  }

  test(
    'missing trees and path escapes fail, while folderless legacy rows recover',
    () async {
      final ProjectFolders folders = _folders();
      for (final String folder in <String>[
        'missing__123456',
        '../escape',
        r'..\escape',
        'C:escape',
        '.hidden',
      ]) {
        expect(
          await folders.restore(
            _project(id: 'missing', name: 'Missing', folderName: folder),
          ),
          isA<FailureResult<Directory>>(),
        );
      }
      expect(
        await folders.restore(_project(id: 'legacy', name: 'Legacy')),
        isA<Success<Directory>>(),
      );
    },
  );

  test('unwritable storage fails before restoring', () async {
    final Directory documents = Directory.systemTemp.createTempSync(
      'tapture-restore-denied-',
    );
    addTearDown(() => documents.deleteSync(recursive: true));
    final ProjectFolders folders = ProjectFolders(
      storageRoot: StorageRoot.fake(
        documentsDirectory: documents,
        writable: false,
      ),
    );
    expect(
      await folders.restore(
        _project(id: 'denied', name: 'Denied', folderName: 'denied__123456'),
      ),
      isA<FailureResult<Directory>>(),
    );
  });
}

ProjectFolders _folders() {
  final Directory documents = Directory.systemTemp.createTempSync(
    'tapture-folders-',
  );
  addTearDown(() {
    if (documents.existsSync()) {
      documents.deleteSync(recursive: true);
    }
  });
  return ProjectFolders(
    storageRoot: StorageRoot.fake(documentsDirectory: documents),
  );
}

Project _project({
  required String id,
  required String name,
  String folderName = '',
}) {
  return Project(
    id: id,
    createdAt: DateTime.utc(2026, 9, 17),
    updatedAt: DateTime.utc(2026, 9, 17),
    updatedByDevice: 'test',
    rev: 1,
    name: name,
    client: '',
    status: ProjectStatus.active,
    folderName: folderName,
    settings: '{}',
  );
}

Directory _ok(Result<Directory> result) {
  return result.fold((Failure failure) {
    fail('${failure.message} ${failure.recoveryAction}');
  }, (Directory directory) => directory);
}

void _okVoid(Result<void> result) {
  result.fold((Failure failure) {
    fail('${failure.message} ${failure.recoveryAction}');
  }, (void _) {});
}

String _slash(String path) => path.replaceAll(r'\', '/');

String _basename(String path) {
  final String normalised = _slash(path);
  final int slash = normalised.lastIndexOf('/');
  return slash == -1 ? normalised : normalised.substring(slash + 1);
}

const List<String> _tree = <String>[
  'photos',
  'documents',
  'audio',
  'meetings',
  'reference',
  'templates',
  'exports',
  'imports',
];

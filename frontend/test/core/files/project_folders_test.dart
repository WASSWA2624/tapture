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

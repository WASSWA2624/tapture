import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/features/projects/data/project_openable_file_lookup_io.dart';
import 'package:tapture/features/projects/domain/project_openable_file_lookup.dart';

import '../../../support/factories.dart';
import '../../templates/fakes/fake_template_repository.dart';

void main() {
  test('an imported workbook wins over a newer export', () async {
    final _Disk disk = await _disk();
    _ok(
      await disk.templates.save(
        aTemplate().copyWith(
          source: 'imported',
          sourceFilePath: 'projects/test-project/templates/book.xlsx',
        ),
      ),
    );
    _write(disk.root, 'projects/test-project/templates/book.xlsx', <int>[
      1,
      2,
      3,
    ]);
    _write(disk.root, 'projects/test-project/exports/later.xlsx', <int>[
      9,
      9,
      9,
    ]);

    final ProjectOpenableFile? file = _ok(
      await disk.lookup.find(
        projectId: 'project-1',
        folderName: 'test-project',
      ),
    );

    expect(file?.fileName, 'book.xlsx');
    expect(file?.bytes, <int>[1, 2, 3]);
    expect(
      file?.mimeType,
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  });

  test('the newest export is used when no workbook was imported', () async {
    final _Disk disk = await _disk();
    final File older = _write(
      disk.root,
      'projects/test-project/exports/older.xlsx',
      <int>[1],
    );
    final File newer = _write(
      disk.root,
      'projects/test-project/exports/newer.pdf',
      <int>[2],
    );
    _write(disk.root, 'projects/test-project/exports/ignored.xlsx.part', <int>[
      3,
    ]);
    older.setLastModifiedSync(DateTime.utc(2026, 1, 1));
    newer.setLastModifiedSync(DateTime.utc(2026, 9, 1));

    final ProjectOpenableFile? file = _ok(
      await disk.lookup.find(
        projectId: 'project-1',
        folderName: 'test-project',
      ),
    );

    expect(file?.fileName, 'newer.pdf');
    expect(file?.bytes, <int>[2]);
    expect(file?.mimeType, 'application/pdf');
    expect(
      _ok(
        await disk.lookup.exists(
          projectId: 'project-1',
          folderName: 'test-project',
        ),
      ),
      isTrue,
    );
  });

  test('a missing file and an unsafe path both hide the item', () async {
    final _Disk disk = await _disk();
    _ok(
      await disk.templates.save(
        aTemplate().copyWith(
          source: 'imported',
          sourceFilePath: '../outside.xlsx',
        ),
      ),
    );

    expect(
      _ok(
        await disk.lookup.exists(
          projectId: 'project-1',
          folderName: 'test-project',
        ),
      ),
      isFalse,
    );
    expect(
      _ok(
        await disk.lookup.find(
          projectId: 'project-1',
          folderName: 'test-project',
        ),
      ),
      isNull,
    );
  });

  test('a built template is not opened', () async {
    final _Disk disk = await _disk();
    _ok(await disk.templates.save(aTemplate()));
    _write(disk.root, 'projects/test-project/templates/book.xlsx', <int>[1]);

    expect(
      _ok(
        await disk.lookup.exists(
          projectId: 'project-1',
          folderName: 'test-project',
        ),
      ),
      isFalse,
    );
  });
}

Future<_Disk> _disk() async {
  final Directory documents = Directory.systemTemp.createTempSync(
    'tapture-open-',
  );
  addTearDown(() {
    if (documents.existsSync()) {
      documents.deleteSync(recursive: true);
    }
  });
  final StorageRoot storage = StorageRoot.fake(documentsDirectory: documents);
  _ok(await storage.resolve());
  final FakeTemplateRepository templates = FakeTemplateRepository();
  addTearDown(templates.dispose);
  return (
    root: Directory('${documents.path}/Tapture'),
    templates: templates,
    lookup: projectOpenableFileLookupIo(
      templates: templates,
      storageRoot: storage,
    ),
  );
}

File _write(Directory root, String relative, List<int> bytes) {
  final File file = File('${root.path}/$relative');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
  return file;
}

T _ok<T>(Result<T> result) {
  return result.fold((Failure failure) {
    fail('${failure.message} ${failure.recoveryAction}');
  }, (T value) => value);
}

typedef _Disk = ({
  Directory root,
  FakeTemplateRepository templates,
  ProjectOpenableFileLookup lookup,
});

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/db/tables/projects.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/db/tables/templates.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_relocation.dart';
import 'package:tapture/core/files/project_folders.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  test('unfiled photos move into the context tree and rows agree', () async {
    final _Harness harness = await _Harness.open();
    final Photo photo = await harness.addPhoto(
      filename: 'keep.jpg',
      relativePath: 'photos/_unfiled/keep.jpg',
    );
    File(
      '${harness.projectDir.path}/${photo.relativePath}',
    ).writeAsStringSync('pixels');

    final int moved = _ok(
      await harness.relocation.relocateRecord(harness.record.id),
    );
    final Photo relocated = await harness.photo(photo.id);

    expect(moved, 1);
    expect(
      relocated.relativePath,
      'photos/Kampala/Kasubi-HC-IV/Theatre/keep.jpg',
    );
    expect(
      File('${harness.projectDir.path}/${relocated.relativePath}').existsSync(),
      isTrue,
    );
    expect(
      File('${harness.projectDir.path}/${photo.relativePath}').existsSync(),
      isFalse,
    );
    expect(
      File(
        '${harness.projectDir.path}/${relocated.relativePath}',
      ).readAsStringSync(),
      'pixels',
    );
  });

  test(
    'correcting a facility relocates every file with no dangling path',
    () async {
      final _Harness harness = await _Harness.open();
      final Photo first = await harness.addPhoto(
        filename: 'a.jpg',
        relativePath: 'photos/Kampala/Kasubi-HC-IV/Theatre/a.jpg',
      );
      final Photo second = await harness.addPhoto(
        filename: 'b.jpg',
        relativePath: 'photos/Kampala/Kasubi-HC-IV/Theatre/b.jpg',
      );
      File(
        '${harness.projectDir.path}/${first.relativePath}',
      ).writeAsStringSync('a');
      File(
        '${harness.projectDir.path}/${second.relativePath}',
      ).writeAsStringSync('b');

      _ok(
        await upsertRecord(
          harness.db,
          row: RecordsCompanion(
            id: Value<String>(harness.record.id),
            contextJson: const Value<String>(
              '{"district":"Kampala","facility":"Kasubi HC III","department":"Theatre"}',
            ),
          ),
          clock: harness.clock,
          deviceId: harness.deviceId,
          ids: harness.ids,
        ),
      );

      final int moved = _ok(
        await harness.relocation.relocateRecord(harness.record.id),
      );
      final Photo movedFirst = await harness.photo(first.id);
      final Photo movedSecond = await harness.photo(second.id);

      expect(moved, 2);
      expect(
        movedFirst.relativePath,
        'photos/Kampala/Kasubi-HC-III/Theatre/a.jpg',
      );
      expect(
        movedSecond.relativePath,
        'photos/Kampala/Kasubi-HC-III/Theatre/b.jpg',
      );
      expect(
        File(
          '${harness.projectDir.path}/${movedFirst.relativePath}',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          '${harness.projectDir.path}/${movedSecond.relativePath}',
        ).existsSync(),
        isTrue,
      );
      expect(
        File('${harness.projectDir.path}/${first.relativePath}').existsSync(),
        isFalse,
      );
    },
  );

  test('a failed move leaves paths and files still agreeing', () async {
    final _Harness harness = await _Harness.open();
    var attempts = 0;
    final FileRelocation relocation = FileRelocation(
      db: harness.db,
      storageRoot: harness.storage,
      clock: harness.clock,
      deviceId: harness.deviceId,
      ids: harness.ids,
      move: (File from, File to) async {
        attempts += 1;
        if (attempts >= 2) {
          throw const FileSystemException('denied');
        }
        await to.parent.create(recursive: true);
        await from.rename(to.path);
      },
    );
    final Photo first = await harness.addPhoto(
      filename: 'a.jpg',
      relativePath: 'photos/_unfiled/a.jpg',
    );
    final Photo second = await harness.addPhoto(
      filename: 'b.jpg',
      relativePath: 'photos/_unfiled/b.jpg',
    );
    File(
      '${harness.projectDir.path}/${first.relativePath}',
    ).writeAsStringSync('a');
    File(
      '${harness.projectDir.path}/${second.relativePath}',
    ).writeAsStringSync('b');

    final Result<int> result = await relocation.relocateRecord(
      harness.record.id,
    );
    final Photo stillFirst = await harness.photo(first.id);
    final Photo stillSecond = await harness.photo(second.id);

    expect(result, isA<FailureResult<int>>());
    expect(stillFirst.relativePath, first.relativePath);
    expect(stillSecond.relativePath, second.relativePath);
    expect(
      File('${harness.projectDir.path}/${first.relativePath}').existsSync(),
      isTrue,
    );
    expect(
      File('${harness.projectDir.path}/${second.relativePath}').existsSync(),
      isTrue,
    );
    expect(
      File(
        '${harness.projectDir.path}/photos/Kampala/Kasubi-HC-IV/Theatre/a.jpg',
      ).existsSync(),
      isFalse,
    );
  });

  test('a failed transaction rolls files back so rows still agree', () async {
    final _Harness harness = await _Harness.open();
    final FileRelocation relocation = FileRelocation(
      db: harness.db,
      storageRoot: harness.storage,
      clock: harness.clock,
      deviceId: harness.deviceId,
      ids: harness.ids,
      failTransaction: () {
        throw StateError('rollback');
      },
    );
    final Photo photo = await harness.addPhoto(
      filename: 'keep.jpg',
      relativePath: 'photos/_unfiled/keep.jpg',
    );
    File(
      '${harness.projectDir.path}/${photo.relativePath}',
    ).writeAsStringSync('pixels');

    final Result<int> result = await relocation.relocateRecord(
      harness.record.id,
    );
    final Photo still = await harness.photo(photo.id);

    expect(result, isA<FailureResult<int>>());
    expect(still.relativePath, photo.relativePath);
    expect(
      File('${harness.projectDir.path}/${photo.relativePath}').existsSync(),
      isTrue,
    );
    expect(
      File(
        '${harness.projectDir.path}/photos/Kampala/Kasubi-HC-IV/Theatre/keep.jpg',
      ).existsSync(),
      isFalse,
    );
  });
}

final class _Harness {
  _Harness._({
    required this.db,
    required this.documents,
    required this.storage,
    required this.clock,
    required this.ids,
    required this.project,
    required this.template,
    required this.record,
    required this.projectDir,
  });

  final AppDatabase db;
  final Directory documents;
  final StorageRoot storage;
  final FixedClock clock;
  final UuidV7Service ids;
  final Project project;
  final Template template;
  final RecordRow record;
  final Directory projectDir;
  final String deviceId = 'device-a';

  FileRelocation get relocation {
    return FileRelocation(
      db: db,
      storageRoot: storage,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    );
  }

  static Future<_Harness> open() async {
    final Directory documents = Directory.systemTemp.createTempSync(
      'tapture-reloc-',
    );
    addTearDown(() {
      if (documents.existsSync()) {
        documents.deleteSync(recursive: true);
      }
    });
    final AppDatabase db = AppDatabase.memory();
    addTearDown(db.close);
    final DateTime t0 = DateTime.utc(2026, 9, 17, 8);
    final FixedClock clock = FixedClock(t0);
    final UuidV7Service ids = UuidV7Service.sequence(clock);
    const String deviceId = 'device-a';
    final StorageRoot storage = StorageRoot.fake(documentsDirectory: documents);
    final Project project = _ok(
      await upsertProject(
        db,
        row: const ProjectsCompanion(
          name: Value<String>('Inventory'),
          client: Value<String>('Acme'),
          status: Value<ProjectStatus>(ProjectStatus.active),
          folderName: Value<String>('inventory__aaaaaa'),
          settings: Value<String>('{}'),
        ),
        clock: clock,
        deviceId: deviceId,
        ids: ids,
      ),
    );
    final Directory projectDir = _ok(
      await ProjectFolders(storageRoot: storage).create(project),
    );
    final Template template = _ok(
      await upsertTemplate(
        db,
        row: TemplatesCompanion(
          projectId: Value<String?>(project.id),
          name: const Value<String>('Medical Equipment'),
          kind: const Value<String>('equipment'),
          source: const Value<String>('shipped'),
        ),
        clock: clock,
        deviceId: deviceId,
        ids: ids,
      ),
    );
    final RecordRow record = _ok(
      await upsertRecord(
        db,
        row: RecordsCompanion(
          projectId: Value<String>(project.id),
          templateId: Value<String>(template.id),
          status: const Value<String>('captured'),
          processingMode: const Value<String>('manual'),
          contextJson: const Value<String>(
            '{"district":"Kampala","facility":"Kasubi HC IV","department":"Theatre"}',
          ),
          identityHash: const Value<String>('hash-1'),
          source: const Value<String>('capture'),
          capturedAt: Value<DateTime>(t0),
          capturedBy: const Value<String>('Ada'),
        ),
        clock: clock,
        deviceId: deviceId,
        ids: ids,
      ),
    );
    return _Harness._(
      db: db,
      documents: documents,
      storage: storage,
      clock: clock,
      ids: ids,
      project: project,
      template: template,
      record: record,
      projectDir: projectDir,
    );
  }

  Future<Photo> addPhoto({
    required String filename,
    required String relativePath,
  }) async {
    final Photo photo = _ok(
      await upsertPhoto(
        db,
        row: PhotosCompanion(
          projectId: Value<String>(project.id),
          recordId: Value<String?>(record.id),
          captureSessionId: const Value<String>('session-1'),
          originalFilename: Value<String>(filename),
          storedFilename: Value<String>(filename),
          relativePath: Value<String>(relativePath),
          photoType: const Value<String>('front'),
          sortOrder: const Value<int>(0),
          width: const Value<int>(1600),
          height: const Value<int>(1200),
          fileSize: const Value<int>(16),
          mimeType: const Value<String>('image/jpeg'),
          sha256: Value<String>('sha-$filename'),
          capturedAt: Value<DateTime>(clock.nowUtc()),
        ),
        clock: clock,
        deviceId: deviceId,
        ids: ids,
      ),
    );
    File('${projectDir.path}/$relativePath').parent.createSync(recursive: true);
    return photo;
  }

  Future<Photo> photo(String id) {
    return (db.select(
      db.photos,
    )..where(($PhotosTable tbl) => tbl.id.equals(id))).getSingle();
  }
}

T _ok<T>(Result<T> result) {
  return result.fold((Failure failure) {
    fail('${failure.message} ${failure.recoveryAction}');
  }, (T value) => value);
}

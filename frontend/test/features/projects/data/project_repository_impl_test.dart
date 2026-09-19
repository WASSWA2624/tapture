import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart' hide Project;
import 'package:tapture/core/db/app_database.dart' as sqlite show Project;
import 'package:tapture/core/db/tables/exports.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/db/tables/projects.dart' as projects_db;
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/db/tables/reference.dart';
import 'package:tapture/core/db/tables/template_fields.dart';
import 'package:tapture/core/db/tables/template_rows.dart';
import 'package:tapture/core/db/tables/templates.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/project_folders.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/projects/data/project_repository_impl.dart';
import 'package:tapture/features/projects/domain/project_repository.dart';

import '../../../support/factories.dart';
import '../project_repository_contract.dart';

void main() {
  late AppDatabase db;
  late ProjectRepositoryImpl repo;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);
  final FixedClock clock = FixedClock(t0);

  setUp(() {
    db = AppDatabase.memory();
    repo = ProjectRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device-test',
      ids: UuidV7Service.sequence(clock),
    );
  });

  tearDown(() async {
    await db.close();
  });

  runProjectRepositoryContract(() => repo);

  test('watchList returns counts and last-worked from one query', () async {
    final IdService ids = UuidV7Service.sequence(clock);
    _ok(await repo.create(aProject()));
    _ok(
      await upsertRecord(
        db,
        row: RecordsCompanion(
          projectId: const Value<String>('project-1'),
          templateId: const Value<String>('template-1'),
          status: const Value<String>('captured'),
          processingMode: const Value<String>('manual'),
          contextJson: const Value<String>('{}'),
          identityHash: const Value<String>('hash-captured'),
          source: const Value<String>('capture'),
          capturedAt: Value<DateTime>(t0),
          capturedBy: const Value<String>('Ada'),
        ),
        clock: FixedClock(t0.add(const Duration(hours: 2))),
        deviceId: 'device-test',
        ids: ids,
      ),
    );
    _ok(
      await upsertRecord(
        db,
        row: RecordsCompanion(
          projectId: const Value<String>('project-1'),
          templateId: const Value<String>('template-1'),
          status: const Value<String>('approved'),
          processingMode: const Value<String>('manual'),
          contextJson: const Value<String>('{}'),
          identityHash: const Value<String>('hash-approved'),
          source: const Value<String>('capture'),
          capturedAt: Value<DateTime>(t0),
          capturedBy: const Value<String>('Ada'),
        ),
        clock: clock,
        deviceId: 'device-test',
        ids: ids,
      ),
    );
    final ProjectListRow row = (await repo.watchList().first).single;
    expect(row.recordCount, 2);
    expect(row.unprocessedCount, 1);
    expect(row.lastWorkedAt.toUtc(), t0.add(const Duration(hours: 2)));
  });

  test('watchHome derives pending counts from records and exports', () async {
    final IdService ids = UuidV7Service.sequence(clock);
    _ok(await repo.create(aProject()));
    _ok(await repo.create(aProject(id: 'other', name: 'Other')));
    Future<void> addRecord(String status, String hash) async {
      _ok(
        await upsertRecord(
          db,
          row: RecordsCompanion(
            projectId: const Value<String>('project-1'),
            templateId: const Value<String>('template-1'),
            status: Value<String>(status),
            processingMode: const Value<String>('manual'),
            contextJson: const Value<String>('{}'),
            identityHash: Value<String>(hash),
            source: const Value<String>('capture'),
            capturedAt: Value<DateTime>(t0),
            capturedBy: const Value<String>('Ada'),
          ),
          clock: clock,
          deviceId: 'device-test',
          ids: ids,
        ),
      );
    }

    await addRecord('needsReview', 'hash-review');
    await addRecord('queued', 'hash-queued');
    await addRecord('processing', 'hash-processing');
    await addRecord('approved', 'hash-approved');
    await addRecord('captured', 'hash-captured');
    _ok(
      await upsertRecord(
        db,
        row: RecordsCompanion(
          projectId: const Value<String>('other'),
          templateId: const Value<String>('template-1'),
          status: const Value<String>('needsReview'),
          processingMode: const Value<String>('manual'),
          contextJson: const Value<String>('{}'),
          identityHash: const Value<String>('hash-other'),
          source: const Value<String>('capture'),
          capturedAt: Value<DateTime>(t0),
          capturedBy: const Value<String>('Ada'),
        ),
        clock: clock,
        deviceId: 'device-test',
        ids: ids,
      ),
    );
    _ok(
      await completeExport(
        db,
        produce: () async => ExportsCompanion(
          projectId: const Value<String>('project-1'),
          formats: Value<String>(jsonEncode(<String>['xlsx'])),
          filters: Value<String>(jsonEncode(<String, String>{})),
          recordCount: const Value<int>(1),
          filePath: const Value<String>('exports/v1.xlsx'),
          fileHash: const Value<String>('hash-file'),
          createdBy: const Value<String>('Ada'),
        ),
        clock: clock,
        deviceId: 'device-test',
        ids: ids,
      ),
    );
    final ProjectHomeCounts counts = (await repo.watchHome('project-1').first);
    expect(counts.review, 1);
    expect(counts.process, 2);
    expect(counts.toExport, 1);
    expect(counts.toShare, 1);
  });

  test('createReady writes the row, folder tree and default context', () async {
    final Directory documents = Directory.systemTemp.createTempSync(
      'tapture-create-ready-',
    );
    addTearDown(() {
      if (documents.existsSync()) {
        documents.deleteSync(recursive: true);
      }
    });
    final ProjectFolders folders = ProjectFolders(
      storageRoot: StorageRoot.fake(documentsDirectory: documents),
    );
    repo = _repo(db, folders: folders);
    final Project created = _ok(await repo.createReady(name: 'Alpha Site'));
    expect(created.name, 'Alpha Site');
    expect(
      created.folderName,
      folderNameFor(name: 'Alpha Site', id: created.id),
    );
    expect(created.folderName, isNotEmpty);
    final List<ContextData> defs = await (db.select(
      db.context,
    )..where(($ContextTable tbl) => tbl.projectId.equals(created.id))).get();
    expect(defs, hasLength(1));
    expect(defs.single.fieldKey, 'site');
    expect(defs.single.label, 'Site');
    final Directory tree = _okDir(
      await folders.resolve(_driftProject(created)),
    );
    expect(Directory('${tree.path}/photos').existsSync(), isTrue);
    expect(Directory('${tree.path}/templates').existsSync(), isTrue);
  });

  test('a failed folder write leaves no row and no partial tree', () async {
    final Directory documents = Directory.systemTemp.createTempSync(
      'tapture-create-fail-',
    );
    addTearDown(() {
      if (documents.existsSync()) {
        documents.deleteSync(recursive: true);
      }
    });
    late String writtenFolder;
    repo = ProjectRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device-test',
      ids: UuidV7Service.sequence(clock),
      createTree:
          ({
            required String id,
            required String name,
            required String folderName,
          }) async {
            writtenFolder = folderName;
            final Directory tree = Directory(
              '${documents.path}/Tapture/projects/$folderName',
            );
            await tree.create(recursive: true);
            await Directory('${tree.path}/photos').create();
            return const FailureResult<void>(
              StorageFailure(
                message:
                    'The project folder could not be created on this device.',
                recoveryAction:
                    'Free space or allow storage access, then try again.',
              ),
            );
          },
      discardTree:
          ({
            required String id,
            required String name,
            required String folderName,
          }) async {
            final Directory tree = Directory(
              '${documents.path}/Tapture/projects/$folderName',
            );
            if (tree.existsSync()) {
              await tree.delete(recursive: true);
            }
            return const Success<void>(null);
          },
    );
    final Result<Project> result = await repo.createReady(name: 'Alpha');
    expect(_failure(result), isA<StorageFailure>());
    expect(await repo.watchAll().first, isEmpty);
    expect(
      Directory(
        '${documents.path}/Tapture/projects/$writtenFolder',
      ).existsSync(),
      isFalse,
    );
  });

  test(
    'a duplicate has zero records and the same structure under a new folder',
    () async {
      final Directory documents = Directory.systemTemp.createTempSync(
        'tapture-duplicate-',
      );
      addTearDown(() {
        if (documents.existsSync()) {
          documents.deleteSync(recursive: true);
        }
      });
      final ProjectFolders folders = ProjectFolders(
        storageRoot: StorageRoot.fake(documentsDirectory: documents),
      );
      repo = _repo(db, folders: folders);
      final Project source = _ok(
        await repo.create(
          aProject(
            name: 'Alpha',
          ).copyWith(settings: const ProjectSettings(gpsEnabled: true)),
        ),
      );
      final String templateId = _ok(
        await upsertTemplate(
          db,
          row: TemplatesCompanion(
            projectId: Value<String>(source.id),
            name: const Value<String>('Assets'),
            kind: const Value<String>('item'),
            source: const Value<String>('built'),
          ),
          clock: clock,
          deviceId: 'device-test',
          ids: UuidV7Service.sequence(clock),
        ),
      ).id;
      _ok(
        await upsertTemplateField(
          db,
          row: TemplateFieldsCompanion(
            templateId: Value<String>(templateId),
            fieldKey: const Value<String>('serial'),
            label: const Value<String>('Serial'),
            type: const Value<String>('text'),
            sortOrder: const Value<int>(0),
          ),
          clock: clock,
          deviceId: 'device-test',
          ids: UuidV7Service.sequence(clock),
        ),
      );
      _ok(
        await upsertTemplateRow(
          db,
          row: TemplateRowsCompanion(
            templateId: Value<String>(templateId),
            outputRowNumber: const Value<int>(2),
            identifier: const Value<String>('row-a'),
            label: const Value<String>('Row A'),
          ),
          clock: clock,
          deviceId: 'device-test',
          ids: UuidV7Service.sequence(clock),
        ),
      );
      await db
          .into(db.context)
          .insert(
            ContextCompanion.insert(
              projectId: source.id,
              level: 1,
              fieldKey: 'site',
              label: 'Site',
              createdAt: t0,
              updatedAt: t0,
              updatedByDevice: 'device-test',
            ),
          );
      final ReferenceDatasetRow dataset = _ok(
        await upsertReferenceDataset(
          db,
          row: ReferenceCompanion(
            name: const Value<String>('Parts'),
            scope: const Value<ReferenceScope>(ReferenceScope.project),
            projectId: Value<String>(source.id),
            keyColumn: const Value<String>('serial'),
            columns: Value<String>(jsonEncode(<String>['serial'])),
            sourceFile: const Value<String>('parts.csv'),
            importedAt: Value<DateTime>(t0),
            rowCount: const Value<int>(1),
          ),
          clock: clock,
          deviceId: 'device-test',
          ids: UuidV7Service.sequence(clock),
        ),
      );
      _ok(
        await upsertReferenceRow(
          db,
          row: ReferenceRowsCompanion(
            datasetId: Value<String>(dataset.id),
            keyValue: const Value<String>('SN-1'),
            values: Value<String>(jsonEncode(<String, String>{'n': 'Pump'})),
          ),
          clock: clock,
          deviceId: 'device-test',
          ids: UuidV7Service.sequence(clock),
        ),
      );
      _ok(
        await upsertRecord(
          db,
          row: RecordsCompanion(
            projectId: Value<String>(source.id),
            templateId: Value<String>(templateId),
            status: const Value<String>('captured'),
            processingMode: const Value<String>('manual'),
            contextJson: const Value<String>('{}'),
            identityHash: const Value<String>('hash-source'),
            source: const Value<String>('capture'),
            capturedAt: Value<DateTime>(t0),
            capturedBy: const Value<String>('Ada'),
          ),
          clock: clock,
          deviceId: 'device-test',
          ids: UuidV7Service.sequence(clock),
        ),
      );
      _ok(
        await upsertPhoto(
          db,
          row: PhotosCompanion(
            projectId: Value<String>(source.id),
            captureSessionId: const Value<String>('session-1'),
            originalFilename: const Value<String>('IMG_001.jpg'),
            storedFilename: const Value<String>('img-001.jpg'),
            relativePath: const Value<String>('photos/_unfiled/abc.jpg'),
            photoType: const Value<String>('front'),
            sortOrder: const Value<int>(0),
            width: const Value<int>(1600),
            height: const Value<int>(1200),
            fileSize: const Value<int>(2048),
            mimeType: const Value<String>('image/jpeg'),
            sha256: const Value<String>('abc123'),
            capturedAt: Value<DateTime>(t0),
          ),
          clock: clock,
          deviceId: 'device-test',
          ids: UuidV7Service.sequence(clock),
        ),
      );

      final Project copy = _ok(
        await repo.createReady(name: 'Alpha (copy)', sourceId: source.id),
      );
      expect(copy.id, isNot(source.id));
      expect(copy.folderName, isNot(source.folderName));
      expect(copy.settings.gpsEnabled, isTrue);
      expect(
        await (db.select(
          db.records,
        )..where(($RecordsTable tbl) => tbl.projectId.equals(copy.id))).get(),
        isEmpty,
      );
      expect(
        await (db.select(
          db.photos,
        )..where(($PhotosTable tbl) => tbl.projectId.equals(copy.id))).get(),
        isEmpty,
      );
      expect(
        await (db.select(
          db.templates,
        )..where(($TemplatesTable tbl) => tbl.projectId.equals(copy.id))).get(),
        hasLength(1),
      );
      expect(
        await (db.select(
          db.context,
        )..where(($ContextTable tbl) => tbl.projectId.equals(copy.id))).get(),
        hasLength(1),
      );
      expect(
        await (db.select(
          db.reference,
        )..where(($ReferenceTable tbl) => tbl.projectId.equals(copy.id))).get(),
        hasLength(1),
      );
      final String copyTemplateId =
          (await (db.select(db.templates)..where(
                    ($TemplatesTable tbl) => tbl.projectId.equals(copy.id),
                  ))
                  .get())
              .single
              .id;
      expect(
        await (db.select(db.templateFields)..where(
              ($TemplateFieldsTable tbl) =>
                  tbl.templateId.equals(copyTemplateId),
            ))
            .get(),
        hasLength(1),
      );
      expect(
        await (db.select(db.templateRows)..where(
              ($TemplateRowsTable tbl) => tbl.templateId.equals(copyTemplateId),
            ))
            .get(),
        hasLength(1),
      );
      expect(
        await (db.select(
          db.records,
        )..where(($RecordsTable tbl) => tbl.projectId.equals(source.id))).get(),
        hasLength(1),
      );
      final Directory tree = _okDir(await folders.resolve(_driftProject(copy)));
      expect(Directory('${tree.path}/photos').existsSync(), isTrue);
    },
  );

  test('presentation under projects imports no core/db', () {
    final Directory presentation = Directory(
      'lib/features/projects/presentation',
    );
    expect(presentation.existsSync(), isTrue);
    for (final FileSystemEntity entity in presentation.listSync(
      recursive: true,
    )) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      expect(
        entity.readAsStringSync(),
        isNot(contains('core/db')),
        reason: entity.path,
      );
    }
  });
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

Failure _failure<T>(Result<T> result) {
  return switch (result) {
    FailureResult<T>(:final Failure failure) => failure,
    Success<T>() => throw TestFailure('expected a failure'),
  };
}

Directory _okDir(Result<Directory> result) {
  return switch (result) {
    Success<Directory>(:final Directory value) => value,
    FailureResult<Directory>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

ProjectRepositoryImpl _repo(AppDatabase db, {required ProjectFolders folders}) {
  return ProjectRepositoryImpl(
    db: db,
    clock: FixedClock(DateTime.utc(2026, 9, 17, 8)),
    deviceId: 'device-test',
    ids: UuidV7Service.sequence(FixedClock(DateTime.utc(2026, 9, 17, 8))),
    createTree:
        ({
          required String id,
          required String name,
          required String folderName,
        }) async {
          return (await folders.create(
            _driftProject(
              Project(
                id: id,
                name: name,
                status: ProjectStatus.active,
                folderName: folderName,
                settings: const ProjectSettings(),
                createdAt: DateTime.utc(2026, 9, 17, 8),
                updatedAt: DateTime.utc(2026, 9, 17, 8),
              ),
            ),
          )).map((Directory _) {});
        },
    discardTree:
        ({
          required String id,
          required String name,
          required String folderName,
        }) {
          return folders.discard(
            _driftProject(
              Project(
                id: id,
                name: name,
                status: ProjectStatus.active,
                folderName: folderName,
                settings: const ProjectSettings(),
                createdAt: DateTime.utc(2026, 9, 17, 8),
                updatedAt: DateTime.utc(2026, 9, 17, 8),
              ),
            ),
          );
        },
  );
}

sqlite.Project _driftProject(Project project) {
  return sqlite.Project(
    id: project.id,
    createdAt: project.createdAt,
    updatedAt: project.updatedAt,
    updatedByDevice: 'device-test',
    rev: 1,
    name: project.name,
    client: project.organisation ?? '',
    status: projects_db.ProjectStatus.active,
    folderName: project.folderName,
    settings: '{}',
  );
}

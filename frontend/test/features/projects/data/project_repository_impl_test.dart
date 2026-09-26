import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart' hide Project;
import 'package:tapture/core/db/app_database.dart' as sqlite show Project;
import 'package:tapture/core/db/tables/attachment_owners.dart';
import 'package:tapture/core/db/tables/attachments.dart';
import 'package:tapture/core/db/tables/captions.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/db/tables/projects.dart' as projects_db;
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/db/tables/reference.dart';
import 'package:tapture/core/db/tables/template_fields.dart';
import 'package:tapture/core/db/tables/template_rows.dart';
import 'package:tapture/core/db/tables/templates.dart';
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
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
      recycleTree:
          ({
            required String id,
            required String name,
            required String folderName,
          }) async => const Success<void>(null),
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
    expect(defs, isEmpty);
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

  test('delete writes tombstones and leaves the file in recycle', () async {
    final Directory documents = Directory.systemTemp.createTempSync(
      'tapture-project-delete-',
    );
    addTearDown(() {
      if (documents.existsSync()) {
        documents.deleteSync(recursive: true);
      }
    });
    final ProjectFolders folders = ProjectFolders(
      storageRoot: StorageRoot.fake(documentsDirectory: documents),
    );
    final ProjectRepositoryImpl deleting = _repo(db, folders: folders);
    _ok(await deleting.create(aProject(name: 'Alpha')));
    final Directory tree = _okDir(
      await folders.create(_driftProject(aProject(name: 'Alpha'))),
    );
    final File keep = File('${tree.path}/photos/keep.txt')
      ..writeAsStringSync('kept');
    _ok(
      await upsertRecord(
        db,
        row: RecordsCompanion(
          id: const Value<String>('record-1'),
          projectId: const Value<String>('project-1'),
          templateId: const Value<String>('template-1'),
          status: const Value<String>('captured'),
          processingMode: const Value<String>('manual'),
          contextJson: const Value<String>('{}'),
          identityHash: const Value<String>('hash-1'),
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
          id: const Value<String>('photo-1'),
          projectId: const Value<String>('project-1'),
          captureSessionId: const Value<String>('session-1'),
          originalFilename: const Value<String>('keep.txt'),
          storedFilename: const Value<String>('keep.txt'),
          relativePath: const Value<String>('photos/keep.txt'),
          photoType: const Value<String>('front'),
          sortOrder: const Value<int>(0),
          width: const Value<int>(1),
          height: const Value<int>(1),
          fileSize: const Value<int>(4),
          mimeType: const Value<String>('text/plain'),
          sha256: const Value<String>('keep-sha'),
          capturedAt: Value<DateTime>(t0),
        ),
        clock: clock,
        deviceId: 'device-test',
        ids: UuidV7Service.sequence(clock),
      ),
    );

    _ok(await deleting.delete('project-1'));

    expect(keep.existsSync(), isFalse);
    final File recycled = File(
      '${documents.path}/Tapture/.recycle/test-project/photos/keep.txt',
    );
    expect(recycled.existsSync(), isTrue);
    expect(recycled.readAsStringSync(), 'kept');
    expect(await deleting.watchAll().first, isEmpty);

    final List<Tombstone> marks = await db.select(db.tombstones).get();
    expect(
      marks.map((Tombstone row) => '${row.entityType}:${row.entityId}'),
      containsAll(<String>[
        'projects:project-1',
        'records:record-1',
        'photos:photo-1',
      ]),
    );
    expect(
      marks.where((Tombstone row) => row.entityId == 'project-1'),
      hasLength(1),
    );
    expect(
      marks.where((Tombstone row) => row.entityId == 'record-1'),
      hasLength(1),
    );
    expect(
      marks.where((Tombstone row) => row.entityId == 'photo-1'),
      hasLength(1),
    );
  });

  test('setPinned writes only the pin and leaves last worked alone', () async {
    _ok(await repo.create(aProject()));
    final sqlite.Project before = (await db.select(db.projects).get()).single;
    final DateTime lastWorked =
        (await repo.watchList().first).single.lastWorkedAt;
    _ok(await repo.setPinned('project-1', true));
    final sqlite.Project after = (await db.select(db.projects).get()).single;
    expect(after.pinnedAt, isNotNull);
    expect(after.updatedAt, before.updatedAt);
    expect(after.rev, before.rev);
    expect(after.updatedByDevice, before.updatedByDevice);
    expect(after.name, before.name);
    expect((await repo.watchList().first).single.lastWorkedAt, lastWorked);
  });

  test('setPinned survives a close and reopen', () async {
    await db.close();
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture_pin_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    AppDatabase fileDb = AppDatabase.open(directoryPath: directory.path);
    ProjectRepositoryImpl fileRepo = ProjectRepositoryImpl(
      db: fileDb,
      clock: clock,
      deviceId: 'device-test',
      ids: UuidV7Service.sequence(clock),
    );
    _ok(await fileRepo.create(aProject()));
    _ok(await fileRepo.setPinned('project-1', true));
    await fileDb.close();
    fileDb = AppDatabase.open(directoryPath: directory.path);
    addTearDown(fileDb.close);
    fileRepo = ProjectRepositoryImpl(
      db: fileDb,
      clock: clock,
      deviceId: 'device-test',
      ids: UuidV7Service.sequence(clock),
    );
    final Project pinned = (await fileRepo.watchAll().first).single;
    expect(pinned.pinnedAt, isNotNull);
    final sqlite.Project row =
        (await fileDb.select(fileDb.projects).get()).single;
    expect(row.rev, 1);
  });

  test('pinned rows with the same updatedAt keep a stable id order', () async {
    _ok(await repo.create(aProject(id: 'b', name: 'Bravo')));
    _ok(await repo.create(aProject(id: 'a', name: 'Alpha')));
    _ok(await repo.setPinned('b', true));
    _ok(await repo.setPinned('a', true));
    expect(
      (await repo.watchAll().first).map((Project row) => row.id).toList(),
      <String>['a', 'b'],
    );
    expect(
      (await repo.watchList().first)
          .map((ProjectListRow row) => row.project.id)
          .toList(),
      <String>['a', 'b'],
    );
  });

  test(
    'a new field is stored as the typed original, then refined beside it',
    () async {
      _ok(await repo.create(aProject()));
      final RecordRow record = _ok(
        await upsertRecord(
          db,
          row: RecordsCompanion(
            projectId: const Value<String>('project-1'),
            templateId: const Value<String>('template-1'),
            status: const Value<String>('captured'),
            processingMode: const Value<String>('manual'),
            contextJson: const Value<String>('{}'),
            identityHash: const Value<String>('hash-edit'),
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
        await repo.addRecordField(
          recordId: record.id,
          fieldKey: 'asset_tag',
          value: 'A-1',
        ),
      );
      _ok(
        await repo.refineRecordField(
          recordId: record.id,
          fieldKey: 'asset_tag',
          value: 'A-001',
        ),
      );

      final List<ProjectRecordRow> rows = await repo
          .watchRecords('project-1', statuses: const <String>['captured'])
          .first;
      expect(rows.single.templateId, 'template-1');
      final ProjectRecordFieldValue field = rows.single.fields.single;
      expect(field.fieldKey, 'asset_tag');
      expect(field.raw, 'A-1');
      expect(field.refined, 'A-001');
      final RecordField stored =
          await (db.select(db.recordFields)
                ..where(($RecordFieldsTable t) => t.recordId.equals(record.id)))
              .getSingle();
      expect(stored.source, 'TYPED');
      expect(stored.valueRaw, 'A-1');
    },
  );

  test(
    'a record row shows its first live photo in its newest edit, turned',
    () async {
      _ok(await repo.create(aProject()));
      final IdService ids = UuidV7Service.sequence(clock);
      _ok(
        await upsertRecord(
          db,
          row: _recordRow(id: 'record-1', hash: 'hash-thumb'),
          clock: clock,
          deviceId: 'device-test',
          ids: ids,
        ),
      );
      Future<void> addPhoto(
        String id, {
        required int sortOrder,
        String? derivedFrom,
        int? rotation,
        Duration after = Duration.zero,
      }) async {
        _ok(
          await upsertPhoto(
            db,
            row: _photoRow(
              id,
              recordId: 'record-1',
              sortOrder: sortOrder,
              derivedFrom: derivedFrom,
              rotation: rotation,
              capturedAt: t0.add(after),
            ),
            clock: clock,
            deviceId: 'device-test',
            ids: ids,
          ),
        );
      }

      await addPhoto('removed', sortOrder: 0);
      await addPhoto('original', sortOrder: 1);
      await addPhoto(
        'cropped',
        sortOrder: 1,
        derivedFrom: 'original',
        rotation: 450,
        after: const Duration(minutes: 1),
      );
      await addPhoto('second', sortOrder: 2);
      await writeTombstone(
        db,
        entityType: 'photos',
        entityId: 'removed',
        reason: 'operator-delete',
        clock: clock,
        deviceId: 'device-test',
      );

      final ProjectRecordRow row =
          (await repo
                  .watchRecords(
                    'project-1',
                    statuses: const <String>['captured'],
                  )
                  .first)
              .single;
      expect(row.thumb?.sha256, 'sha-cropped');
      expect(
        row.thumb?.storagePath,
        'projects/test-project/photos/cropped.jpg',
      );
      expect(row.thumb?.quarterTurns, 1);
      expect(row.photoCount, 2);
    },
  );

  test('template counts group live records and skip archived ones', () async {
    _ok(await repo.create(aProject()));
    final IdService ids = UuidV7Service.sequence(clock);
    Future<void> add(String id, String templateId, String status) async {
      _ok(
        await upsertRecord(
          db,
          row: _recordRow(
            id: id,
            hash: 'hash-$id',
            status: status,
            templateId: templateId,
          ),
          clock: clock,
          deviceId: 'device-test',
          ids: ids,
        ),
      );
    }

    await add('r1', 'assets', 'captured');
    await add('r2', 'assets', 'approved');
    await add('r3', 'rooms', 'captured');
    await add('r4', 'rooms', 'archived');

    final Map<String, int> counts = await repo
        .watchTemplateRecordCounts(
          'project-1',
          statuses: const <String>['captured', 'approved'],
        )
        .first;
    expect(counts, <String, int>{'assets': 2, 'rooms': 1});
  });

  test(
    'watchRecord lists live photos with captions and counts audio',
    () async {
      _ok(await repo.create(aProject()));
      final IdService ids = UuidV7Service.sequence(clock);
      _ok(
        await upsertRecord(
          db,
          row: _recordRow(id: 'record-1', hash: 'hash-detail'),
          clock: clock,
          deviceId: 'device-test',
          ids: ids,
        ),
      );
      for (final (String id, int order) in <(String, int)>[
        ('first', 0),
        ('second', 1),
        ('removed', 2),
      ]) {
        _ok(
          await upsertPhoto(
            db,
            row: _photoRow(
              id,
              recordId: 'record-1',
              sortOrder: order,
              capturedAt: t0,
            ),
            clock: clock,
            deviceId: 'device-test',
            ids: ids,
          ),
        );
      }
      await writeTombstone(
        db,
        entityType: 'photos',
        entityId: 'removed',
        reason: 'operator-delete',
        clock: clock,
        deviceId: 'device-test',
      );
      Future<Caption> caption(CaptionOwnerType owner, String id, String text) {
        return insertCaption(
          db,
          row: CaptionsCompanion(
            ownerType: Value<CaptionOwnerType>(owner),
            ownerId: Value<String>(id),
            textRaw: Value<String>(text),
            inputMode: const Value<CaptionInputMode>(CaptionInputMode.typed),
          ),
          clock: clock,
          deviceId: 'device-test',
          ids: ids,
        ).then(_ok);
      }

      await caption(CaptionOwnerType.record, 'record-1', 'Boiler room');
      final Caption front = await caption(
        CaptionOwnerType.photo,
        'first',
        'Frnt',
      );
      _ok(
        await writeCaptionRefined(
          db,
          id: front.id,
          textRefined: 'Front',
          clock: clock,
          deviceId: 'device-test',
          ids: ids,
        ),
      );
      _ok(
        await upsertAttachment(
          db,
          row: const AttachmentsCompanion(
            id: Value<String>('clip-1'),
            projectId: Value<String>('project-1'),
            relativePath: Value<String>('audio/clip-1.wav'),
            mimeType: Value<String>('audio/wav'),
            fileSize: Value<int>(4),
            sha256: Value<String>('clip-sha'),
            kind: Value<AttachmentKind>(AttachmentKind.audio),
          ),
          clock: clock,
          deviceId: 'device-test',
          ids: ids,
        ),
      );
      await db
          .into(db.attachmentOwners)
          .insert(
            AttachmentOwnersCompanion(
              id: const Value<String>('owner-1'),
              attachmentId: const Value<String>('clip-1'),
              ownerType: const Value<AttachmentOwnerType>(
                AttachmentOwnerType.record,
              ),
              ownerId: const Value<String>('record-1'),
              sortOrder: const Value<int>(0),
              createdAt: Value<DateTime>(t0),
              updatedAt: Value<DateTime>(t0),
              updatedByDevice: const Value<String>('device-test'),
              rev: const Value<int>(1),
            ),
          );

      final ProjectRecordDetail detail = (await repo
          .watchRecord('record-1')
          .first)!;
      expect(detail.caption, 'Boiler room');
      expect(
        detail.photos
            .map((RecordPhotoCaption photo) => photo.photo.sha256)
            .toList(),
        <String>['sha-first', 'sha-second'],
      );
      expect(detail.photos.first.caption, 'Front');
      expect(detail.photos.last.caption, '');
      expect(detail.audioClips, 1);
      expect(detail.row.thumb?.sha256, 'sha-first');

      _ok(await repo.archiveRecord('record-1'));
      expect(await repo.watchRecord('record-1').first, isNull);
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

  group('project photo', () {
    late Directory documents;

    setUp(() {
      documents = Directory.systemTemp.createTempSync('tapture-cover-');
    });

    tearDown(() {
      if (documents.existsSync()) {
        documents.deleteSync(recursive: true);
      }
    });

    Future<(ProjectRepositoryImpl, Directory)> withWriter({
      bool writable = true,
    }) async {
      final StorageRoot storage = StorageRoot.fake(
        documentsDirectory: documents,
        writable: writable,
      );
      final Directory root = writable
          ? _ok(await storage.resolve())
          : documents;
      return (
        ProjectRepositoryImpl(
          db: db,
          clock: clock,
          deviceId: 'device-test',
          ids: UuidV7Service.sequence(clock),
          writer: FileWriter(storageRoot: storage),
        ),
        root,
      );
    }

    test('a photo is written, then set, and a replaced file stays', () async {
      final (ProjectRepositoryImpl photos, Directory root) = await withWriter();
      final Project project = _ok(await photos.create(aProject()));

      final ProjectSettings first = _ok(
        await photos.setCoverPhoto(project.id, Uint8List.fromList(<int>[1, 2])),
      );
      final ProjectCoverPhoto one = first.coverPhoto!;
      expect(one.path, startsWith('projects/${project.folderName}/cover/'));
      expect(one.path, endsWith('.jpg'));
      expect(one.sha256, isNotEmpty);
      final File firstFile = File('${root.path}/${one.path}');
      expect(firstFile.readAsBytesSync(), <int>[1, 2]);

      final ProjectSettings second = _ok(
        await photos.setCoverPhoto(project.id, Uint8List.fromList(<int>[3])),
      );
      expect(second.coverPhoto!.path, isNot(one.path));
      expect(firstFile.existsSync(), isTrue);
      final Project stored = (await photos.watchAll().first).single;
      expect(stored.settings.coverPhoto, second.coverPhoto);

      final ProjectSettings cleared = _ok(
        await photos.clearCoverPhoto(project.id),
      );
      expect(cleared.coverPhoto, isNull);
      expect(
        File('${root.path}/${second.coverPhoto!.path}').existsSync(),
        isTrue,
      );
      expect(
        (await photos.watchAll().first).single.settings.coverPhoto,
        isNull,
      );
    });

    test('a failed file write changes nothing', () async {
      final (ProjectRepositoryImpl photos, Directory _) = await withWriter(
        writable: false,
      );
      final Project project = _ok(await photos.create(aProject()));

      final Result<ProjectSettings> result = await photos.setCoverPhoto(
        project.id,
        Uint8List.fromList(<int>[1]),
      );

      expect(result, isA<FailureResult<ProjectSettings>>());
      expect(
        (await photos.watchAll().first).single.settings.coverPhoto,
        isNull,
      );
    });

    test('without a file writer a photo is refused', () async {
      final Project project = _ok(await repo.create(aProject()));
      expect(
        await repo.setCoverPhoto(project.id, Uint8List.fromList(<int>[1])),
        isA<FailureResult<ProjectSettings>>(),
      );
      expect(
        await repo.clearCoverPhoto('missing'),
        isA<FailureResult<ProjectSettings>>(),
      );
    });
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

RecordsCompanion _recordRow({
  required String id,
  required String hash,
  String status = 'captured',
  String templateId = 'template-1',
}) {
  return RecordsCompanion(
    id: Value<String>(id),
    projectId: const Value<String>('project-1'),
    templateId: Value<String>(templateId),
    status: Value<String>(status),
    processingMode: const Value<String>('manual'),
    contextJson: const Value<String>('{}'),
    identityHash: Value<String>(hash),
    source: const Value<String>('capture'),
    capturedAt: Value<DateTime>(DateTime.utc(2026, 9, 17, 8)),
    capturedBy: const Value<String>('Ada'),
  );
}

PhotosCompanion _photoRow(
  String id, {
  required String recordId,
  required int sortOrder,
  required DateTime capturedAt,
  String? derivedFrom,
  int? rotation,
}) {
  return PhotosCompanion(
    id: Value<String>(id),
    projectId: const Value<String>('project-1'),
    recordId: Value<String?>(recordId),
    captureSessionId: const Value<String>('session-1'),
    originalFilename: Value<String>('$id.jpg'),
    storedFilename: Value<String>('$id.jpg'),
    relativePath: Value<String>('photos/$id.jpg'),
    photoType: const Value<String>('other'),
    sortOrder: Value<int>(sortOrder),
    width: const Value<int>(1),
    height: const Value<int>(1),
    fileSize: const Value<int>(1),
    mimeType: const Value<String>('image/jpeg'),
    sha256: Value<String>('sha-$id'),
    capturedAt: Value<DateTime>(capturedAt),
    derivedFrom: Value<String?>(derivedFrom),
    rotationDegrees: Value<int?>(rotation),
  );
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
    recycleTree:
        ({
          required String id,
          required String name,
          required String folderName,
        }) async {
          return (await folders.recycle(
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

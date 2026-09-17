import 'package:drift/drift.dart' show Value;
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/db/tables/projects.dart' as projects_db;
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/db/tables/templates.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';
import 'package:tapture/features/projects/domain/project_repository.dart';
import 'package:tapture/features/records/domain/record_repository.dart';
import 'package:tapture/features/templates/domain/template_repository.dart';

/// A valid [Project] for one-line test setup.
typedef ProjectFactory = Project;

/// A valid [RecordDraft] for one-line test setup.
typedef RecordFactory = RecordDraft;

/// A valid [TemplateDef] for one-line test setup.
typedef TemplateFactory = TemplateDef;

/// A valid [PhotoAsset] for one-line test setup.
typedef PhotoFactory = PhotoAsset;

/// A project with sensible defaults. Override [name] when the test cares.
ProjectFactory aProject({String? name}) {
  return (
    id: 'project-1',
    name: name ?? 'Test project',
    status: ProjectStatus.active,
    folderName: 'test-project',
  );
}

/// A record draft filed under [projectId] with optional [fields].
RecordFactory aRecord({String? projectId, Map<String, String>? fields}) {
  return (
    id: null,
    projectId: projectId ?? 'project-1',
    templateId: 'template-1',
    fields: fields ?? const <String, String>{'serial': 'A-1'},
  );
}

/// A template with sensible defaults. Override [name] when the test cares.
TemplateFactory aTemplate({String? name, String? projectId}) {
  return (
    id: 'template-1',
    projectId: projectId ?? 'project-1',
    name: name ?? 'Test template',
    version: 1,
  );
}

/// A photo with sensible defaults. Override [projectId] when the test cares.
PhotoFactory aPhoto({String? projectId, String? recordId}) {
  return (
    id: 'photo-1',
    projectId: projectId ?? 'project-1',
    recordId: recordId,
    relativePath: 'photos/_unfiled/seed.jpg',
    sha256: 'seed-sha',
  );
}

/// An in-memory database holding one project, one template, [records] rows and
/// one photo per record.
Future<sqlite.AppDatabase> seededDatabase({int records = 0}) async {
  final sqlite.AppDatabase db = sqlite.AppDatabase.memory();
  final DateTime capturedAt = DateTime.utc(2026, 9, 17, 8);
  final FixedClock clock = FixedClock(capturedAt);
  final UuidV7Service ids = UuidV7Service.sequence(clock);
  const String deviceId = 'device-test';
  try {
    final sqlite.Project project = _require(
      await projects_db.upsertProject(
        db,
        row: const sqlite.ProjectsCompanion(
          name: Value<String>('Seeded project'),
          client: Value<String>('Acme'),
          status: Value<projects_db.ProjectStatus>(
            projects_db.ProjectStatus.active,
          ),
          folderName: Value<String>('seeded-project'),
          settings: Value<String>('{}'),
        ),
        clock: clock,
        deviceId: deviceId,
        ids: ids,
      ),
    );
    final sqlite.Template template = _require(
      await upsertTemplate(
        db,
        row: sqlite.TemplatesCompanion(
          projectId: Value<String?>(project.id),
          name: const Value<String>('Seeded template'),
          kind: const Value<String>('equipment'),
          source: const Value<String>('shipped'),
        ),
        clock: clock,
        deviceId: deviceId,
        ids: ids,
      ),
    );
    for (int index = 0; index < records; index++) {
      final sqlite.RecordRow row = _require(
        await upsertRecord(
          db,
          row: sqlite.RecordsCompanion(
            projectId: Value<String>(project.id),
            templateId: Value<String>(template.id),
            status: const Value<String>('captured'),
            processingMode: const Value<String>('manual'),
            contextJson: const Value<String>('{}'),
            identityHash: Value<String>('hash-$index'),
            source: const Value<String>('capture'),
            capturedAt: Value<DateTime>(capturedAt),
            capturedBy: const Value<String>('Ada'),
          ),
          clock: clock,
          deviceId: deviceId,
          ids: ids,
        ),
      );
      _require(
        await upsertPhoto(
          db,
          row: sqlite.PhotosCompanion(
            projectId: Value<String>(project.id),
            recordId: Value<String?>(row.id),
            captureSessionId: const Value<String>('session-seed'),
            originalFilename: Value<String>('IMG_$index.jpg'),
            storedFilename: Value<String>('img-$index.jpg'),
            relativePath: Value<String>('photos/${row.id}/img-$index.jpg'),
            photoType: const Value<String>('front'),
            sortOrder: const Value<int>(0),
            width: const Value<int>(1600),
            height: const Value<int>(1200),
            fileSize: const Value<int>(2048),
            mimeType: const Value<String>('image/jpeg'),
            sha256: Value<String>('sha-$index'),
            capturedAt: Value<DateTime>(capturedAt),
          ),
          clock: clock,
          deviceId: deviceId,
          ids: ids,
        ),
      );
    }
    return db;
  } on Object {
    await db.close();
    rethrow;
  }
}

T _require<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw StateError(
      failure.message,
    ),
  };
}

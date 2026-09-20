import 'dart:typed_data';

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
import 'package:tapture/features/feedback/domain/feedback_category.dart';
import 'package:tapture/features/feedback/domain/feedback_context.dart';
import 'package:tapture/features/feedback/domain/feedback_device_type.dart';
import 'package:tapture/features/feedback/domain/feedback_entry.dart';
import 'package:tapture/features/feedback/domain/feedback_submitter.dart';
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
ProjectFactory aProject({
  String? id,
  String? name,
  ProjectStatus? status,
  DateTime? updatedAt,
  DateTime? pinnedAt,
}) {
  final DateTime at = DateTime.utc(2026, 9, 17, 8);
  return Project(
    id: id ?? 'project-1',
    name: name ?? 'Test project',
    status: status ?? ProjectStatus.active,
    folderName: 'test-project',
    settings: const ProjectSettings(),
    createdAt: at,
    updatedAt: updatedAt ?? at,
    pinnedAt: pinnedAt,
  );
}

/// A record draft filed under [projectId] with optional [fields].
RecordFactory aRecord({
  String? projectId,
  String? templateId,
  Map<String, String>? fields,
}) {
  return (
    id: null,
    projectId: projectId ?? 'project-1',
    templateId: templateId ?? 'template-1',
    fields: fields ?? const <String, String>{'serial': 'A-1'},
  );
}

/// A template with sensible defaults. Override [name] when the test cares.
TemplateFactory aTemplate({
  String? id,
  String? name,
  String? projectId,
  String? templateKey,
  int? version,
  List<FieldDef>? fields,
  List<String>? identityFieldKeys,
  List<TemplateRow>? rows,
}) {
  return TemplateDef(
    id: id ?? 'template-1',
    templateKey: templateKey ?? 'test_template',
    name: name ?? 'Test template',
    version: version ?? 1,
    fields: fields ?? const <FieldDef>[],
    identityFieldKeys: identityFieldKeys ?? const <String>[],
    rows: rows ?? const <TemplateRow>[],
    projectId: projectId ?? 'project-1',
    kind: 'item',
    source: 'built',
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

/// A feedback entry with sensible defaults.
FeedbackEntry aFeedbackEntry({
  String id = 'fb-1',
  int number = 1,
  DateTime? submittedAtUtc,
  FeedbackCategory category = FeedbackCategory.general,
  String? otherCategory,
  String message = 'The list is slow',
  bool hasScreenshot = false,
  String screen = 'Projects',
  String platform = 'windows',
  FeedbackDeviceType deviceType = FeedbackDeviceType.desktop,
  FeedbackSubmitter submitter = FeedbackSubmitter.localOperator,
}) {
  return FeedbackEntry(
    id: id,
    number: number,
    submittedAtUtc: submittedAtUtc ?? DateTime.utc(2026, 9, 18, 7, 2),
    category: category,
    otherCategory: otherCategory,
    message: message,
    hasScreenshot: hasScreenshot,
    context: FeedbackContext(
      capturedAtUtc: DateTime.utc(2026, 9, 18, 7, 1),
      submitter: submitter,
      operatorName: 'Ada',
      operatorInitials: 'A',
      operatorContact: 'ada@x',
      accountId: null,
      screen: screen,
      route: '/projects',
      routeName: 'projects',
      pageUrl: null,
      projectId: 'p1',
      platform: platform,
      deviceType: deviceType,
      appVersion: '1.0.0',
      environment: 'development',
      locale: 'en',
      timeZone: 'EAT',
      utcOffsetMinutes: 180,
      viewportWidth: 1280,
      viewportHeight: 720,
      devicePixelRatio: 1.5,
      displayWidth: 1920,
      displayHeight: 1080,
      orientation: 'landscape',
      breakpoint: 'expanded',
      theme: 'light',
      textScale: 1,
      connectivity: 'online',
      userAgent: 'test-agent',
      addresses: const <String>['192.0.2.10'],
      deviceId: 'device-1',
      deviceModel: 'test-model',
      osVersion: 'test-os',
    ),
  );
}

/// A 1-by-1 PNG, valid for both storage and [Image.memory].
final Uint8List aFeedbackPng = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

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

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/device/device_identity.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/face_blur.dart';
import 'package:tapture/core/export/face_detector.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/photo_privacy_service.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/exports/data/deliverable_repository_impl.dart';
import 'package:tapture/features/exports/data/export_repository_impl.dart';
import 'package:tapture/features/exports/domain/deliverable_repository.dart';
import 'package:tapture/features/projects/data/project_repository_impl.dart';
import 'package:tapture/features/projects/domain/project.dart';
import 'package:tapture/features/records/data/record_repository_impl.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';
import 'package:tapture/features/templates/domain/template_repository.dart';

import '../../../core/db/record_rows.dart';
import '../../../support/factories.dart';

final class ExportPrivacyFixture {
  ExportPrivacyFixture(
    this.db,
    this.storage,
    this.root,
    this.project,
    this.reports,
    this.packages,
    this.privacy,
  );
  final sqlite.AppDatabase db;
  final StorageRoot storage;
  final Directory root;
  final Project project;
  final DeliverableRepositoryImpl reports;
  final ExportRepositoryImpl packages;
  final PhotoPrivacyService privacy;
  static final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 30));

  static Future<ExportPrivacyFixture> open({
    bool blurFaces = false,
    FaceDetector? detector,
  }) async {
    final sqlite.AppDatabase db = sqlite.AppDatabase.memory();
    final Directory directory = await Directory.systemTemp.createTemp(
      'tapture-privacy-export-',
    );
    final StorageRoot storage = StorageRoot.fake(documentsDirectory: directory);
    final Directory root = privacyValue(await storage.resolve());
    addTearDown(() async {
      await db.close();
      directory.deleteSync(recursive: true);
    });
    final IdService ids = UuidV7Service.sequence(clock);
    final Project project = privacyValue(
      await ProjectRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'device',
        ids: ids,
      ).create(aProject()),
    );
    final TemplateRepositoryImpl templates = TemplateRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device',
      ids: ids,
    );
    privacyValue(
      await templates.save(
        aTemplate(
          fields: const <FieldDef>[
            FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
            FieldDef(
              fieldKey: 'permission',
              label: 'Consent',
              type: FieldType.consent,
              requiredness: Requiredness.required,
            ),
            FieldDef(
              fieldKey: 'position',
              label: 'Position',
              type: FieldType.gpsLocation,
            ),
            FieldDef(
              fieldKey: 'survey_fix',
              label: 'Survey fix',
              type: FieldType.text,
              autoFill: AutoFill.gps,
            ),
          ],
        ),
      ),
    );
    final PhotoPrivacyService privacy = PhotoPrivacyService(
      db: db,
      files: FileReader(storageRoot: storage),
      writer: FileWriter(storageRoot: storage),
      clock: clock,
      deviceId: 'device',
      detector: detector,
    );
    final RecordRepositoryImpl records = RecordRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device',
      ids: ids,
    );
    final DeliverableRepositoryImpl reports = DeliverableRepositoryImpl(
      db: db,
      storageRoot: storage,
      records: records,
      templates: templates,
      clock: clock,
      ids: ids,
      deviceId: 'device',
      privacy: privacy,
      blurFaces: () async => blurFaces,
    );
    final ExportRepositoryImpl packages = ExportRepositoryImpl(
      db: db,
      storageRoot: storage,
      clock: clock,
      deviceId: 'device',
      ids: ids,
      templates: templates,
      privacy: privacy,
      blurFaces: () async => blurFaces,
      bundles: BundleWriter(
        db: db,
        storageRoot: storage,
        files: FileReader(storageRoot: storage),
        clock: clock,
        ids: ids,
        deviceId: 'device',
        device: () async => const DeviceDescriptor.fake(),
        inBrowser: false,
      ),
    );
    return ExportPrivacyFixture(
      db,
      storage,
      root,
      project,
      reports,
      packages,
      privacy,
    );
  }

  Future<void> record(String id, {required bool consent}) async {
    await seedRecord(
      db,
      id,
      projectId: project.id,
      templateId: 'template-1',
      status: 'approved',
    );
    await db.customStatement(
      'UPDATE records SET context_json = ? WHERE id = ?',
      <Object>[
        jsonEncode(<String, String>{
          'site': 'Kasubi',
          'gps_latitude': '12.345678',
          'survey_fix': '45.987654',
        }),
        id,
      ],
    );
    await seedField(
      db,
      '$id-serial',
      recordId: id,
      fieldKey: 'serial',
      raw: id,
      source: 'TYPED',
    );
    for (final String key in <String>['gps_latitude', 'survey_fix']) {
      await seedField(
        db,
        '$id-$key',
        recordId: id,
        fieldKey: key,
        raw: key == 'gps_latitude'
            ? '12.345678'
            : '{"latitude":12.345678,"longitude":45.987654}',
        source: 'TYPED',
      );
      await appendAudit(
        db,
        entityType: 'records',
        entityId: id,
        action: AuditAction.updated,
        fieldKey: key,
        previousValue: '12.345678',
        newValue: '45.987654',
        clock: clock,
        device: 'device',
      );
    }
    final String stamp = jsonEncode(<String, Object?>{
      'by': 'Ada',
      'at': clock.nowUtc().toIso8601String(),
    });
    await seedField(
      db,
      '$id-consent',
      recordId: id,
      fieldKey: 'permission',
      raw: consent ? stamp : '',
      refined: consent ? null : stamp,
      approved: consent ? null : stamp,
      source: 'TYPED',
    );
    await seedField(
      db,
      '$id-location',
      recordId: id,
      fieldKey: 'position',
      raw: '{"latitude":12.345678,"longitude":45.987654}',
      source: 'TYPED',
    );
    await appendAudit(
      db,
      entityType: 'records',
      entityId: id,
      action: AuditAction.updated,
      fieldKey: 'position',
      previousValue: '12.345678',
      newValue: '45.987654',
      clock: clock,
      device: 'device',
    );
  }

  Future<PreparedDeliverable> prepare() async => privacyValue(
    await reports.prepare(
      privacyValue(await reports.options(project.id)).copyWith(
        formats: const <ExportFormat>{ExportFormat.json},
        scope: (
          kind: ExportScopeKind.all,
          context: null,
          from: null,
          to: null,
          filter: null,
        ),
      ),
      cancel: CancellationToken(),
    ),
  );
  File file(String path) => File('${root.path}/$path');
  String photoPath(String id) =>
      'projects/${project.folderName}/photos/$id.jpg';
  Future<Uint8List> photo(String id, String record) async {
    final img.Image image = img.Image(width: 8, height: 8);
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        image.setPixelRgb(x, y, x * 27 + 5, y * 25 + 5, 40);
      }
    }
    final Uint8List bytes = img.encodePng(image);
    file(photoPath(id)).parent.createSync(recursive: true);
    file(photoPath(id)).writeAsBytesSync(bytes);
    await seedPhoto(db, id, projectId: project.id, recordId: record);
    await (db.update(
      db.photos,
    )..where((sqlite.$PhotosTable row) => row.id.equals(id))).write(
      const sqlite.PhotosCompanion(
        gpsLat: Value<double?>(12.345678),
        gpsLon: Value<double?>(45.987654),
      ),
    );
    return bytes;
  }
}

final class FixedPrivacyFaces extends FaceDetector {
  const FixedPrivacyFaces();
  @override
  Future<Result<List<FaceRect>>> detect(
    Uint8List bytes, {
    CancellationToken? cancel,
  }) async => const Success<List<FaceRect>>(<FaceRect>[
    (x: 4, y: 4, width: 3, height: 3),
  ]);
}

T privacyValue<T>(Result<T> result) => result.fold(
  (Failure failure) => throw TestFailure(failure.message),
  (T value) => value,
);

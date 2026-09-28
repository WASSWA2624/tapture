import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart' show Archive, ArchiveFile, ZipDecoder;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart'
    show AppDatabase, AuditLogData, ExportRow;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/exports/data/deliverable_repository_impl.dart';
import 'package:tapture/features/exports/domain/deliverable_repository.dart';
import 'package:tapture/features/exports/domain/export_validation.dart';
import 'package:tapture/features/projects/data/project_repository_impl.dart';
import 'package:tapture/features/projects/domain/project.dart';
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/templates/domain/template_repository.dart';

import '../../../support/factories.dart';
import '../../../support/fakes/fake_record_repository.dart';
import '../../../support/fakes/fake_template_repository.dart';

void main() {
  test(
    'a deliverable package holds the outputs, the photos and a replayable request',
    () async {
      final _Harness harness = await _Harness.open();
      await harness.seedTemplate();
      final String photoPath =
          'projects/${harness.project.folderName}/photos/r1/front.jpg';
      harness.writeFile(photoPath, <int>[1, 2, 3]);
      harness.records.seedEntry(
        aRecordEntry(id: 'r1', status: RecordStatus.approved).copyWith(
          photos: <RecordPhoto>[
            RecordPhoto(
              id: 'ph1',
              sha256: 'sha-1',
              storagePath: photoPath,
              photoType: 'front',
            ),
          ],
        ),
      );

      final ExportRequest options = _ok(
        await harness.repo.options(harness.project.id),
      );
      expect(options.formats, <ExportFormat>{
        ExportFormat.xlsx,
        ExportFormat.zip,
      });
      expect(options.extras.photoMode, 'relative');
      final PreparedDeliverable prepared = _ok(
        await harness.repo.prepare(options, cancel: CancellationToken()),
      );
      expect(prepared.validation.incomplete, isEmpty);
      expect(prepared.validation.unapproved, isEmpty);
      final List<DeliverableProgress> progress = <DeliverableProgress>[];
      final DeliverableEntry entry = _ok(
        await harness.repo.write(
          prepared.request,
          cancel: CancellationToken(),
          onProgress: progress.add,
        ),
      );

      expect(entry.projectId, harness.project.id);
      expect(entry.version, 1);
      expect(entry.recordCount, 1);
      expect(entry.path, endsWith('/deliverables.zip'));
      expect(entry.fileName, endsWith('_v1.zip'));
      expect(entry.mimeType, 'application/zip');
      expect(entry.missing, isFalse);
      expect(
        progress.map((DeliverableProgress step) => step.stage),
        containsAll(<String>['records', 'photos', 'archive']),
      );
      expect(progress, contains((stage: 'archive', fraction: 1.0)));

      final Map<String, List<int>> archive = harness.unzip(entry.path);
      expect(
        archive.keys,
        containsAll(<String>[
          'outputs/records.xlsx',
          'outputs/dictionary.json',
          'manifest.json',
        ]),
      );
      final String photo = archive.keys.singleWhere(
        (String name) => name.startsWith('photos/'),
      );
      expect(archive[photo], <int>[1, 2, 3]);
      // The workbook sits in outputs/, so its relative link steps up a level.
      final String workbook = _xml(archive['outputs/records.xlsx']!);
      expect(workbook, contains('../$photo'));
      expect(workbook, contains('A-1'));

      final String folder = entry.path.substring(
        0,
        entry.path.lastIndexOf('/'),
      );
      expect(harness.file('$folder/request.json').existsSync(), isTrue);
      expect(harness.file('$folder/manifest.json').existsSync(), isTrue);
      // The staged outputs are removed once the package is written.
      expect(harness.file('$folder/.staging/0').existsSync(), isFalse);
      expect(harness.file('$folder/.staging/1').existsSync(), isFalse);

      final List<ExportRow> rows = await harness.db
          .select(harness.db.exports)
          .get();
      expect(rows.single.id, entry.id);
      expect(rows.single.filters, contains('"kind":"deliverable"'));
      final List<AuditLogData> audit = await harness.db
          .select(harness.db.auditLog)
          .get();
      final List<AuditLogData> exported = <AuditLogData>[
        for (final AuditLogData row in audit)
          if (row.fieldKey == 'export') row,
      ];
      expect(exported.single.entityId, 'r1');
      expect(exported.single.newValue, 'v1');

      final List<DeliverableEntry> history = await harness.repo
          .watchHistory(projectId: harness.project.id)
          .first;
      expect(history.single.id, entry.id);
      final ExportRequest replayed = _ok(await harness.repo.replay(entry.id));
      expect(replayed.records.single.id, 'r1');
      expect(
        replayed.files,
        contains((path: 'outputs/records.xlsx', role: 'output')),
      );
      expect(replayed.files, contains((path: photo, role: 'photo')));
    },
  );

  test(
    'a record whose template was deleted is still delivered, flagged',
    () async {
      final _Harness harness = await _Harness.open();
      await harness.seedTemplate();
      harness.records.seedEntry(
        aRecordEntry(id: 'r1', status: RecordStatus.approved),
      );
      _ok(await harness.templates.delete('template-1', reason: 'Replaced'));

      final ExportRequest options = _ok(
        await harness.repo.options(harness.project.id),
      );
      final PreparedDeliverable prepared = _ok(
        await harness.repo.prepare(options, cancel: CancellationToken()),
      );
      expect(prepared.validation.incomplete, <String>['r1']);
      final ExportGate gate = ExportValidation.apply(
        request: prepared.request,
        report: prepared.validation,
        choice: ExportGateChoice.exportAnyway,
      );
      final DeliverableEntry entry = _ok(
        await harness.repo.write(gate.request, cancel: CancellationToken()),
      );

      expect(entry.recordCount, 1);
      final String workbook = _xml(
        harness.unzip(entry.path)['outputs/records.xlsx']!,
      );
      expect(workbook, contains('Removed template'));
      expect(workbook, contains('A-1'));
    },
  );

  test('a cancelled write leaves no file and no history', () async {
    final _Harness harness = await _Harness.open();
    await harness.seedTemplate();
    harness.records.seedEntry(
      aRecordEntry(id: 'r1', status: RecordStatus.approved),
    );
    final PreparedDeliverable prepared = _ok(
      await harness.repo.prepare(
        _ok(await harness.repo.options(harness.project.id)),
        cancel: CancellationToken(),
      ),
    );

    final Result<DeliverableEntry> written = await harness.repo.write(
      prepared.request,
      cancel: CancellationToken()..cancel(),
    );

    expect(_failure(written), isA<CancelledFailure>());
    expect(await harness.db.select(harness.db.exports).get(), isEmpty);
    expect(
      Directory(
        '${harness.root.path}/projects/${harness.project.folderName}/exports',
      ).existsSync(),
      isFalse,
    );
  });

  test('options are remembered without any captured values', () async {
    final _Harness harness = await _Harness.open();
    final ExportRequest chosen = ExportRequest(
      projectId: harness.project.id,
      formats: const <ExportFormat>{ExportFormat.csv},
      scope: (
        kind: ExportScopeKind.all,
        context: null,
        from: null,
        to: null,
        filter: null,
      ),
      columns: (raw: true, refined: false, confidence: true, evidence: false),
      extras: (
        dictionary: false,
        photoIndex: false,
        photoMode: 'filename',
        delimiter: ';',
      ),
      records: const <ExportRecord>[
        ExportRecord(
          id: 'r1',
          number: '1',
          templateId: 'template-1',
          templateName: 'Test template',
          status: 'approved',
        ),
      ],
    );

    _ok(await harness.repo.remember(chosen));
    final ExportRequest restored = _ok(
      await harness.repo.options(harness.project.id),
    );

    expect(restored.formats, <ExportFormat>{ExportFormat.csv});
    expect(restored.scope.kind, ExportScopeKind.all);
    expect(restored.columns.raw, isTrue);
    expect(restored.columns.confidence, isTrue);
    expect(restored.extras.delimiter, ';');
    expect(restored.records, isEmpty);
  });

  test('a write needs records, an output and a project', () async {
    final _Harness harness = await _Harness.open();
    final ExportRequest empty = _ok(
      await harness.repo.options(harness.project.id),
    );
    const ExportRecord record = ExportRecord(
      id: 'r1',
      number: '1',
      templateId: 'template-1',
      templateName: 'Test template',
      status: 'approved',
    );

    expect(
      _failure(
        await harness.repo.write(empty, cancel: CancellationToken()),
      ).message,
      'Nothing to export',
    );
    expect(
      _failure(
        await harness.repo.write(
          ExportRequest.fromJson(<String, Object?>{
            ...empty.copyWith(records: <ExportRecord>[record]).toJson(),
            'formats': <String>['zip'],
          }),
          cancel: CancellationToken(),
        ),
      ).message,
      'Choose an output format.',
    );
    final ExportRequest elsewhere = ExportRequest.fromJson(<String, Object?>{
      ...empty.copyWith(records: <ExportRecord>[record]).toJson(),
      'projectId': 'missing',
    });
    expect(
      _failure(
        await harness.repo.write(elsewhere, cancel: CancellationToken()),
      ),
      isA<StorageFailure>(),
    );
    expect(
      _failure(await harness.repo.options('missing')),
      isA<StorageFailure>(),
    );
    expect(
      _failure(await harness.repo.remember(elsewhere)),
      isA<StorageFailure>(),
    );
    expect(await harness.db.select(harness.db.exports).get(), isEmpty);
  });
}

/// One project on an in-memory database with a temporary storage root, and
/// the deliverable repository over fake record and template stores.
final class _Harness {
  _Harness._({
    required this.db,
    required this.root,
    required this.project,
    required this.records,
    required this.templates,
    required this.repo,
  });

  final AppDatabase db;
  final Directory root;
  final Project project;
  final FakeRecordRepository records;
  final FakeTemplateRepository templates;
  final DeliverableRepositoryImpl repo;

  static Future<_Harness> open() async {
    final AppDatabase db = AppDatabase.memory();
    final Directory documents = await Directory.systemTemp.createTemp(
      'tapture-deliverable-',
    );
    final StorageRoot storage = StorageRoot.fake(documentsDirectory: documents);
    final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 24, 8));
    final UuidV7Service ids = UuidV7Service.sequence(clock);
    final Project project = _ok(
      await ProjectRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'device-test',
        ids: ids,
      ).create(aProject()),
    );
    final FakeRecordRepository records = FakeRecordRepository();
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(() async {
      records.dispose();
      templates.dispose();
      await db.close();
      if (documents.existsSync()) {
        try {
          documents.deleteSync(recursive: true);
        } on FileSystemException {
          // Windows can still hold a file a reader just closed.
        }
      }
    });
    return _Harness._(
      db: db,
      root: _ok(await storage.resolve()),
      project: project,
      records: records,
      templates: templates,
      repo: DeliverableRepositoryImpl(
        db: db,
        storageRoot: storage,
        records: records,
        templates: templates,
        clock: clock,
        ids: ids,
        deviceId: 'device-test',
        inBrowser: false,
      ),
    );
  }

  /// Saves `template-1` with one optional text field, `serial`.
  Future<void> seedTemplate() async {
    _ok(
      await templates.save(
        aTemplate(
          fields: const <FieldDef>[
            FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
          ],
        ),
      ),
    );
  }

  /// The file at [relativePath] under the storage root.
  File file(String relativePath) => File('${root.path}/$relativePath');

  /// Writes [bytes] at [relativePath] under the storage root.
  void writeFile(String relativePath, List<int> bytes) {
    file(relativePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
  }

  /// The archive at [relativePath], entry name to bytes.
  Map<String, List<int>> unzip(String relativePath) {
    final Archive archive = ZipDecoder().decodeBytes(
      file(relativePath).readAsBytesSync(),
    );
    return <String, List<int>>{
      for (final ArchiveFile entry in archive.files)
        if (entry.isFile) entry.name: entry.content as List<int>,
    };
  }
}

/// Every XML part of the workbook [bytes], joined.
String _xml(List<int> bytes) {
  final Archive archive = ZipDecoder().decodeBytes(bytes);
  final StringBuffer buffer = StringBuffer();
  for (final ArchiveFile file in archive.files) {
    if (file.name.endsWith('.xml')) {
      buffer.write(utf8.decode(file.content as List<int>));
    }
  }
  return buffer.toString();
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
    Success<T>() => throw TestFailure('Expected a failure.'),
    FailureResult<T>(:final Failure failure) => failure,
  };
}

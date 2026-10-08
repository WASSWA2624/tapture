import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart' show Archive, ArchiveFile, ZipDecoder;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart'
    show AppDatabase, AuditLogData, ExportRow;
import 'package:tapture/core/db/tables/device_profile.dart';
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
import 'package:tapture/features/meetings/data/meeting_repository_impl.dart';
import 'package:tapture/features/meetings/domain/action_entry.dart';
import 'package:tapture/features/meetings/domain/attendee.dart';
import 'package:tapture/features/meetings/domain/decision.dart';
import 'package:tapture/features/meetings/domain/meeting.dart';
import 'package:tapture/features/projects/data/project_repository_impl.dart';
import 'package:tapture/features/projects/domain/project.dart';
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/templates/domain/template_repository.dart';

import '../../../core/db/record_rows.dart';
import '../../../support/factories.dart';
import '../../../support/fakes/fake_record_repository.dart';
import '../../../support/fakes/fake_template_repository.dart';
import '../../../support/pdf_inspector.dart';

void main() {
  test(
    'a deliverable package holds the outputs, the photos and a replayable request',
    () async {
      final _Harness harness = await _Harness.open();
      await harness.seedTemplate();
      final String photoPath =
          'projects/${harness.project.folderName}/photos/r1/front.jpg';
      final Uint8List originalPhoto = img.encodePng(
        img.Image(width: 8, height: 8),
      );
      harness.writeFile(photoPath, originalPhoto);
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

      final ExportRequest defaults = _ok(
        await harness.repo.options(harness.project.id),
      );
      // The project package is the default output (task 076, D13); the
      // deliverable writes the chosen files.
      expect(defaults.isProjectPackage, isTrue);
      expect(defaults.extras.photoMode, 'relative');
      final ExportRequest options = defaults.copyWith(
        formats: const <ExportFormat>{ExportFormat.xlsx, ExportFormat.zip},
      );
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
      expect(img.decodeImage(Uint8List.fromList(archive[photo]!))!.width, 8);
      expect(
        File('${harness.root.path}/$photoPath').readAsBytesSync(),
        originalPhoto,
      );
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

      final PreparedDeliverable prepared = _ok(
        await harness.repo.prepare(
          await harness.options(),
          cancel: CancellationToken(),
        ),
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
        await harness.options(),
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
        pdfPhotos: 'thumbnail',
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
      ...empty
          .copyWith(
            records: <ExportRecord>[record],
            formats: const <ExportFormat>{ExportFormat.xlsx},
          )
          .toJson(),
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

  test('a PDF export cancelled mid-render leaves no file, no history and the '
      'original photo unchanged', () async {
    final _Harness harness = await _Harness.open();
    await harness.seedTemplate();
    final List<int> original = harness.seedPhotoRecord('r1');
    final PreparedDeliverable prepared = _ok(
      await harness.repo.prepare(
        await harness.options(formats: const <ExportFormat>{ExportFormat.pdf}),
        cancel: CancellationToken(),
      ),
    );
    final CancellationToken cancel = CancellationToken();
    final List<String> stages = <String>[];

    final Result<DeliverableEntry> written = await harness.repo.write(
      prepared.request,
      cancel: cancel,
      onProgress: (DeliverableProgress progress) {
        stages.add(progress.stage);
        if (progress.stage == 'reports') {
          cancel.cancel();
        }
      },
    );

    expect(_failure(written), isA<CancelledFailure>());
    expect(stages, contains('reports'));
    expect(await harness.db.select(harness.db.exports).get(), isEmpty);
    expect(harness.exportedFiles(), isEmpty);
    expect(harness.file(harness.photoPath('r1')).readAsBytesSync(), original);
  });

  test(
    'a PDF export reports records, photos, reports and archive in order',
    () async {
      final _Harness harness = await _Harness.open();
      await harness.seedTemplate();
      harness.seedPhotoRecord('r1');
      final PreparedDeliverable prepared = _ok(
        await harness.repo.prepare(
          await harness.options(
            formats: const <ExportFormat>{ExportFormat.pdf},
          ),
          cancel: CancellationToken(),
        ),
      );
      final List<String> stages = <String>[];

      final DeliverableEntry entry = _ok(
        await harness.repo.write(
          prepared.request,
          cancel: CancellationToken(),
          onProgress: (DeliverableProgress progress) {
            if (stages.isEmpty || stages.last != progress.stage) {
              stages.add(progress.stage);
            }
            expect(progress.fraction, inInclusiveRange(0, 1));
          },
        ),
      );

      expect(stages, <String>['records', 'photos', 'reports', 'archive']);
      final Map<String, List<int>> archive = harness.unzip(entry.path);
      expect(
        archive.keys,
        containsAll(<String>['outputs/records.pdf', 'outputs/summary.pdf']),
      );
      final PdfInspector records = PdfInspector(
        Uint8List.fromList(archive['outputs/records.pdf']!),
      );
      expect(records.problems, isEmpty);
      expect(records.images, hasLength(1));
    },
  );

  test(
    'history names the operator and the manifest records the request',
    () async {
      final _Harness harness = await _Harness.open();
      await harness.seedTemplate();
      await ensureDeviceProfile(
        harness.db,
        deviceId: 'device-test',
        operatorName: 'W. Wasswa',
      );
      harness.records.seedEntry(
        aRecordEntry(id: 'r1', status: RecordStatus.approved),
      );
      final PreparedDeliverable prepared = _ok(
        await harness.repo.prepare(
          await harness.options(),
          cancel: CancellationToken(),
        ),
      );

      final DeliverableEntry entry = _ok(
        await harness.repo.write(prepared.request, cancel: CancellationToken()),
      );

      expect(entry.operatorName, 'W. Wasswa');
      final List<DeliverableEntry> history = await harness.repo
          .watchHistory(projectId: harness.project.id)
          .first;
      expect(history.single.operatorName, 'W. Wasswa');
      expect(history.single.package, isFalse);
      final String folder = entry.path.substring(
        0,
        entry.path.lastIndexOf('/'),
      );
      final Map<String, Object?> manifest = Map<String, Object?>.from(
        jsonDecode(harness.file('$folder/manifest.json').readAsStringSync())
            as Map,
      );
      expect(manifest['exportedBy'], 'W. Wasswa');
      final Map<String, Object?> request = Map<String, Object?>.from(
        manifest['request']! as Map,
      );
      expect(request['formats'], <String>['xlsx', 'zip']);
      expect(
        Map<String, Object?>.from(request['scope']! as Map)['kind'],
        'approved',
      );
      expect(manifest['entries'], hasLength(1));
    },
  );

  test('a second export the same day keeps the first file', () async {
    final _Harness harness = await _Harness.open();
    await harness.seedTemplate();
    harness.records.seedEntry(
      aRecordEntry(id: 'r1', status: RecordStatus.approved),
    );
    final PreparedDeliverable prepared = _ok(
      await harness.repo.prepare(
        await harness.options(),
        cancel: CancellationToken(),
      ),
    );

    final DeliverableEntry first = _ok(
      await harness.repo.write(prepared.request, cancel: CancellationToken()),
    );
    final DeliverableEntry second = _ok(
      await harness.repo.write(prepared.request, cancel: CancellationToken()),
    );

    final String exports = 'projects/${harness.project.folderName}/exports';
    expect(first.path, '$exports/2026-09-24/v1/deliverables.zip');
    expect(second.path, '$exports/2026-09-24/v2/deliverables.zip');
    expect(harness.file(first.path).existsSync(), isTrue);
    expect(harness.file(second.path).existsSync(), isTrue);
  });

  test('a checklist export prints a never-captured row as Not found and counts '
      'it on the cover', () async {
    final _Harness harness = await _Harness.open();
    await harness.seedTemplate();
    await seedRow(harness.db, 'template_rows', <String, Object?>{
      'id': 'row-exits',
      'template_id': 'template-1',
      'output_row_number': 2,
      'identifier': 'exits',
      'label': 'Fire exits clear',
    });
    await seedRow(harness.db, 'template_rows', <String, Object?>{
      'id': 'row-extinguisher',
      'template_id': 'template-1',
      'output_row_number': 3,
      'identifier': 'extinguisher',
      'label': 'Extinguisher in date',
    });
    harness.records.seedEntry(
      aRecordEntry(
        id: 'r1',
        status: RecordStatus.approved,
      ).copyWith(templateRowId: 'row-exits'),
    );
    final PreparedDeliverable prepared = _ok(
      await harness.repo.prepare(
        await harness.options(formats: const <ExportFormat>{ExportFormat.pdf}),
        cancel: CancellationToken(),
      ),
    );

    final DeliverableEntry entry = _ok(
      await harness.repo.write(prepared.request, cancel: CancellationToken()),
    );

    final Map<String, List<int>> archive = harness.unzip(entry.path);
    final String inspection = PdfInspector(
      Uint8List.fromList(
        archive.entries
            .singleWhere(
              (MapEntry<String, List<int>> file) =>
                  file.key.startsWith('outputs/inspection-'),
            )
            .value,
      ),
    ).transcript;
    expect(inspection, contains('Fire exits clear\nSerial: A-1'));
    expect(inspection, contains('Extinguisher in date\nNot found'));
    expect(inspection, contains('1 not found'));
  });

  test('a meeting whose actions have no owner is blocked, and stays out even '
      'when exported anyway', () async {
    final _Harness harness = await _Harness.open();
    await harness.seedMeetingTemplate(Requiredness.required);
    await harness.saveMeeting('r-meet', const <ActionEntry>[
      ActionEntry(id: 'a1', text: 'Buy paint'),
    ]);
    harness.records.seedEntry(
      aRecordEntry(id: 'r1', status: RecordStatus.approved),
    );

    final PreparedDeliverable prepared = _ok(
      await harness.repo.prepare(
        await harness.options(),
        cancel: CancellationToken(),
      ),
    );

    expect(prepared.validation.blocked, <String>['r-meet']);
    final ExportGate gate = ExportValidation.apply(
      request: prepared.request,
      report: prepared.validation,
      choice: ExportGateChoice.exportAnyway,
    );
    expect(
      gate.request.records.map((ExportRecord record) => record.id),
      <String>['r1'],
    );
  });

  test(
    'an exported meeting carries its minutes and its action register',
    () async {
      final _Harness harness = await _Harness.open();
      await harness.seedMeetingTemplate(Requiredness.required);
      await harness.saveMeeting('r-meet', <ActionEntry>[
        ActionEntry(
          id: 'a1',
          text: 'Buy paint',
          ownerName: 'Ada Lovelace',
          due: DateTime.utc(2026, 9, 26),
        ),
      ]);
      final PreparedDeliverable prepared = _ok(
        await harness.repo.prepare(
          await harness.options(
            formats: const <ExportFormat>{ExportFormat.pdf, ExportFormat.csv},
          ),
          cancel: CancellationToken(),
        ),
      );
      expect(prepared.validation.blocked, isEmpty);

      final DeliverableEntry entry = _ok(
        await harness.repo.write(prepared.request, cancel: CancellationToken()),
      );

      final Map<String, List<int>> archive = harness.unzip(entry.path);
      final String minutes = PdfInspector(
        Uint8List.fromList(
          archive.entries
              .singleWhere(
                (MapEntry<String, List<int>> file) =>
                    file.key.startsWith('outputs/minutes-'),
              )
              .value,
        ),
      ).transcript;
      expect(minutes, contains('Ada Lovelace'));
      expect(minutes, contains('Grace Hopper (Apology)'));
      expect(minutes, contains('Raw notes\nWe agreed to paint the gate.'));
      expect(minutes, contains('Refined minutes\nThe gate will be painted.'));
      expect(minutes, contains('Paint the gate'));
      expect(minutes, contains('Buy paint'));
      expect(
        utf8.decode(archive['outputs/action_register.csv']!),
        contains('Site meeting,Buy paint,Ada Lovelace,2026-09-26,Open'),
      );
    },
  );

  test('an export prints each finished transcript raw as heard with its edit '
      'beside it, in the minutes and the transcripts report', () async {
    final _Harness harness = await _Harness.open();
    await harness.seedMeetingTemplate(Requiredness.required);
    await harness.saveMeeting('r-meet', <ActionEntry>[
      ActionEntry(
        id: 'a1',
        text: 'Buy paint',
        ownerName: 'Ada Lovelace',
        due: DateTime.utc(2026, 9, 26),
      ),
    ]);
    await harness.seedTranscript(
      't-meeting',
      ownerKind: 'meeting',
      ownerId: 'meeting-r-meet',
      attachedTo: 'r-meet',
      lines: <String>['paint the gate', 'by friday'],
      edited: 'Paint the gate by Friday.',
    );
    await harness.seedTranscript(
      't-walk',
      ownerKind: 'capture',
      attachedTo: 'r-meet',
      title: 'Gate walk',
      lines: <String>['hinges rusted'],
      edited: 'Hinges are rusted.',
    );
    await harness.seedTranscript(
      't-live',
      ownerKind: 'capture',
      attachedTo: 'r-meet',
      title: 'Live walk',
      status: 'live',
      lines: <String>['still talking'],
    );
    final PreparedDeliverable prepared = _ok(
      await harness.repo.prepare(
        await harness.options(formats: const <ExportFormat>{ExportFormat.pdf}),
        cancel: CancellationToken(),
      ),
    );

    final DeliverableEntry entry = _ok(
      await harness.repo.write(prepared.request, cancel: CancellationToken()),
    );

    final Map<String, List<int>> archive = harness.unzip(entry.path);
    String pdf(String prefix) => PdfInspector(
      Uint8List.fromList(
        archive.entries
            .singleWhere(
              (MapEntry<String, List<int>> file) => file.key.startsWith(prefix),
            )
            .value,
      ),
    ).transcript;
    final String minutes = pdf('outputs/minutes-');
    expect(
      minutes,
      contains('Site meeting (as heard)\npaint the gate by friday'),
    );
    expect(
      minutes,
      contains('Site meeting (edited)\nPaint the gate by Friday.'),
    );
    final String heard = pdf('outputs/transcripts');
    expect(heard, contains('Gate walk (as heard)\nhinges rusted'));
    expect(heard, contains('Gate walk (edited)\nHinges are rusted.'));
    expect(heard, isNot(contains('paint the gate')));
    expect(heard, isNot(contains('still talking')));
    expect(minutes, isNot(contains('still talking')));
  });

  test('history lists project packages beside deliverables', () async {
    final _Harness harness = await _Harness.open();
    await seedRow(harness.db, 'exports', <String, Object?>{
      'id': 'package-1',
      'project_id': harness.project.id,
      'version': 1,
      'formats': '["bundle","xlsx"]',
      'filters': '{"project":"${harness.project.id}"}',
      'record_count': 3,
      'file_path': 'projects/${harness.project.folderName}/exports/p.zip',
      'file_hash': 'abc',
      'created_by': 'Ada',
    });

    final List<DeliverableEntry> history = await harness.repo
        .watchHistory(projectId: harness.project.id)
        .first;

    expect(history.single.id, 'package-1');
    expect(history.single.package, isTrue);
    expect(history.single.missing, isTrue);
    expect(history.single.operatorName, 'Ada');
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

  /// The project's remembered options writing [formats] instead of the
  /// default project package.
  Future<ExportRequest> options({
    Set<ExportFormat> formats = const <ExportFormat>{
      ExportFormat.xlsx,
      ExportFormat.zip,
    },
  }) async {
    return _ok(await repo.options(project.id)).copyWith(formats: formats);
  }

  /// Every file under the project's export folder, relative to it.
  List<String> exportedFiles() {
    final Directory exports = Directory(
      '${root.path}/projects/${project.folderName}/exports',
    );
    if (!exports.existsSync()) {
      return const <String>[];
    }
    return <String>[
      for (final FileSystemEntity entity in exports.listSync(recursive: true))
        if (entity is File)
          entity.path
              .replaceAll(r'\', '/')
              .substring(exports.path.replaceAll(r'\', '/').length + 1),
    ];
  }

  /// A JPEG filed on an approved record [recordId]. The returned bytes are
  /// what was written, so a later read can show the original was left alone.
  List<int> seedPhotoRecord(String recordId) {
    final String path = photoPath(recordId);
    final Uint8List bytes = img.encodeJpg(img.Image(width: 8, height: 6));
    writeFile(path, bytes);
    records.seedEntry(
      aRecordEntry(id: recordId, status: RecordStatus.approved).copyWith(
        photos: <RecordPhoto>[
          RecordPhoto(
            id: 'ph-$recordId',
            sha256: 'sha-$recordId',
            storagePath: path,
            photoType: 'front',
          ),
        ],
      ),
    );
    return bytes;
  }

  /// Where [seedPhotoRecord] stores the photo, relative to the storage root.
  String photoPath(String recordId) =>
      'projects/${project.folderName}/photos/$recordId/front.jpg';

  /// Saves `template-1` with an action register of [requiredness], so a
  /// meeting export can be blocked when an action has no owner.
  Future<void> seedMeetingTemplate(Requiredness requiredness) async {
    _ok(
      await templates.save(
        aTemplate(
          fields: <FieldDef>[
            FieldDef(
              fieldKey: 'action_items',
              label: 'Actions',
              type: FieldType.text,
              requiredness: requiredness,
            ),
          ],
        ),
      ),
    );
  }

  /// Files a site meeting on approved record [recordId], with [actions].
  Future<void> saveMeeting(String recordId, List<ActionEntry> actions) async {
    records.seedEntry(
      aRecordEntry(
        id: recordId,
        projectId: project.id,
        status: RecordStatus.approved,
      ),
    );
    final DateTime at = DateTime.utc(2026, 9, 24, 9);
    final MeetingRepositoryImpl meetings = MeetingRepositoryImpl(
      db: db,
      clock: FixedClock(at),
      deviceId: 'device-test',
      ids: UuidV7Service.sequence(FixedClock(at)),
    );
    _ok(
      await meetings.save(
        Meeting(
          id: 'meeting-$recordId',
          projectId: project.id,
          title: 'Site meeting',
          startedAt: at,
          attendees: const <Attendee>[
            Attendee(id: 'person-1', name: 'Ada Lovelace'),
            Attendee(
              id: 'person-2',
              name: 'Grace Hopper',
              status: AttendanceStatus.apology,
            ),
          ],
          decisions: const <Decision>[
            Decision(id: 'd1', text: 'Paint the gate'),
          ],
          actions: actions,
        ),
        recordId: recordId,
        notes: 'We agreed to paint the gate.',
        minutes: 'The gate will be painted.',
      ),
    );
  }

  /// Seeds transcript [id] owned as [ownerKind] (and [ownerId]) with one
  /// raw segment per entry of [lines] and the operator's [edited] text. A
  /// [attachedTo] record has the transcript's audio filed on it.
  Future<void> seedTranscript(
    String id, {
    required String ownerKind,
    required List<String> lines,
    String? ownerId,
    String? attachedTo,
    String title = '',
    String status = 'complete',
    String? edited,
  }) async {
    final String? audio = attachedTo == null ? null : 'audio-$id';
    if (audio != null) {
      await seedRow(db, 'attachments', <String, Object?>{
        'id': audio,
        'project_id': project.id,
        'relative_path': 'audio/$id.wav',
        'mime_type': 'audio/wav',
        'file_size': 4,
        'sha256': 'hash-$id',
        'kind': 'audio',
      });
      await seedRow(db, 'attachment_owners', <String, Object?>{
        'id': 'owner-$id',
        'attachment_id': audio,
        'owner_type': 'record',
        'owner_id': attachedTo,
      });
    }
    await seedRow(db, 'transcripts', <String, Object?>{
      'id': id,
      'project_id': project.id,
      'owner_kind': ownerKind,
      'owner_id': ownerId,
      'attachment_id': audio,
      'audio_path': 'projects/${project.folderName}/audio/$id.wav',
      'title': title,
      'language_tag': 'en',
      'model_id': 'tiny-q5_1',
      'status': status,
      'started_at': 1,
      'text_edited': edited,
      'edited_at': edited == null ? null : 2,
    });
    for (int index = 0; index < lines.length; index++) {
      await seedRow(db, 'transcript_segments', <String, Object?>{
        'id': '$id-${index + 1}',
        'transcript_id': id,
        'seq': index + 1,
        'start_ms': index * 1000,
        'end_ms': index * 1000 + 900,
        'text_raw': lines[index],
      });
    }
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
        if (entry.isFile) entry.name: entry.content,
    };
  }
}

/// Every XML part of the workbook [bytes], joined.
String _xml(List<int> bytes) {
  final Archive archive = ZipDecoder().decodeBytes(bytes);
  final StringBuffer buffer = StringBuffer();
  for (final ArchiveFile file in archive.files) {
    if (file.name.endsWith('.xml')) {
      buffer.write(utf8.decode(file.content));
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

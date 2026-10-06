import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/export/export_output_template.dart';
import 'package:tapture/core/files/blob_file_writer.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/core/files/project_folders.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/exports/data/export_record_loader.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../core/export/template_output_fixture.dart';
import '../../../support/factories.dart';
import '../../../support/fakes/fake_record_repository.dart';

void main() {
  late sqlite.AppDatabase db;
  late TemplateRepositoryImpl templates;
  setUp(() {
    db = sqlite.AppDatabase.memory();
    final FixedClock clock = FixedClock(DateTime.utc(2026));
    templates = TemplateRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device',
      ids: UuidV7Service.sequence(clock),
    );
  });
  tearDown(() => db.close());

  test(
    'durable captured source hash and database row identity survive edits and reach output',
    () async {
      final TemplateDef first = (await templates.save(
        aTemplate(
          id: '',
          projectId: 'project',
          fields: const <FieldDef>[
            FieldDef(
              fieldKey: 'serial',
              label: 'Serial',
              type: FieldType.text,
              outputColumn: 'B',
            ),
          ],
          rows: const <TemplateRow>[
            TemplateRow(
              identifier: 'asset',
              label: 'Asset',
              outputRowNumber: 7,
            ),
          ],
        ).copyWith(
          source: 'imported',
          sourceFilePath: 'templates/first.xlsx',
          sheetName: 'Register',
          headerRow: 3,
          detection: const <String, Object?>{'sourceSha256': 'first-hash'},
        ),
      )).getOrThrow();
      expect(first.rows.single.id, isNotEmpty);
      final FakeRecordRepository records = FakeRecordRepository();
      addTearDown(records.dispose);
      records.seedEntry(
        aRecordEntry(
          projectId: 'project',
          templateId: first.id,
          status: RecordStatus.approved,
        ).copyWith(
          templateRowId: first.rows.single.id,
          templateVersion: first.version,
        ),
      );
      final TemplateDef second = (await templates.save(
        first.copyWith(
          sourceFilePath: 'templates/second.xlsx',
          fields: <FieldDef>[first.fields.single.copyWith(outputColumn: 'E')],
          rows: <TemplateRow>[first.rows.single.copyWith(outputRowNumber: 12)],
          detection: const <String, Object?>{'sourceSha256': 'second-hash'},
        ),
      )).getOrThrow();
      expect(second.version, 2);
      final prepared =
          (await ExportRecordLoader(
                records: records,
                templates: templates,
              ).load(
                TemplateOutputFixture.request(),
                cancel: CancellationToken(),
              ))
              .getOrThrow();
      final ExportOutputTemplate snapshot =
          prepared.request.outputTemplates.single;
      expect(snapshot.sourcePath, 'templates/first.xlsx');
      expect(snapshot.sourceHash, 'first-hash');
      expect(snapshot.columns, <String, String>{'serial': 'B'});
      expect(snapshot.rows, <String, int>{first.rows.single.id: 7});
      expect(
        prepared.request.records.single.templateRowId,
        first.rows.single.id,
      );
      expect(prepared.request.records.single.approved, isTrue);
    },
  );

  test(
    'Word and text imports preserve source bytes and hash in the existing atomic file store',
    () async {
      final Directory directory = Directory.systemTemp.createTempSync(
        'tapture-output-template-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final StorageRoot storage = StorageRoot.fake(
        documentsDirectory: directory,
      );
      final BlobStore store = BlobStore.memory();
      final XlsxTemplateImport importer = XlsxTemplateImport(
        storageRoot: storage,
        folders: ProjectFolders(storageRoot: storage),
        writer: BlobFileWriter(store),
        templates: templates,
      );
      for (final String kind in <String>['docx', 'txt']) {
        final Uint8List source = kind == 'docx'
            ? File(
                'test/fixtures/export_templates/client.docx',
              ).readAsBytesSync()
            : Uint8List.fromList('{{serial}}\r\n'.codeUnits);
        final PickedBytes document = PickedBytes(source, 'client.$kind');
        final TemplateDef draft = (await TemplateDocumentImport.output(
          document,
          projectId: 'project',
        )).getOrThrow();
        final TemplateDef saved = (await importer.applyDocument(
          projectId: 'project',
          projectName: 'Project',
          folderName: 'project',
          document: document,
          draft: draft,
        )).getOrThrow();
        expect(saved.sourceFilePath, endsWith('.$kind'));
        expect(
          saved.detection['sourceSha256'],
          sha256.convert(source).toString(),
        );
        expect((await store.read(saved.sourceFilePath!)).getOrThrow(), source);
        expect(saved.fields.map((field) => field.fieldKey), contains('serial'));
      }
    },
  );
}

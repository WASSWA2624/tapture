import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/exports/data/export_repository_impl.dart';
import 'package:tapture/features/exports/domain/export_repository.dart';
import 'package:tapture/features/records/domain/record_entry.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';

import '../test/support/matchers.dart';
import '../test/support/processing_fixture.dart';
import 'support/harness.dart';

void main() {
  test(
    'offline project export writes one readable ZIP with workbook and raw evidence',
    () async {
      final ProcessingFixture fixture = await ProcessingFixture.open();
      final photo = await fixture.db.select(fixture.db.photos).getSingle();
      final File raw = File('${fixture.projectFolder}/${photo.relativePath}');
      final Uint8List before = await raw.readAsBytes();
      final ExportRepository repository = ExportRepositoryImpl(
        db: fixture.db,
        storageRoot: fixture.storageRoot,
        clock: fixture.clock,
        deviceId: 'device-a',
        ids: fixture.ids,
        templates: TemplateRepositoryImpl(
          db: fixture.db,
          clock: fixture.clock,
          deviceId: 'device-a',
          ids: fixture.ids,
        ),
      );
      final ExportedPackage exported = valueOf(
        await repository.exportProject(
          fixture.project.id,
          cancel: CancellationToken(),
        ),
      );
      final StoredBundle package = exported.package as StoredBundle;
      final File zip = File(
        '${fixture.documents.path}/Tapture/${package.relativePath}',
      );
      final InspectedBundle inspected = valueOf(
        await BundleReader.inspect(
          PickedFile(zip, exported.fileName, await zip.length()),
        ),
      );
      addTearDown(inspected.close);
      expect(
        await inspected.readEntry(BundleFormat.workbook),
        isA<Success<Uint8List>>(),
      );
      expect(inspected.rowsOf('records'), hasLength(1));
      expect(inspected.rowsOf('photos'), hasLength(1));
      final String archivePhoto =
          inspected.rowsOf('photos').single['relative_path']! as String;
      expect(valueOf(await inspected.readEntry(archivePhoto)), before);
      expect(await raw.readAsBytes(), before);
      final List<File> archives = Directory('${fixture.projectFolder}/exports')
          .listSync(recursive: true)
          .whereType<File>()
          .where((File file) => file.path.endsWith('.zip'))
          .toList();
      expect(archives, hasLength(1));
      expect(await fixture.db.select(fixture.db.exports).get(), hasLength(1));
    },
  );

  test(
    'capture through approval exports the approved values from the database',
    () async {
      final TestApp app = await bootTestApp();
      addTearDown(app.dispose);
      final RecordEntry captured = await app.capture(
        fields: const <String, String>{'serial': 'M-1'},
      );
      final RecordEntry approved = await app.approve(captured.id);
      expect(approved.status, RecordStatus.approved);
      final RecordEntry? rebuilt = valueOf(await app.records.byId(approved.id));
      expect(rebuilt?.valueOf('serial')?.display, 'M-1');
      final String csv = app.csvFor(<ExportRecord>[app.rowOf(approved)]);
      expect(csv.contains('M-1'), isTrue);
      expect(app.outboundCallCount, 0);
    },
  );
}

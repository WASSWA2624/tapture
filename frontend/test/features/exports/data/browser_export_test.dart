import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/device/device_identity.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_file_reader.dart';
import 'package:tapture/core/files/blob_file_writer.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/files/evidence_purge.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/features/exports/data/export_repository_impl.dart';
import 'package:tapture/features/exports/domain/export_repository.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';

import '../../../support/processing_fixture.dart';

void main() {
  test(
    'browser package contains saved photos and downloads the same durable archive',
    () async {
      final ProcessingFixture fixture = await ProcessingFixture.open();
      final photo = await fixture.db.select(fixture.db.photos).getSingle();
      final Map<String, Uint8List> backing = <String, Uint8List>{};
      final BlobStore store = BlobStore.memory(backing: backing);
      final BlobFileReader files = BlobFileReader(store);
      final BlobFileWriter writer = BlobFileWriter(store);
      final Uint8List pixels = Uint8List.fromList(<int>[1, 2, 3, 4]);
      await writer.write(
        Stream<List<int>>.value(pixels),
        'projects/${fixture.project.folderName}/${photo.relativePath}',
      );
      final ExportRepositoryImpl repository = ExportRepositoryImpl(
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
        files: files,
        writer: writer,
        cleanup: EvidencePurge.store(store),
        bundles: BundleWriter(
          db: fixture.db,
          storageRoot: fixture.storageRoot,
          files: files,
          clock: fixture.clock,
          ids: fixture.ids,
          deviceId: 'device-a',
          device: () async => const DeviceDescriptor.fake(),
          inBrowser: true,
        ),
      );
      final Result<ExportedPackage> result = await repository.exportProject(
        fixture.project.id,
        cancel: CancellationToken(),
      );
      final ExportedPackage exported =
          (result as Success<ExportedPackage>).value;
      final InMemoryBundle output = exported.package as InMemoryBundle;
      final InspectedBundle inspected =
          (await BundleReader.inspect(
                    PickedBytes(output.bytes, exported.fileName),
                  )
                  as Success<InspectedBundle>)
              .value;
      addTearDown(inspected.close);
      expect(
        (await inspected.readEntry(photo.relativePath) as Success<Uint8List>)
            .value,
        pixels,
      );
      expect(
        await inspected.readEntry(BundleFormat.workbook),
        isA<Success<Uint8List>>(),
      );
      final saved = await fixture.db.select(fixture.db.exports).getSingle();
      expect(
        (await files.read(saved.filePath) as Success<Uint8List>).value,
        output.bytes,
      );
      Uint8List? downloaded;
      final DownloadService downloads = DownloadService.fake(
        onSave: (_, Uint8List bytes, _) => downloaded = bytes,
      );
      await downloads.save(
        fileName: exported.fileName,
        bytes: output.bytes,
        mimeType: BundleFormat.mimeType,
      );
      expect(downloaded, output.bytes);
    },
  );
}

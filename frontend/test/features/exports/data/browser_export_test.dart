import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/document_assets.dart';
import 'package:tapture/core/device/device_identity.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_file_reader.dart';
import 'package:tapture/core/files/blob_file_writer.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/files/evidence_purge.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/exports/data/export_repository_impl.dart';
import 'package:tapture/features/exports/domain/export_repository.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';

import '../../../support/factories.dart';
import '../../../support/screen_database.dart';
import '../../../support/screen_font_fetch_stub.dart'
    if (dart.library.js_interop) '../../../support/screen_font_fetch_web.dart'
    show fetchScreenFont;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'browser package contains saved photos and downloads the same durable archive',
    () async {
      if (kIsWeb) _serveCanonicalPatternAsset();
      final db = await seededDatabase(
        records: 1,
        database: createScreenDatabase(),
      );
      addTearDown(db.close);
      final project = await db.select(db.projects).getSingle();
      final photo = await db.select(db.photos).getSingle();
      final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 26, 8));
      final UuidV7Service ids = UuidV7Service.sequence(clock);
      int nativeRootResolutions = 0;
      final StorageRoot storageRoot = StorageRoot(
        documentsDirectory: () async {
          nativeRootResolutions++;
          throw TestFailure('Browser exports must not resolve native files');
        },
        publicDocuments: () async => null,
      );
      final Map<String, Uint8List> backing = <String, Uint8List>{};
      final BlobStore store = BlobStore.memory(backing: backing);
      final BlobFileReader files = BlobFileReader(store);
      final BlobFileWriter writer = BlobFileWriter(store);
      final Uint8List pixels = img.encodePng(img.Image(width: 4, height: 4));
      await writer.write(
        Stream<List<int>>.value(pixels),
        'projects/${project.folderName}/${photo.relativePath}',
      );
      final ExportRepositoryImpl repository = ExportRepositoryImpl(
        db: db,
        storageRoot: storageRoot,
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
        templates: TemplateRepositoryImpl(
          db: db,
          clock: clock,
          deviceId: 'device-a',
          ids: ids,
        ),
        files: files,
        writer: writer,
        cleanup: EvidencePurge.store(store),
        bundles: BundleWriter(
          db: db,
          storageRoot: storageRoot,
          files: files,
          clock: clock,
          ids: ids,
          deviceId: 'device-a',
          device: () async => const DeviceDescriptor.fake(),
          inBrowser: true,
        ),
      );
      final Result<ExportedPackage> result = await repository.exportProject(
        project.id,
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
      final String protectedPath =
          inspected.rowsOf('photos').single['relative_path']! as String;
      final Uint8List protected =
          (await inspected.readEntry(protectedPath) as Success<Uint8List>)
              .value;
      expect(img.decodeImage(protected)!.width, 4);
      expect(
        (await files.read(
                  'projects/${project.folderName}/${photo.relativePath}',
                )
                as Success<Uint8List>)
            .value,
        pixels,
      );
      expect(
        await inspected.readEntry(BundleFormat.workbook),
        isA<Success<Uint8List>>(),
      );
      final saved = await db.select(db.exports).getSingle();
      expect(
        (await files.read(saved.filePath) as Success<Uint8List>).value,
        output.bytes,
      );
      Uint8List? downloaded;
      int publicDownloads = 0;
      final DownloadService downloads = DownloadService.fake(
        onSave: (_, Uint8List bytes, _) {
          publicDownloads++;
          downloaded = bytes;
        },
      );
      await downloads.save(
        fileName: exported.fileName,
        bytes: output.bytes,
        mimeType: BundleFormat.mimeType,
      );
      expect(downloaded, output.bytes);
      expect(publicDownloads, 1);
      expect((await db.select(db.exports).get()), hasLength(1));
      expect(nativeRootResolutions, 0);
    },
  );
}

void _serveCanonicalPatternAsset() {
  final TestDefaultBinaryMessenger messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  expect(messenger.checkMockMessageHandler('flutter/assets', null), isTrue);
  rootBundle.evict(DocumentAssets.secretPatterns);
  messenger.setMockMessageHandler('flutter/assets', (ByteData? message) async {
    if (message == null) throw TestFailure('The pattern asset key is missing.');
    final String key = utf8.decode(
      message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes),
    );
    if (key != DocumentAssets.secretPatterns) {
      throw TestFailure('Unexpected browser export asset: $key');
    }
    // The web test engine ignores platform messages. Serve the actual canonical
    // bytes staged by the browser runner so the production scanner still runs.
    return fetchScreenFont(Uri.base.resolve('/task144-secret-patterns.yaml'));
  });
  addTearDown(() {
    messenger.setMockMessageHandler('flutter/assets', null);
    rootBundle.evict(DocumentAssets.secretPatterns);
  });
}

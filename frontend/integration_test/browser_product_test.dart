@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/ai/ocr_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/device/device_identity.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_file_reader.dart';
import 'package:tapture/core/files/blob_file_writer.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/files/evidence_purge.dart';
import 'package:tapture/core/files/photo_thumbnails.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_photo_thumb.dart';
import 'package:tapture/core/widgets/record_thumb.dart';
import 'package:tapture/features/exports/data/export_repository_impl.dart';
import 'package:tapture/features/exports/domain/export_repository.dart';
import 'package:tapture/features/processing/data/processing_repository_impl.dart';
import 'package:tapture/features/processing/data/processing_stage_worker.dart';
import 'package:tapture/features/processing/domain/processing_repository.dart';
import 'package:tapture/features/processing/presentation/processing_batch_state.dart';
import 'package:tapture/features/processing/presentation/processing_controller.dart';
import 'package:tapture/features/processing/presentation/queue_providers.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';

import '../test/support/factories.dart';
import '../test/support/pump_external_work.dart';

/// Executes production browser services against actual wasm SQLite/IndexedDB.
/// Its network-free provider setting deliberately preserves manual evidence.
void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tearDownAll(() {
    binding.reportData = <String, Object?>{'results': binding.results};
  });

  testWidgets(
    'browser processing completes and preserves IndexedDB originals',
    (WidgetTester tester) async {
      await tester.runAsync(() async {
        final _BrowserProduct fixture = await _BrowserProduct.open();
        try {
          final SettingsStore settings = SettingsStore.fake(
            stored: <String, Object?>{SettingKeys.offlineByChoice.name: true},
          );
          final ProcessingRepository repository = ProcessingRepositoryImpl(
            db: fixture.db,
            clock: fixture.clock,
            deviceId: 'browser-audit',
            ids: fixture.ids,
            settings: settings,
          );
          final ProcessingStageWorker worker = ProcessingStageWorker(
            db: fixture.db,
            clock: fixture.clock,
            deviceId: 'browser-audit',
            ids: fixture.ids,
            storageRoot: fixture.root,
            files: fixture.files,
            writer: fixture.writer,
            ocr: OcrService(),
            providers: ProviderRegistry.keyless(),
            settings: settings,
          );
          final ProviderContainer container = ProviderContainer(
            overrides: <Override>[
              processingRepositoryProvider.overrideWithValue(repository),
              processingStageWorkProvider.overrideWithValue(worker.perform),
              processingEgressSummaryProvider.overrideWithValue(
                worker.egressSummary,
              ),
            ],
          );
          try {
            final String id = (await repository.enqueue(
              fixture.record.id,
            )).getOrThrow();
            final ProviderSubscription<ProcessingBatchState> subscription =
                container.listen(processingControllerProvider, (_, _) {});
            try {
              await container
                  .read(processingControllerProvider.notifier)
                  .process(confirmOnline: (ProcessingJob _) async => true);
              final ProcessingBatchState result = container.read(
                processingControllerProvider,
              );
              expect((result.succeeded, result.failed), (1, 0));
              expect(
                (await repository.byId(id)).getOrThrow()?.status,
                JobStatus.completed,
              );
              expect(
                (await fixture.files.read(fixture.photoPath)).getOrThrow(),
                fixture.original,
              );
              final Uint8List thumb = (await fixture.thumbnails.bytesFor(
                sha256: fixture.photo.sha256,
                storagePath: fixture.photoPath,
                edge: AppConstants.images.thumbnailEdge,
              )).getOrThrow();
              expect(
                img.decodeJpg(thumb)!.width,
                lessThanOrEqualTo(AppConstants.images.thumbnailEdge),
              );
            } finally {
              subscription.close();
            }
          } finally {
            container.dispose();
          }
        } finally {
          await fixture.close();
        }
      });
    },
  );

  testWidgets(
    'browser exports stored photos through the production download service',
    (WidgetTester tester) async {
      await tester.runAsync(() async {
        final _BrowserProduct fixture = await _BrowserProduct.open();
        try {
          final ExportRepositoryImpl repository = ExportRepositoryImpl(
            db: fixture.db,
            storageRoot: fixture.root,
            clock: fixture.clock,
            deviceId: 'browser-audit',
            ids: fixture.ids,
            templates: TemplateRepositoryImpl(
              db: fixture.db,
              clock: fixture.clock,
              deviceId: 'browser-audit',
              ids: fixture.ids,
            ),
            files: fixture.files,
            writer: fixture.writer,
            cleanup: EvidencePurge.store(fixture.store),
            bundles: BundleWriter(
              db: fixture.db,
              storageRoot: fixture.root,
              files: fixture.files,
              clock: fixture.clock,
              ids: fixture.ids,
              deviceId: 'browser-audit',
              device: () async => const DeviceDescriptor.fake(),
              inBrowser: true,
            ),
          );
          final ExportedPackage exported = (await repository.exportProject(
            fixture.project.id,
            cancel: CancellationToken(),
          )).getOrThrow();
          final InMemoryBundle output = exported.package as InMemoryBundle;
          final InspectedBundle inspected = (await BundleReader.inspect(
            PickedBytes(output.bytes, exported.fileName),
          )).getOrThrow();
          try {
            final String path =
                inspected.rowsOf('photos').single['relative_path']! as String;
            final img.Image protected = img.decodeImage(
              (await inspected.readEntry(path)).getOrThrow(),
            )!;
            expect((protected.width, protected.height), (512, 256));
            expect(
              (await fixture.files.read(fixture.photoPath)).getOrThrow(),
              fixture.original,
            );
            final ExportRow saved = await fixture.db
                .select(fixture.db.exports)
                .getSingle();
            expect(
              (await fixture.files.read(saved.filePath)).getOrThrow(),
              output.bytes,
            );
            expect(
              await DownloadService().save(
                fileName: exported.fileName,
                bytes: output.bytes,
                mimeType: BundleFormat.mimeType,
              ),
              isA<Success<String?>>(),
            );
          } finally {
            await inspected.close();
          }
        } finally {
          await fixture.close();
        }
      });
    },
  );

  testWidgets(
    'the shared record and project thumbnail draws bounded IndexedDB bytes',
    (WidgetTester tester) async {
      late _BrowserProduct fixture;
      await tester.runAsync(() async => fixture = await _BrowserProduct.open());
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              photoThumbnailsProvider.overrideWithValue(fixture.thumbnails),
            ],
            child: MaterialApp(
              theme: buildTheme(brightness: Brightness.light),
              home: Scaffold(
                body: RecordThumb(
                  sha256: fixture.photo.sha256,
                  storagePath: fixture.photoPath,
                ),
              ),
            ),
          ),
        );
        await pumpExternalWork(
          tester,
          () =>
              tester
                  .widget<AppPhotoThumb>(find.byType(AppPhotoThumb))
                  .photo
                  .thumbBytes !=
              null,
        );
        final AppPhotoThumb drawn = tester.widget(find.byType(AppPhotoThumb));
        expect(drawn.photo.thumbBytes, isNotNull);
        final img.Image decoded = img.decodeJpg(drawn.photo.thumbBytes!)!;
        expect(
          decoded.width,
          lessThanOrEqualTo(AppConstants.images.thumbnailEdge),
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(fixture.close);
      }
    },
  );
}

final class _BrowserProduct {
  _BrowserProduct(
    this.db,
    this.store,
    this.clock,
    this.ids,
    this.project,
    this.record,
    this.photo,
    this.original,
  );

  final AppDatabase db;
  final BlobStore store;
  final FixedClock clock;
  final UuidV7Service ids;
  final Project project;
  final RecordRow record;
  final Photo photo;
  final Uint8List original;
  final StorageRoot root = StorageRoot();
  late final BlobFileReader files = BlobFileReader(store);
  late final BlobFileWriter writer = BlobFileWriter(store);
  late final PhotoThumbnails thumbnails = PhotoThumbnails(
    storageRoot: root,
    files: files,
    writer: writer,
  );
  String get photoPath =>
      'projects/${project.folderName}/${photo.relativePath}';

  static Future<_BrowserProduct> open() async {
    final AppDatabase db = await seededDatabase(records: 1);
    final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 1));
    final _BrowserProduct fixture = _BrowserProduct(
      db,
      BlobStore.platform(
        'product-audit-${DateTime.now().microsecondsSinceEpoch}',
      ),
      clock,
      UuidV7Service.sequence(clock),
      await db.select(db.projects).getSingle(),
      await db.select(db.records).getSingle(),
      await db.select(db.photos).getSingle(),
      img.encodeJpg(img.Image(width: 512, height: 256)),
    );
    (await fixture.writer.write(
      Stream<List<int>>.value(fixture.original),
      fixture.photoPath,
    )).getOrThrow();
    return fixture;
  }

  Future<void> close() async {
    // The dedicated per-test store cannot reach an operator's project files.
    await store.remove(photoPath);
    await store.remove(
      '.cache/thumbs/${photo.sha256}_${AppConstants.images.thumbnailEdge}',
    );
    for (final ExportRow row in await db.select(db.exports).get()) {
      await store.remove(row.filePath);
    }
    await db.close();
  }
}

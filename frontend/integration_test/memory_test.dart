@Tags(<String>['performance'])
@Timeout(Duration(minutes: 10))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/device/device_identity.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/text_export_writer.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/merge/data/package_files.dart';
import 'package:tapture/features/merge/data/package_import_repository_impl.dart';
import 'package:tapture/features/merge/domain/domain.dart';
import 'package:tapture/features/quality/quality.dart' show PossibleDuplicate;

import '../test/support/bundle_fixture.dart';
import '../test/support/factories.dart';
import '../test/support/matchers.dart';
import '../tool/profile_memory.dart';
import 'support/capture_rig.dart';
import 'support/harness.dart';

const int _mib = 1024 * 1024;

void main() {
  final List<MemoryProfile> profiles = <MemoryProfile>[];
  int databases = 0;
  int subscriptions = 0;
  int bundles = 0;
  int containers = 0;
  Map<String, int> resources() => <String, int>{
    'databases': databases,
    'subscriptions': subscriptions,
    'bundles': bundles,
    'containers': containers,
    'isolates': debugLiveIsolates,
  };
  tearDownAll(() async {
    final File report = File('build/memory-profile.json');
    await report.parent.create(recursive: true);
    await report.writeAsString(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(profiles.map(memoryProfileJson).toList()),
    );
  });

  Future<void> measure(
    String scenario,
    Future<void> Function() operation,
  ) async {
    final MemoryProfile profile = await profileMemory(
      scenario: scenario,
      operation: operation,
      resources: resources,
    );
    profiles.add(profile);
    expect(profile.samples, greaterThan(1));
    expect(profile.settled, isNotEmpty);
    expect(profile.resourcesAfter, profile.resourcesBefore);
    expect(profile.peak - profile.baseline, lessThanOrEqualTo(128 * _mib));
    // Record retained RSS faithfully. Device-specific baseline tolerance is
    // evaluated by profile_memory.dart, not assumed after close or forced GC.
  }

  test(
    'capture two hundred real JPEG records, close session resources, sample RSS',
    () async {
      await measure('capture-200', () async {
        final TestApp app = await bootTestApp();
        databases++;
        CaptureRig? capture;
        final Completer<void> first = Completer<void>();
        final StreamSubscription<List<RecordRow>> watch = app.db
            .select(app.db.records)
            .watch()
            .listen((_) {
              if (!first.isCompleted) first.complete();
            });
        subscriptions++;
        try {
          await first.future;
          capture = await CaptureRig.open(app, registerTearDown: false);
          containers++;
          valueOf(await capture.controller.setTemplate(CaptureRig.templateId));
          final img.Image image = img.Image(width: 32, height: 32);
          img.fill(image, color: img.ColorRgb8(220, 200, 40));
          final Uint8List bytes = Uint8List.fromList(
            img.encodeJpg(image),
          ).asUnmodifiableView();
          final Map<String, Uint8List> originals = <String, Uint8List>{};
          for (int record = 0; record < 200; record++) {
            final Uint8List original = _captureJpeg(bytes, record);
            final photo = await capture.shoot(bytes: original);
            originals[photo.id] = original;
            valueOf(await capture.controller.setCaption(null, 'RSS-$record'));
            valueOf(
              await capture.controller.saveRaw(
                capture.container.read(captureRecordWriterProvider)!.persist,
              ),
            );
          }
          expect(await app.db.select(app.db.records).get(), hasLength(200));
          final List<Photo> photos = await app.db.select(app.db.photos).get();
          expect(photos, hasLength(200));
          expect(
            photos.map((Photo photo) => photo.relativePath).toSet(),
            hasLength(200),
          );
          for (final Photo photo in photos) {
            expect(
              await capture.file(photo.relativePath).readAsBytes(),
              originals[photo.id],
            );
          }
          expect(capture.session.photos, isEmpty);
          expect(app.outboundCallCount, 0);
        } finally {
          await watch.cancel();
          subscriptions--;
          if (capture != null) {
            await capture.dispose();
            containers--;
          }
          await app.dispose();
          databases--;
        }
      });
    },
  );

  test(
    'export five thousand stored records to real CSV and JSON files, sample RSS',
    () async {
      await measure('export-5000', () async {
        final AppDatabase db = await seededDatabase(records: 5000);
        databases++;
        final Directory documents = await Directory.systemTemp.createTemp(
          'tapture-memory-export-',
        );
        try {
          final List<RecordRow> stored = await db.select(db.records).get();
          final ExportRequest request = ExportRequest(
            projectId: stored.first.projectId,
            formats: const <ExportFormat>{ExportFormat.csv, ExportFormat.json},
            scope: (
              kind: ExportScopeKind.all,
              context: null,
              from: null,
              to: null,
              filter: null,
            ),
            columns: (
              raw: true,
              refined: true,
              confidence: false,
              evidence: false,
            ),
            extras: (
              dictionary: false,
              photoIndex: false,
              photoMode: 'filename',
              pdfPhotos: 'thumbnail',
              delimiter: ',',
            ),
            records: <ExportRecord>[
              for (final RecordRow row in stored)
                ExportRecord(
                  id: row.id,
                  number: '${row.recordNumber ?? 0}',
                  templateId: row.templateId,
                  templateName: 'Seeded equipment',
                  status: row.status,
                  values: const <ExportValue>[],
                ),
            ],
          );
          final StorageRoot root = StorageRoot.fake(
            documentsDirectory: documents,
          );
          final Map<String, WrittenFile> outputs = valueOf(
            await TextExportWriter(root).write(
              request,
              'projects/p/exports/memory',
              cancel: CancellationToken(),
            ),
          );
          final Directory base = valueOf(await root.resolve());
          final Object? decoded = jsonDecode(
            await File(
              '${base.path}/${outputs['records.json']!.relativePath}',
            ).readAsString(),
          );
          expect(decoded, isA<Map<String, Object?>>());
          expect(
            (decoded! as Map<String, Object?>)['records'],
            hasLength(5000),
          );
          final File csv = File(
            '${base.path}/${outputs.entries.firstWhere((MapEntry<String, WrittenFile> entry) => entry.key.endsWith('.csv')).value.relativePath}',
          );
          expect(await csv.length(), greaterThan(5000));
        } finally {
          await db.close();
          databases--;
          await documents.delete(recursive: true);
        }
      });
    },
  );

  test(
    'merge two thousand real JPEG files through package inspection and apply, sample RSS',
    () async {
      await measure('merge-2000-photos', () async {
        final BundleFixture source = await seedProjectForBundle(records: 2000);
        databases++;
        // The general package fixture exercises a deleted final record. This
        // scenario instead measures 2,000 live photos; deletion has its own
        // package/merge regressions and must retain its production behavior.
        await (source.db.delete(
          source.db.tombstones,
        )..where(($TombstonesTable row) => row.id.equals('tomb-1'))).go();
        final AppDatabase target = AppDatabase.memory();
        databases++;
        final Directory documents = await Directory.systemTemp.createTemp(
          'tapture-memory-merge-',
        );
        final FixedClock clock = FixedClock(DateTime.utc(2026, 10));
        final StorageRoot root = StorageRoot.fake(
          documentsDirectory: documents,
        );
        InspectedBundle? inspected;
        try {
          final StoredBundle written =
              valueOf(
                    await BundleWriter(
                      db: source.db,
                      storageRoot: source.storageRoot,
                      files: FileReader(storageRoot: source.storageRoot),
                      clock: clock,
                      ids: UuidV7Service.sequence(clock),
                      deviceId: 'source-device',
                      device: () async => const DeviceDescriptor.fake(),
                    ).write(
                      projectId: source.projectId,
                      cancel: CancellationToken(),
                    ),
                  )
                  as StoredBundle;
          final InspectedBundle bundle = valueOf(
            await BundleReader.inspect(
              PickedFile(
                File('${source.root.path}/${written.relativePath}'),
                'memory.zip',
                written.byteLength,
              ),
            ),
          );
          inspected = bundle;
          bundles++;
          expect(bundle.rowsOf('photos'), hasLength(2000));
          for (final String table in <String>[
            'projects',
            'templates',
            'template_fields',
          ]) {
            for (final Map<String, Object?> row in bundle.rowsOf(table)) {
              await insertRow(target, table, row);
            }
          }
          final PackageImportRepositoryImpl repository =
              PackageImportRepositoryImpl(
                db: target,
                files: PackageFiles(storageRoot: root),
                clock: clock,
                deviceId: 'target-device',
                ids: UuidV7Service.sequence(clock),
              );
          final MergeGround ground = valueOf(
            await repository.groundFor(
              projectId: source.projectId,
              incoming: bundle.tables,
            ),
          );
          final CompatibilityReport compatible = TemplateCompatibility.check(
            incoming: bundle.tables,
            local: ground.local,
            sameProject: true,
          );
          expect(compatible.canMerge, isTrue);
          final MergePlan plan = MergePlanner.plan(
            incoming: bundle.tables,
            local: ground.local,
            templateMapping: compatible.mapping,
            targetProjectId: source.projectId,
            incomingProjectId: source.projectId,
            elsewhere: ground.elsewhere,
            decided: ground.decided,
          );
          expect(plan.conflicts, isEmpty);
          valueOf(
            await repository.merge(
              bundle: bundle,
              projectId: source.projectId,
              plan: plan,
              choices: const <String, ConflictChoice>{},
              duplicates: const <PossibleDuplicate>[],
              skipped: const <String>{},
              chooser: 'Memory audit',
            ),
          );
          final List<Photo> photos = await target.select(target.photos).get();
          expect(photos, hasLength(2000));
          final Directory base = valueOf(await root.resolve());
          for (final Photo photo in <Photo>[photos.first, photos.last]) {
            final File file = File(
              '${base.path}/projects/${source.folderName}/${photo.relativePath}',
            );
            expect(await file.readAsBytes(), source.files[photo.relativePath]);
          }
        } finally {
          if (inspected != null) {
            await inspected.close();
            bundles--;
          }
          await target.close();
          databases--;
          await source.db.close();
          databases--;
          await source.root.parent.delete(recursive: true);
          await documents.delete(recursive: true);
        }
      });
    },
  );
}

/// A JPEG COM segment makes each capture distinct without mutating the shared
/// encoded pixels. The real photo store deliberately refuses identical hashes.
Uint8List _captureJpeg(Uint8List pixels, int record) {
  final List<int> identity = utf8.encode('memory-capture-$record');
  final int length = identity.length + 2;
  return Uint8List.fromList(<int>[
    ...pixels.take(2), // SOI
    0xff, 0xfe, // COM
    length >> 8, length & 0xff,
    ...identity,
    ...pixels.skip(2),
  ]).asUnmodifiableView();
}

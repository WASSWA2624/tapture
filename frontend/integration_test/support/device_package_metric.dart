import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/files/project_folders.dart';
import 'package:tapture/core/files/storage_guard.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/exports/domain/export_repository.dart';
import 'package:tapture/features/merge/merge.dart';
import 'package:tapture/features/merge/presentation/merge_controller.dart';
import 'package:tapture/features/merge/presentation/package_import_controller.dart';

/// A separate real receiving device store, seeded before the timed merge.
final class DevicePackageMetric {
  DevicePackageMetric._(
    this.database,
    this.secrets,
    this.root,
    this.guard,
    this.container,
  );

  /// Imports the empty baseline through the actual reader and applying repository.
  static Future<DevicePackageMetric> create({
    required Directory directory,
    required PickedFile baseline,
  }) async {
    final SecureStorage secrets = SecureStorage.namespaced(
      'receiver_${DateTime.now().microsecondsSinceEpoch}',
    );
    final AppDatabase db = AppDatabase.open(
      directoryPath: '${directory.path}/receiver-db',
      keyStore: secrets,
    );
    final StorageRoot root = StorageRoot(
      documentsDirectory: () async =>
          Directory('${directory.path}/receiver-documents'),
    );
    final StorageGuard guard = StorageGuard(storageRoot: root);
    const SystemClock clock = SystemClock();
    final PackageImportRepositoryImpl repository = PackageImportRepositoryImpl(
      db: db,
      files: PackageFiles(storageRoot: root),
      clock: clock,
      deviceId: 'metric-receiver',
      ids: UuidV7Service(clock),
      guard: guard,
      folders: ProjectFolders(storageRoot: root),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        packageImportRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final DevicePackageMetric fixture = DevicePackageMetric._(
      db,
      secrets,
      root,
      guard,
      container,
    );
    try {
      final InspectedBundle inspected = (await BundleReader.inspect(
        baseline,
      )).getOrThrow();
      try {
        expect(inspected.rowsOf('records'), isEmpty);
        (await repository.importAsNew(inspected)).getOrThrow();
      } finally {
        await inspected.close();
      }
      return fixture;
    } on Object {
      await fixture.close();
      rethrow;
    }
  }

  /// Owned receiving SQLite connection.
  final AppDatabase database;

  /// Owned receiving Keystore/Keychain namespace.
  final SecureStorage secrets;

  /// Actual receiver file root under the producer sandbox.
  final StorageRoot root;

  /// Native disk headroom policy used during import and merge.
  final StorageGuard guard;

  /// Real inspection, planning-isolate and applying controllers.
  final ProviderContainer container;

  /// Includes reading, planning and committing 1,000 new records plus evidence.
  Future<Map<String, Object?>> measureMerge(
    PickedFile full,
    String projectId,
  ) async {
    final PackageImportController flow = container.read(
      packageImportControllerProvider.notifier,
    );
    final listener = container.listen(
      mergeControllerProvider(projectId),
      (_, _) {},
    );
    final Stopwatch timer = Stopwatch()..start();
    try {
      (await flow.check(full)).getOrThrow();
      final view = await container.read(
        mergeControllerProvider(projectId).future,
      );
      expect(view, isNotNull);
      expect(view!.report.canMerge, isTrue);
      expect(view.plan.counts.newRecords, 1000);
      expect(view.unsettled, isEmpty);
      (await container
              .read(mergeControllerProvider(projectId).notifier)
              .apply(chooser: 'Device measurement fixture'))
          .getOrThrow();
      timer.stop();
      final int records =
          (await database
                  .customSelect('SELECT COUNT(*) AS n FROM records')
                  .getSingle())
              .read<int>('n');
      final int photos =
          (await database
                  .customSelect('SELECT COUNT(*) AS n FROM photos')
                  .getSingle())
              .read<int>('n');
      expect(records, 1000);
      expect(photos, 1);
      return <String, Object?>{
        'metric': 'merge',
        'milliseconds': timer.elapsedMilliseconds,
        'scope':
            'native bundle inspect, isolate plan, file copy and atomic merge commit',
        'records': records,
        'photos': photos,
        'packageBytes': full.byteLength,
      };
    } finally {
      listener.close();
      await flow.finish();
    }
  }

  /// Releases only receiver resources. The parent removes the shared sandbox.
  Future<void> close() async {
    await container.read(packageImportControllerProvider.notifier).finish();
    container.dispose();
    await guard.dispose();
    await database.close();
    await secrets.deleteAll();
  }
}

/// The actual native output retained by the exporting repository.
Future<PickedFile> exportDevicePackage(
  ExportRepository repository,
  StorageRoot root,
  String projectId, {
  void Function(Map<String, Object?>)? measured,
}) async {
  final Stopwatch timer = Stopwatch()..start();
  final ExportedPackage exported = (await repository.exportProject(
    projectId,
    cancel: CancellationToken(),
  )).getOrThrow();
  timer.stop();
  final StoredBundle package = exported.package as StoredBundle;
  final Directory folder = (await root.resolve()).getOrThrow();
  final PickedFile picked = PickedFile(
    File('${folder.path}/${package.relativePath}'),
    exported.fileName,
    package.byteLength,
  );
  expect(await picked.file.length(), package.byteLength);
  if (measured != null) {
    final InspectedBundle inspected = (await BundleReader.inspect(
      picked,
    )).getOrThrow();
    try {
      expect(inspected.rowsOf('records'), hasLength(1000));
      expect(inspected.rowsOf('photos'), hasLength(1));
    } finally {
      await inspected.close();
    }
    measured(<String, Object?>{
      'metric': 'export',
      'milliseconds': timer.elapsedMilliseconds,
      'scope':
          'actual ExportRepository workbook and package write through export-row commit',
      'records': 1000,
      'photos': 1,
      'packageBytes': package.byteLength,
    });
  }
  return picked;
}

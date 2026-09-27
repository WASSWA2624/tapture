import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/bundle/bundle_zip_job.dart';
import 'package:tapture/core/bundle/bundle_zip_web.dart' as web;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/device/device_identity.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/ids/ids.dart';
import 'package:tapture/core/time/clock.dart';

import '../../support/bundle_fixture.dart';

void main() {
  late BundleFixture fixture;
  late BundleWriter writer;

  setUp(() async {
    fixture = await seedProjectForBundle();
    writer = _writer(fixture);
  });

  tearDown(() async {
    await fixture.db.close();
    if (fixture.root.parent.existsSync()) {
      fixture.root.parent.deleteSync(recursive: true);
    }
  });

  test('a written package reads back every row and file', () async {
    final StoredBundle stored = _stored(
      await writer.write(
        projectId: fixture.projectId,
        cancel: CancellationToken(),
        extras: <String, List<int>>{
          BundleFormat.workbook: utf8.encode('workbook'),
        },
      ),
    );
    final File package = File('${fixture.root.path}/${stored.relativePath}');
    expect(package.existsSync(), isTrue);
    expect(File('${package.path}.part').existsSync(), isFalse);
    expect(
      stored.relativePath,
      startsWith('projects/${fixture.folderName}/exports/'),
    );
    expect(stored.byteLength, package.lengthSync());
    expect(
      stored.sha256,
      crypto.sha256.convert(package.readAsBytesSync()).toString(),
    );

    final InspectedBundle bundle = _inspected(
      await BundleReader.inspect(
        PickedFile(package, 'seeded.zip', package.lengthSync()),
      ),
    );
    addTearDown(bundle.close);
    final BundleManifest manifest = bundle.manifest;
    expect(manifest.format, BundleFormat.name);
    expect(manifest.formatVersion, BundleFormat.version);
    expect(manifest.projectId, fixture.projectId);
    expect(manifest.projectName, 'Seeded project');
    expect(manifest.folderName, fixture.folderName);
    expect(manifest.sourceDeviceId, 'device-test');
    expect(manifest.operatorName, 'Ada');
    expect(manifest.lineage.last.device, 'device-test');
    expect(manifest.templates.single.templateKey, 'seeded_equipment');
    expect(manifest.templates.single.fields, <String, String>{
      'serial_number': 'text',
    });
    expect(manifest.missingFiles, isEmpty);

    final BundleTables local = (await BundleTables.read(
      fixture.db,
      fixture.projectId,
    ))!;
    for (final String table in BundleFormat.insertOrder) {
      expect(bundle.rowsOf(table), local.rows[table] ?? isEmpty, reason: table);
    }
    for (final MapEntry<String, Uint8List> file in fixture.files.entries) {
      final Result<Uint8List> read = await bundle.readEntry(file.key);
      expect((read as Success<Uint8List>).value, file.value, reason: file.key);
    }
    expect(
      utf8.decode(
        (await bundle.readEntry(BundleFormat.workbook) as Success<Uint8List>)
            .value,
      ),
      'workbook',
    );
  });

  test('the package carries only this project and what it looks up', () async {
    final BundleTables tables = (await BundleTables.read(
      fixture.db,
      fixture.projectId,
    ))!;

    expect(tables.rows['projects']!.single['id'], fixture.projectId);
    expect(
      tables.rows['records']!.map((Map<String, Object?> r) => r['project_id']),
      everyElement(fixture.projectId),
    );
    expect(
      tables.rows['audit_log']!.map((Map<String, Object?> r) => r['id']),
      isNot(contains('audit-other')),
    );
    expect(tables.rows['audit_log'], hasLength(2));
    expect(tables.rows['tombstones'], hasLength(1));
    expect(
      tables.rows['reference_datasets']!.map(
        (Map<String, Object?> r) => r['id'],
      ),
      <String>['ds-global'],
    );
    expect(tables.rows['reference_rows'], hasLength(1));
    expect(tables.rows['captions'], hasLength(2));
    expect(tables.rows['context_definitions'], hasLength(1));
    expect(tables.coverPath, 'cover/cover-1.jpg');
    expect(tables.filePaths, containsAll(fixture.files.keys));
  });

  test('no device secret enters any entry of the package', () async {
    final StoredBundle stored = _stored(
      await writer.write(
        projectId: fixture.projectId,
        cancel: CancellationToken(),
      ),
    );
    final Archive archive = ZipDecoder().decodeBytes(
      File('${fixture.root.path}/${stored.relativePath}').readAsBytesSync(),
    );

    for (final ArchiveFile file in archive.files) {
      final String text = latin1.decode(file.content as List<int>);
      expect(text, isNot(contains(fixture.secret)), reason: file.name);
      expect(text, isNot(contains('device_profile')), reason: file.name);
    }
  });

  test(
    'a file a row points at but the disk lost is listed as missing',
    () async {
      final String lost = fixture.files.keys.first;
      File(
        '${fixture.root.path}/projects/${fixture.folderName}/$lost',
      ).deleteSync();

      final StoredBundle stored = _stored(
        await writer.write(
          projectId: fixture.projectId,
          cancel: CancellationToken(),
        ),
      );
      final File package = File('${fixture.root.path}/${stored.relativePath}');
      final InspectedBundle bundle = _inspected(
        await BundleReader.inspect(
          PickedFile(package, 'seeded.zip', package.lengthSync()),
        ),
      );
      addTearDown(bundle.close);

      expect(bundle.manifest.missingFiles, <String>[lost]);
    },
  );

  test('a cancelled write leaves no package and no partial file', () async {
    final CancellationToken cancel = CancellationToken()..cancel();

    final Result<BundleOutput> result = await writer.write(
      projectId: fixture.projectId,
      cancel: cancel,
    );

    expect(
      (result as FailureResult<BundleOutput>).failure,
      isA<CancelledFailure>(),
    );
    final Directory exports = Directory(
      '${fixture.root.path}/projects/${fixture.folderName}/exports',
    );
    expect(
      exports.existsSync() ? exports.listSync() : const <FileSystemEntity>[],
      isEmpty,
    );
  });

  test(
    'a package estimated above the ceiling is refused before writing',
    () async {
      await fixture.db.customStatement(
        'UPDATE photos SET file_size = ?',
        <Object>[AppConstants.bundles.nativeMaxBytes],
      );

      final Result<int> estimate = await writer.estimate(fixture.projectId);
      final Result<BundleOutput> result = await writer.write(
        projectId: fixture.projectId,
        cancel: CancellationToken(),
      );

      expect((estimate as Success<int>).value, greaterThan(writer.ceiling));
      expect(
        (result as FailureResult<BundleOutput>).failure,
        isA<StorageFailure>(),
      );
      expect(
        Directory(
          '${fixture.root.path}/projects/${fixture.folderName}/exports',
        ).existsSync(),
        isFalse,
      );
    },
  );

  test('a missing project is a failure, not an empty package', () async {
    final Result<BundleOutput> result = await writer.write(
      projectId: 'no-such-project',
      cancel: CancellationToken(),
    );

    expect(result, isA<FailureResult<BundleOutput>>());
  });

  test(
    'a browser builds the same package in memory from its file store',
    () async {
      final BundleTables tables = (await BundleTables.read(
        fixture.db,
        fixture.projectId,
      ))!;
      final Result<BundleOutput> built = await web.zipBundle(
        BundleZipJob(
          storageRoot: fixture.storageRoot,
          files: FileReader.memory(<String, Uint8List>{
            for (final MapEntry<String, Uint8List> file
                in fixture.files.entries)
              'projects/${fixture.folderName}/${file.key}': file.value,
          }),
          folderName: fixture.folderName,
          targetPath: 'unused',
          entries: tables.encode(),
          projectFiles: tables.filePaths,
          manifest: BundleManifest(
            formatVersion: BundleFormat.version,
            appVersion: '1.0.0',
            schemaVersion: 20,
            bundleId: 'bundle-web',
            projectId: fixture.projectId,
            projectName: 'Seeded project',
            folderName: fixture.folderName,
            exportedAt: DateTime.utc(2026, 9, 27),
            sourceDeviceId: 'browser',
            counts: tables.counts,
            lineage: const <({String device, DateTime at})>[],
            templates: const <BundleTemplateSummary>[],
            entries: const <BundleEntry>[],
          ),
          ceiling: 200 * 1024 * 1024,
          cancel: CancellationToken(),
        ),
      );

      final InMemoryBundle bundle =
          (built as Success<BundleOutput>).value as InMemoryBundle;
      final InspectedBundle read = _inspected(
        await BundleReader.inspect(PickedBytes(bundle.bytes, 'web.zip')),
      );
      expect(read.manifest.bundleId, 'bundle-web');
      expect(
        (await read.readEntry(fixture.files.keys.first) as Success<Uint8List>)
            .value,
        fixture.files.values.first,
      );
    },
  );
}

BundleWriter _writer(BundleFixture fixture) {
  return BundleWriter(
    db: fixture.db,
    storageRoot: fixture.storageRoot,
    files: FileReader(storageRoot: fixture.storageRoot),
    clock: FixedClock(DateTime.utc(2026, 9, 27, 9)),
    ids: UuidV7Service.sequence(FixedClock(DateTime.utc(2026, 9, 27, 9))),
    deviceId: 'device-test',
    device: () async => const DeviceDescriptor.fake(),
    inBrowser: false,
  );
}

StoredBundle _stored(Result<BundleOutput> result) {
  return switch (result) {
    Success<BundleOutput>(:final BundleOutput value) => value as StoredBundle,
    FailureResult<BundleOutput>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

InspectedBundle _inspected(Result<InspectedBundle> result) {
  return switch (result) {
    Success<InspectedBundle>(:final InspectedBundle value) => value,
    FailureResult<InspectedBundle>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

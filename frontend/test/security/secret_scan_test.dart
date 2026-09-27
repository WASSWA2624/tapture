import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/bundle/bundle_entry.dart';
import 'package:tapture/core/bundle/bundle_format.dart';
import 'package:tapture/core/bundle/bundle_manifest.dart';
import 'package:tapture/core/bundle/bundle_output.dart';
import 'package:tapture/core/bundle/bundle_zip_io.dart';
import 'package:tapture/core/bundle/bundle_zip_job.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/csv_writer.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/logging/log_export.dart';
import 'package:tapture/core/logging/logger.dart';

import '../support/secret_patterns.dart';

void main() {
  late Logger previous;

  setUp(() {
    previous = Logger.current;
  });

  tearDown(() {
    Logger.current = previous;
  });

  test('a clean export, bundle and log contain no secret', () async {
    final Directory temp = Directory.systemTemp.createTempSync('tapture-scan');
    addTearDown(() {
      if (temp.existsSync()) {
        temp.deleteSync(recursive: true);
      }
    });
    final String yaml = File('tool/secret_patterns.yaml').readAsStringSync();
    final List<({String name, RegExp pattern})> patterns = SecretScan.compile(
      yaml,
      secrets: const <String>['planted-secret-value'],
    );
    final File csv = File('${temp.path}/records.csv');
    final Map<String, String> written = CsvWriter.write(
      const ExportRequest(
        projectId: 'project-1',
        formats: <ExportFormat>{ExportFormat.csv},
        scope: (
          kind: ExportScopeKind.all,
          context: null,
          from: null,
          to: null,
          filter: null,
        ),
        columns: (
          raw: true,
          refined: false,
          confidence: false,
          evidence: false,
        ),
        extras: (
          dictionary: false,
          photoIndex: false,
          photoMode: 'none',
          delimiter: ',',
        ),
        records: <ExportRecord>[
          ExportRecord(
            id: 'record-1',
            number: '1',
            templateId: 'template-1',
            templateName: 'Pumps',
            status: 'approved',
          ),
        ],
      ),
    );
    csv.writeAsStringSync(written.values.single);
    final Logger logger = Logger(deviceId: 'device-scan');
    Logger.current = logger;
    logger.info('app', 'export finished');
    final File log = (await exportLog(
      into: temp,
    )).fold((_) => throw StateError('log'), (File file) => file);
    final Directory docs = Directory('${temp.path}/docs')..createSync();
    final Result<BundleOutput> bundle = await zipBundle(
      BundleZipJob(
        storageRoot: StorageRoot.fake(documentsDirectory: docs),
        files: FileReader.memory(),
        folderName: 'pumps',
        targetPath: 'projects/pumps/exports/bundle.zip',
        entries: const <String, List<int>>{},
        projectFiles: const <String>[],
        manifest: BundleManifest(
          formatVersion: BundleFormat.version,
          appVersion: '1.0.0',
          schemaVersion: 22,
          bundleId: 'bundle-scan',
          projectId: 'project-1',
          projectName: 'Pumps',
          folderName: 'pumps',
          exportedAt: DateTime.utc(2026, 9, 28),
          sourceDeviceId: 'device-scan',
          counts: const <String, int>{},
          lineage: const <({String device, DateTime at})>[],
          templates: const <BundleTemplateSummary>[],
          entries: const <BundleEntry>[],
        ),
        ceiling: 1024 * 1024,
        cancel: CancellationToken(),
      ),
    );
    expect(bundle, isA<Success<BundleOutput>>());
    final StoredBundle stored =
        (bundle as Success<BundleOutput>).value as StoredBundle;
    final File zip = File('${docs.path}/Tapture/${stored.relativePath}');
    final List<SecretHit> hits = <SecretHit>[
      ...SecretScan.scanFile(csv, patterns),
      ...SecretScan.scanFile(log, patterns),
      if (zip.existsSync()) ...SecretScan.scanFile(zip, patterns),
    ];
    expect(hits, isEmpty);
  });

  test('a token in an entry name and a log line are both reported', () {
    const String token = 'bearer abcdefghijklmnop';
    final List<({String name, RegExp pattern})> patterns = SecretScan.compile(
      File('tool/secret_patterns.yaml').readAsStringSync(),
      secrets: const <String>[token],
    );
    final Archive archive = Archive();
    archive.addFile(ArchiveFile('$token.txt', 4, <int>[1, 2, 3, 4]));
    archive.addFile(ArchiveFile('notes.txt', token.length, token.codeUnits));
    final List<int> zipped = ZipEncoder().encode(archive)!;
    final Directory temp = Directory.systemTemp.createTempSync('tapture-bad');
    addTearDown(() => temp.deleteSync(recursive: true));
    final File bundle = File('${temp.path}/bad.zip')..writeAsBytesSync(zipped);
    final File log = File('${temp.path}/bad.log')
      ..writeAsStringSync('line $token\n');
    final List<SecretHit> hits = <SecretHit>[
      ...SecretScan.scanFile(bundle, patterns),
      ...SecretScan.scanFile(log, patterns),
    ];
    expect(hits.length, greaterThan(1));
    expect(hits.any((SecretHit hit) => hit.entry.contains('bearer')), isTrue);
    expect(
      hits.any((SecretHit hit) => hit.artefact.endsWith('bad.log')),
      isTrue,
    );
  });
}

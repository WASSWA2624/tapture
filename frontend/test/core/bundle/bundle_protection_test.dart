import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/bundle/bundle_zip_io.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart'
    show debugLiveIsolates;
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
  setUp(() async => fixture = await seedProjectForBundle());
  tearDown(() async {
    await fixture.db.close();
    fixture.root.parent.deleteSync(recursive: true);
  });

  BundleWriter writer({bool browser = false}) {
    final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 1));
    return BundleWriter(
      db: fixture.db,
      storageRoot: fixture.storageRoot,
      files: FileReader(storageRoot: fixture.storageRoot),
      clock: clock,
      ids: UuidV7Service.sequence(clock),
      deviceId: 'fixture',
      device: () async => const DeviceDescriptor.fake(),
      inBrowser: browser,
    );
  }

  Future<PickedFile> protectedNativePackage() async {
    final StoredBundle stored =
        (await writer().write(
              projectId: fixture.projectId,
              cancel: CancellationToken(),
              password: 'fixture password',
            )).getOrThrow()
            as StoredBundle;
    final File file = File('${fixture.root.path}/${stored.relativePath}');
    return PickedFile(file, 'protected.zip', file.lengthSync());
  }

  test(
    'cancelling an active protected write releases workers and all owned scratch',
    () async {
      final CancellationToken cancel = CancellationToken();
      final List<String> scratch = <String>[];
      final Result<BundleOutput> result = await writer()
          .write(
            projectId: fixture.projectId,
            cancel: cancel,
            password: 'cancel this write',
            onProgress: (double fraction) {
              if (fraction > 0.9 && scratch.isEmpty) {
                scratch.addAll(debugBundleWriteScratchPaths);
                cancel.cancel();
              }
            },
          )
          .timeout(const Duration(seconds: 10));
      expect(
        (result as FailureResult<BundleOutput>).failure,
        isA<CancelledFailure>(),
      );
      expect(scratch, isNotEmpty);
      expect(debugBundleWriteScratchPaths, isEmpty);
      expect(debugLiveIsolates, 0);
      for (final String path in scratch) {
        expect(await Directory(path).exists(), isFalse);
      }
      expect(
        await fixture.root
            .list(recursive: true)
            .where(
              (FileSystemEntity entity) =>
                  entity.path.contains('.part') ||
                  entity.path.endsWith('.cipher'),
            )
            .toList(),
        isEmpty,
      );
    },
  );

  test('native encrypted packages read the same real rows and files', () async {
    final PickedFile picked = await protectedNativePackage();
    expect((await BundleReader.needsPassword(picked)).getOrThrow(), isTrue);
    expect(
      await BundleReader.inspect(picked),
      isA<FailureResult<InspectedBundle>>(),
    );
    final InspectedBundle opened = (await BundleReader.inspect(
      picked,
      password: 'fixture password',
    )).getOrThrow();
    for (final MapEntry<String, Uint8List> photo in fixture.files.entries) {
      expect((await opened.readEntry(photo.key)).getOrThrow(), photo.value);
    }
    expect(opened.rowsOf('records'), hasLength(2));
    await opened.close();
    expect(
      await opened.readEntry(fixture.files.keys.first),
      isA<FailureResult<Uint8List>>(),
    );
    expect(
      picked.file.parent
          .listSync()
          .whereType<File>()
          .map((File file) => file.path)
          .where(
            (String path) => path.contains('.part') || path.endsWith('.cipher'),
          ),
      isEmpty,
    );
  });

  test(
    'native encrypted packages refuse a wrong password without extraction',
    () async {
      final PickedFile picked = await protectedNativePackage();
      final Result<InspectedBundle> result = await BundleReader.inspect(
        picked,
        password: 'different',
      );
      expect(
        (result as FailureResult<InspectedBundle>).failure,
        isA<ValidationFailure>(),
      );
      expect(await picked.file.exists(), isTrue);
      expect(debugLiveIsolates, 0);
      expect(
        picked.file.parent
            .listSync()
            .whereType<File>()
            .map((File file) => file.path)
            .where(
              (String path) =>
                  path.contains('.part') || path.endsWith('.cipher'),
            ),
        isEmpty,
      );
    },
  );

  test(
    'browser encrypted packages open through the same reader with no password persisted in tables',
    () async {
      final InMemoryBundle stored =
          (await writer(browser: true).write(
                projectId: fixture.projectId,
                cancel: CancellationToken(),
                password: 'fixture password',
              )).getOrThrow()
              as InMemoryBundle;
      final PickedDocument picked = PickedBytes(stored.bytes, 'protected.zip');
      final InspectedBundle opened = (await BundleReader.inspect(
        picked,
        password: 'fixture password',
      )).getOrThrow();
      expect(opened.manifest.projectId, fixture.projectId);
      expect(jsonEncode(opened.tables), isNot(contains('fixture password')));
      expect(
        (await opened.readEntry(fixture.files.keys.first)).getOrThrow(),
        fixture.files.values.first,
      );
      await opened.close();
    },
    tags: <String>['performance'],
  );

  test(
    'real writers refuse secrets in entry names payloads and compressed nested workbook entries',
    () async {
      final String token = 'sk-${List<String>.filled(24, 'x').join()}';
      final Archive nested = Archive()
        ..addFile(
          ArchiveFile('xl/value.xml', token.length, utf8.encode(token)),
        );
      final List<Map<String, List<int>>> cases = <Map<String, List<int>>>[
        <String, List<int>>{
          '$token.txt': <int>[1],
        },
        <String, List<int>>{'note.txt': utf8.encode(token)},
        <String, List<int>>{'records.xlsx': ZipEncoder().encodeBytes(nested)},
      ];
      for (final bool browser in <bool>[false, true]) {
        for (final Map<String, List<int>> extras in cases) {
          final Result<BundleOutput> result = await writer(browser: browser)
              .write(
                projectId: fixture.projectId,
                cancel: CancellationToken(),
                extras: extras,
              );
          expect(result, isA<FailureResult<BundleOutput>>());
          expect(
            (result as FailureResult<BundleOutput>).failure,
            isA<ValidationFailure>(),
          );
        }
      }
    },
  );

  test(
    'native attachment scan checks compressed content without publishing a bundle',
    () async {
      final String token = 'sk-${List<String>.filled(24, 'x').join()}';
      final Archive nested = Archive()
        ..addFile(
          ArchiveFile('xl/value.xml', token.length, utf8.encode(token)),
        );
      final File attachment = File(
        '${fixture.root.path}/projects/${fixture.folderName}/${fixture.files.keys.first}',
      );
      attachment.writeAsBytesSync(ZipEncoder().encodeBytes(nested));
      final Result<BundleOutput> result = await writer().write(
        projectId: fixture.projectId,
        cancel: CancellationToken(),
      );
      expect(result, isA<FailureResult<BundleOutput>>());
      expect(
        (result as FailureResult<BundleOutput>).failure,
        isA<ValidationFailure>(),
      );
      final Directory exports = Directory(
        '${fixture.root.path}/projects/${fixture.folderName}/exports',
      );
      expect(
        exports.existsSync() ? exports.listSync() : const <FileSystemEntity>[],
        isEmpty,
      );
    },
  );

  test(
    'production encoding strips nested settings credentials while preserving source data',
    () async {
      final String token = 'sk-${List<String>.filled(24, 'x').join()}';
      final String settings = jsonEncode(<String, Object?>{
        'connection': <String, Object?>{'password': token, 'label': 'Site'},
      });
      await fixture.db.customStatement(
        'UPDATE projects SET settings = ? WHERE id = ?',
        <Object>[settings, fixture.projectId],
      );
      final StoredBundle stored =
          (await writer().write(
                projectId: fixture.projectId,
                cancel: CancellationToken(),
              )).getOrThrow()
              as StoredBundle;
      final File file = File('${fixture.root.path}/${stored.relativePath}');
      final InspectedBundle opened = (await BundleReader.inspect(
        PickedFile(file, 'package.zip', file.lengthSync()),
      )).getOrThrow();
      final String exported =
          opened.rowsOf('projects').single['settings']! as String;
      expect(exported, isNot(contains(token)));
      expect(jsonDecode(exported), <String, Object?>{
        'connection': <String, Object?>{'label': 'Site'},
      });
      expect(
        (await fixture.db
                .customSelect(
                  'SELECT settings FROM projects WHERE id = ?',
                  variables: <Variable<Object>>[
                    Variable<String>(fixture.projectId),
                  ],
                )
                .getSingle())
            .data['settings'],
        settings,
      );
      await opened.close();
    },
  );
}

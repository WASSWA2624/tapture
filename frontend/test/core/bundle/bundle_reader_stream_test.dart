import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive_io.dart' hide ZLibEncoder;
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/bundle/bundle_archive_stream.dart';
import 'package:tapture/core/bundle/bundle_json.dart';
import 'package:tapture/core/bundle/bundle_zip_job.dart';
import 'package:tapture/core/bundle/native_bundle_entries.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';

import '../../support/bundle_fixture.dart';

void main() {
  test(
    'native inspection and compressed entry streaming retain bounded RSS',
    () async {
      final ({File file, BundleEntry entry}) source = await _largePackage(
        128 * 1024 * 1024,
      );
      addTearDown(() => source.file.parent.delete(recursive: true));
      final int baseline = ProcessInfo.currentRss;
      int peak = baseline;
      final Timer sample = Timer.periodic(const Duration(milliseconds: 5), (_) {
        peak = max(peak, ProcessInfo.currentRss);
      });
      late InspectedBundle bundle;
      try {
        bundle = (await BundleReader.inspect(
          PickedFile(source.file, 'large.zip', await source.file.length()),
        )).getOrThrow();
        int count = 0;
        final Stream<List<int>> stream = (await bundle.openEntry(
          source.entry.path,
        )).getOrThrow();
        final crypto.Digest digest = await crypto.sha256
            .bind(
              stream.map((List<int> chunk) {
                expect(chunk.length, lessThanOrEqualTo(64 * 1024));
                count += chunk.length;
                return chunk;
              }),
            )
            .first;
        expect(count, source.entry.byteLength);
        expect(digest.toString(), source.entry.sha256);
        peak = max(peak, ProcessInfo.currentRss);
        expect(peak - baseline, lessThan(80 * 1024 * 1024));
        await bundle.close();
        expect(await source.file.exists(), isTrue);
        final File metrics = File('build/bundle-reader-memory-audit.json');
        await metrics.parent.create(recursive: true);
        await metrics.writeAsString(
          jsonEncode(<String, int>{
            'uncompressedEntryBytes': count,
            'compressedPackageBytes': await source.file.length(),
            'baseline': baseline,
            'peak': peak,
            'additional': peak - baseline,
          }),
        );
      } finally {
        sample.cancel();
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
    tags: <String>['performance'],
  );

  test(
    'entry completion, cancellation and owner close remove generated plaintext',
    () async {
      final ({File file, BundleEntry entry}) source = await _largePackage(
        2 * 1024 * 1024,
      );
      addTearDown(() => source.file.parent.delete(recursive: true));
      final Directory scratch = await Directory(
        '${source.file.parent.path}/scratch',
      ).create();
      final NativeBundleEntries entries = NativeBundleEntries(
        source: source.file.path,
        scratch: scratch,
        entries: <BundleEntry>[source.entry],
      );
      final Stream<List<int>> first = (await entries.openEntry(
        source.entry.path,
      )).getOrThrow();
      await first.first;
      expect(await scratch.list().toList(), isEmpty);
      final Stream<List<int>> unopened = (await entries.openEntry(
        source.entry.path,
      )).getOrThrow();
      expect(await scratch.list().toList(), hasLength(1));
      await entries.close();
      expect(await scratch.exists(), isFalse);
      expect(await unopened.toList(), isEmpty);
      expect(await source.file.exists(), isTrue);
    },
  );

  test(
    'closing during decompression stops the worker and removes partial output',
    () async {
      final ({File file, BundleEntry entry}) source = await _largePackage(
        128 * 1024 * 1024,
      );
      addTearDown(() => source.file.parent.delete(recursive: true));
      final Directory scratch = await Directory(
        '${source.file.parent.path}/scratch',
      ).create();
      final NativeBundleEntries entries = NativeBundleEntries(
        source: source.file.path,
        scratch: scratch,
        entries: <BundleEntry>[source.entry],
        inventory: _checkedOffsets(source.file),
      );
      final Future<Result<Stream<List<int>>>> opening = entries.openEntry(
        source.entry.path,
      );
      final File partial = File('${scratch.path}/entry-1/payload');
      final Stopwatch started = Stopwatch()..start();
      while (!await partial.exists() &&
          started.elapsed < const Duration(seconds: 3)) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(
        await partial.exists(),
        isTrue,
        reason: 'cancel while the actual output handle is open',
      );
      await entries.close().timeout(const Duration(seconds: 3));
      expect(
        (await opening as FailureResult<Stream<List<int>>>).failure,
        isA<CancelledFailure>(),
      );
      expect(await scratch.exists(), isFalse);
      expect(debugLiveIsolates, 0);
      expect(await source.file.exists(), isTrue);
    },
  );

  test(
    'cancelling inspection closes the native source handle before return',
    () async {
      final ({File file, BundleEntry entry}) source = await _largePackage(
        128 * 1024 * 1024,
      );
      addTearDown(() => source.file.parent.delete(recursive: true));
      final CancellationToken cancel = CancellationToken();
      final Future<Result<InspectedBundle>> pending = BundleReader.inspect(
        PickedFile(source.file, 'large.zip', await source.file.length()),
        cancel: cancel,
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      cancel.cancel();
      final Result<InspectedBundle> result = await pending.timeout(
        const Duration(seconds: 3),
      );
      expect(
        (result as FailureResult<InspectedBundle>).failure,
        isA<CancelledFailure>(),
      );
      expect(debugLiveIsolates, 0);
      expect(cancel.debugListenerCount, 0);
      // Windows rejects this deletion while a killed isolate retains its handle.
      await source.file.delete();
      expect(await source.file.exists(), isFalse);
    },
  );

  test('bounded metadata encoding rejects overflow while emitting chunks', () {
    expect(
      () => BundleJson.encode(<String, Object?>{
        'value': 'a' * 100000,
      }, maximum: 1000),
      throwsA(isA<ValidationFailure>()),
    );
    expect(
      utf8.decode(
        BundleJson.encode(<String, Object?>{'value': 'é'}, maximum: 100),
      ),
      '{"value":"é"}',
    );
  });

  test(
    'a declared 4 GB JSON entry is refused before native inflation',
    () async {
      final Archive archive = Archive()
        ..addFile(
          _compressedEntry(BundleFormat.manifest, 4000000000, const <int>[
            1,
            2,
            3,
          ]),
        );
      final List<int> encoded = ZipEncoder().encodeBytes(archive);
      final Directory folder = await Directory.systemTemp.createTemp(
        'tapture-metadata-test-',
      );
      addTearDown(() => folder.delete(recursive: true));
      final File file = await File(
        '${folder.path}/oversized.zip',
      ).writeAsBytes(encoded);
      final Result<InspectedBundle> result = await BundleReader.inspect(
        PickedFile(file, 'oversized.zip', encoded.length),
      );
      expect(
        (result as FailureResult<InspectedBundle>).failure.message,
        BundleReader.rejectionMessage(BundleRejection.tooLarge),
      );
    },
  );

  test('inflated bytes cannot exceed a smaller declared entry length', () {
    final List<int> compressed = ZLibEncoder(
      raw: true,
    ).convert(List<int>.filled(100000, 1));
    final ArchiveFile entry = _compressedEntry('data', 1, compressed);
    expect(() => BundleArchiveStream.checksum(entry), throwsFormatException);
  });

  test(
    'five thousand real stored records remain below the metadata ceiling',
    () async {
      final BundleFixture fixture = await seedProjectForBundle(records: 5000);
      addTearDown(() async {
        await fixture.db.close();
        await fixture.root.parent.delete(recursive: true);
      });
      final BundleTables tables = (await BundleTables.read(
        fixture.db,
        fixture.projectId,
      ))!;
      expect(tables.rows['records'], hasLength(5000));
      expect(
        tables.encode().values.fold<int>(
          0,
          (int sum, List<int> bytes) => sum + bytes.length,
        ),
        lessThan(AppConstants.bundles.metadataMaxBytes),
      );
    },
    tags: <String>['performance'],
  );
}

Map<String, BundleZipEntry> _checkedOffsets(File source) {
  final InputFileStream input = InputFileStream(source.path);
  try {
    final Map<String, BundleZipEntry> inventory = <String, BundleZipEntry>{};
    BundleArchiveStream.decode(input, inventory: inventory);
    return inventory;
  } finally {
    input.closeSync();
  }
}

Future<({File file, BundleEntry entry})> _largePackage(int length) async {
  final Uint8List chunk = Uint8List(64 * 1024);
  int crc = 0;
  Stream<List<int>> content() async* {
    for (int offset = 0; offset < length; offset += chunk.length) {
      yield chunk;
    }
  }

  final crypto.Digest digest = await crypto.sha256.bind(content()).first;
  final BytesBuilder compressed = BytesBuilder(copy: false);
  await for (final List<int> bytes in ZLibEncoder(raw: true).bind(
    content().map((List<int> bytes) {
      crc = getCrc32(bytes, crc);
      return bytes;
    }),
  )) {
    compressed.add(bytes);
  }
  final BundleEntry photo = BundleEntry(
    path: 'photos/large.bin',
    byteLength: length,
    sha256: digest.toString(),
  );
  final Map<String, List<int>> data = <String, List<int>>{
    for (final String path in BundleFormat.tableEntries.keys)
      path: utf8.encode('{}'),
    'project.json': utf8.encode(
      '{"projects":[{"id":"p","name":"Test","folder_name":"test"}]}',
    ),
  };
  final List<BundleEntry> written = <BundleEntry>[
    for (final MapEntry<String, List<int>> entry in data.entries)
      BundleEntry(
        path: entry.key,
        byteLength: entry.value.length,
        sha256: crypto.sha256.convert(entry.value).toString(),
      ),
    photo,
  ];
  final ({List<int> manifest, List<int> checksums}) finish = finishBundle(
    BundleManifest(
      formatVersion: BundleFormat.version,
      appVersion: '1.0.0',
      schemaVersion: 20,
      bundleId: 'bundle',
      projectId: 'p',
      projectName: 'Test',
      folderName: 'test',
      exportedAt: DateTime.utc(2026, 10, 1),
      sourceDeviceId: 'device',
      counts: const <String, int>{},
      lineage: const <({String device, DateTime at})>[],
      templates: const <BundleTemplateSummary>[],
      entries: const <BundleEntry>[],
    ),
    written,
    missingFiles: const <String>[],
  );
  final Archive archive = Archive()
    ..addFile(
      _compressedEntry(photo.path, length, compressed.takeBytes(), crc: crc),
    );
  for (final MapEntry<String, List<int>> entry in <String, List<int>>{
    ...data,
    BundleFormat.manifest: finish.manifest,
    BundleFormat.checksums: finish.checksums,
  }.entries) {
    archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
  }
  final Directory folder = await Directory.systemTemp.createTemp(
    'tapture-entry-test-',
  );
  final File file = await File(
    '${folder.path}/package.zip',
  ).writeAsBytes(ZipEncoder().encodeBytes(archive));
  return (file: file, entry: photo);
}

// Deliberately keeps declared and actual sizes independent for malformed input
// and RSS fixtures. The encoder forwards already-compressed bytes unchanged.
ArchiveFile _compressedEntry(
  String name,
  int declaredSize,
  List<int> bytes, {
  int crc = 0,
}) =>
    ArchiveFile.file(
        name,
        declaredSize,
        _CompressedFixtureContent(InputMemoryStream(bytes)),
      )
      ..compression = CompressionType.deflate
      ..crc32 = crc;

final class _CompressedFixtureContent extends FileContent {
  _CompressedFixtureContent(this._source);
  final InputStream _source;

  @override
  int get length => _source.length;

  @override
  bool get isCompressed => true;

  @override
  InputStream getStream({bool decompress = true}) {
    if (!decompress) return _source.subset();
    final OutputMemoryStream output = OutputMemoryStream();
    this.decompress(output);
    return InputMemoryStream(output.getBytes());
  }

  @override
  void decompress(OutputStream output) {
    Inflate.stream(_source.subset(), output: output);
  }

  @override
  void write(OutputStream output) => decompress(output);

  @override
  Future<void> close() async => closeSync();

  @override
  void closeSync() => _source.closeSync();
}

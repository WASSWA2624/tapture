@Timeout(Duration(minutes: 5))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/export_archive.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';

void main() {
  late Directory documents;
  late Directory root;
  late ExportArchive archive;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('tapture-archive-');
    final StorageRoot storage = StorageRoot.fake(documentsDirectory: documents);
    root = _ok(await storage.resolve());
    archive = ExportArchive(
      storageRoot: storage,
      files: FileReader(storageRoot: storage),
      writer: FileWriter(storageRoot: storage),
    );
  });

  tearDown(() async {
    await documents.delete(recursive: true);
  });

  test(
    'failed and cancelled archives preserve an earlier completed target',
    () async {
      final File target = File('${root.path}/exports/kept.zip');
      await target.parent.create(recursive: true);
      await target.writeAsString('previous export');
      for (final CancellationToken cancel in <CancellationToken>[
        CancellationToken(),
        CancellationToken()..cancel(),
      ]) {
        final Result<WrittenFile> result = await archive.write(
          target: 'exports/kept.zip',
          sources: <String, String>{'missing.jpg': 'photos/missing.jpg'},
          manifest: Uint8List.fromList(utf8.encode('{}')),
          cancel: cancel,
        );
        expect(result, isA<FailureResult<WrittenFile>>());
        expect(await target.readAsString(), 'previous export');
        expect(await File('${target.path}.part').exists(), isFalse);
      }
    },
  );

  test(
    'a cancelled native worker closes handles and can immediately replace the same target',
    () async {
      final File target = File('${root.path}/exports/kept.zip');
      await target.parent.create(recursive: true);
      await target.writeAsString('previous export');
      final File source = File('${root.path}/photos/evidence.jpg');
      await source.parent.create(recursive: true);
      await source.writeAsString('photo evidence');
      final CancellationToken cancel = CancellationToken();
      final Result<WrittenFile> stopped = await archive.write(
        target: 'exports/kept.zip',
        sources: <String, String>{'evidence.jpg': 'photos/evidence.jpg'},
        manifest: Uint8List.fromList(utf8.encode('{}')),
        cancel: cancel,
        onProgress: (double progress) {
          if (progress > 0) cancel.cancel();
        },
      );
      expect(
        (stopped as FailureResult<WrittenFile>).failure,
        isA<CancelledFailure>(),
      );
      expect(await target.readAsString(), 'previous export');
      expect(await File('${target.path}.part').exists(), isFalse);
      final WrittenFile written = _ok(
        await archive.write(
          target: 'exports/kept.zip',
          sources: <String, String>{'evidence.jpg': 'photos/evidence.jpg'},
          manifest: Uint8List.fromList(utf8.encode('{}')),
          cancel: CancellationToken(),
        ),
      );
      expect(written.byteLength, await target.length());
      final Archive decoded = ZipDecoder().decodeBytes(
        await target.readAsBytes(),
      );
      expect(
        utf8.decode(decoded.findFile('evidence.jpg')!.content),
        'photo evidence',
      );
    },
  );

  test(
    'a 400MB native archive streams within 120MB of additional resident memory',
    () async {
      const int size = 400 * 1024 * 1024;
      final File source = File('${root.path}/photos/evidence.bin');
      await source.parent.create(recursive: true);
      final RandomAccessFile handle = await source.open(mode: FileMode.write);
      // A sparse fixture has the same logical stream length without allocating
      // the input in the test or needlessly consuming storage on the host.
      await handle.truncate(size);
      await handle.close();
      final int baseline = ProcessInfo.currentRss;
      int peak = baseline;
      final Timer sample = Timer.periodic(const Duration(milliseconds: 5), (_) {
        final int resident = ProcessInfo.currentRss;
        if (resident > peak) peak = resident;
      });
      final Stopwatch elapsed = Stopwatch()..start();
      late WrittenFile written;
      try {
        written = _ok(
          await archive.write(
            target: 'exports/large.zip',
            sources: <String, String>{
              'photos/evidence.bin': 'photos/evidence.bin',
            },
            manifest: Uint8List.fromList(utf8.encode('{"fixture":true}')),
            cancel: CancellationToken(),
          ),
        );
      } finally {
        sample.cancel();
        elapsed.stop();
      }
      expect(await source.length(), size);
      expect(written.byteLength, greaterThan(size));
      expect(peak - baseline, lessThan(120 * 1024 * 1024));
      final InputFileStream input = InputFileStream(
        '${root.path}/${written.relativePath}',
      );
      try {
        final Archive decoded = ZipDecoder().decodeStream(input);
        expect(decoded.findFile('photos/evidence.bin')?.size, size);
        expect(decoded.files.last.name, 'manifest.json');
      } finally {
        input.close();
      }
      // Metrics are fixture results, not a claim about a reference field device.
      // ignore: avoid_print
      print(
        'archive fixture: ${elapsed.elapsedMilliseconds}ms, '
        '${(peak - baseline) ~/ (1024 * 1024)}MB peak RSS above baseline',
      );
    },
  );
}

T _ok<T>(Result<T> result) => result.fold(
  (Failure failure) => throw TestFailure(failure.message),
  (T value) => value,
);

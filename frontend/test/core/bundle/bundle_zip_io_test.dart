import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/bundle/bundle_manifest.dart';
import 'package:tapture/core/bundle/bundle_output.dart';
import 'package:tapture/core/bundle/bundle_zip_io.dart';
import 'package:tapture/core/bundle/bundle_zip_job.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/storage_root.dart';

void main() {
  test(
    'cancelling a replacement preserves the completed target byte for byte',
    () async {
      final _Fixture fixture = await _fixture();
      final List<int> old = utf8.encode('an earlier completed package');
      await fixture.target.writeAsBytes(old);
      final CancellationToken cancel = CancellationToken();
      final Result<BundleOutput> result = await zipBundle(
        fixture.job(
          'replacement',
          cancel,
          onProgress: (double progress) {
            if (progress > 0) cancel.cancel();
          },
        ),
      );
      expect(
        (result as FailureResult<BundleOutput>).failure,
        isA<CancelledFailure>(),
      );
      expect(await fixture.target.readAsBytes(), old);
      expect(await File('${fixture.target.path}.part').exists(), isFalse);
    },
  );

  test(
    'a write cancelled while waiting for the shared lock never starts publication',
    () async {
      final _Fixture fixture = await _fixture();
      final List<int> old = utf8.encode('an earlier completed package');
      await fixture.target.writeAsBytes(old);
      final Completer<void> entered = Completer<void>();
      final Completer<void> release = Completer<void>();
      final Future<void> holder = fixture.root.withWriteLock(
        fixture.target.parent.path,
        () async {
          entered.complete();
          await release.future;
        },
      );
      await entered.future;
      final CancellationToken cancel = CancellationToken();
      final Future<Result<BundleOutput>> pending = zipBundle(
        fixture.job('replacement', cancel),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(await fixture.target.readAsBytes(), old);
      cancel.cancel();
      release.complete();
      await holder;
      expect(
        (await pending as FailureResult<BundleOutput>).failure,
        isA<CancelledFailure>(),
      );
      expect(await fixture.target.readAsBytes(), old);
    },
  );

  test(
    'colliding writers serialize cleanup and publish one complete replacement',
    () async {
      final _Fixture fixture = await _fixture();
      final CancellationToken firstCancel = CancellationToken();
      final Future<Result<BundleOutput>> first = zipBundle(
        fixture.job(
          'cancelled',
          firstCancel,
          onProgress: (double progress) {
            if (progress > 0) firstCancel.cancel();
          },
        ),
      );
      final Future<Result<BundleOutput>> second = zipBundle(
        fixture.job('completed', CancellationToken()),
      );
      expect(await first, isA<FailureResult<BundleOutput>>());
      final StoredBundle stored =
          (await second as Success<BundleOutput>).value as StoredBundle;
      final List<int> bytes = await fixture.target.readAsBytes();
      final Archive archive = ZipDecoder().decodeBytes(bytes);
      expect(
        utf8.decode(archive.findFile('payload.txt')!.content),
        'completed',
      );
      expect(stored.sha256, sha256.convert(bytes).toString());
      expect(stored.byteLength, bytes.length);
      expect(await File('${fixture.target.path}.part').exists(), isFalse);
    },
  );

  test('a worker failure leaves the previous target intact', () async {
    final _Fixture fixture = await _fixture();
    final List<int> old = utf8.encode('an earlier completed package');
    await fixture.target.writeAsBytes(old);
    await Directory('${fixture.target.path}.part').create();
    expect(
      await zipBundle(fixture.job('replacement', CancellationToken())),
      isA<FailureResult<BundleOutput>>(),
    );
    expect(await fixture.target.readAsBytes(), old);
  });

  test(
    'a failing completion observer cannot turn a published bundle into failure',
    () async {
      final _Fixture fixture = await _fixture();
      final Result<BundleOutput> result = await zipBundle(
        fixture.job(
          'completed',
          CancellationToken(),
          onProgress: (double progress) {
            if (progress == 1) throw StateError('disposed observer');
          },
        ),
      );
      expect(result, isA<Success<BundleOutput>>());
      expect(await fixture.target.exists(), isTrue);
    },
  );
}

Future<_Fixture> _fixture() async {
  final Directory documents = await Directory.systemTemp.createTemp(
    'tapture_bundle_atomic_',
  );
  addTearDown(() => documents.delete(recursive: true));
  final StorageRoot root = StorageRoot.fake(documentsDirectory: documents);
  final Directory base = (await root.resolve() as Success<Directory>).value;
  const String path = 'projects/sample/exports/current.tapture.zip';
  final File target = File('${base.path}/$path');
  await target.parent.create(recursive: true);
  return _Fixture(root, target, path);
}

final class _Fixture {
  _Fixture(this.root, this.target, this.path);
  final StorageRoot root;
  final File target;
  final String path;
  BundleZipJob job(
    String payload,
    CancellationToken cancel, {
    void Function(double)? onProgress,
  }) => BundleZipJob(
    storageRoot: root,
    files: FileReader(storageRoot: root),
    folderName: 'sample',
    targetPath: path,
    entries: <String, List<int>>{'payload.txt': utf8.encode(payload)},
    projectFiles: const <String>[],
    manifest: BundleManifest(
      formatVersion: 1,
      appVersion: '1',
      schemaVersion: 1,
      bundleId: 'bundle-a',
      projectId: 'project-a',
      projectName: 'Sample',
      folderName: 'sample',
      exportedAt: DateTime.utc(2026, 9, 30),
      sourceDeviceId: 'device-a',
      counts: const <String, int>{},
      lineage: const [],
      templates: const [],
      entries: const [],
    ),
    ceiling: 1024 * 1024,
    cancel: cancel,
    onProgress: onProgress,
  );
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/audio/audio_recorder_service.dart';
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/camera/camera_service.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart' hide CaptureSession;
import 'package:tapture/core/device/device_identity.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/data/capture_record_writer.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';

import '../test/support/bundle_fixture.dart';
import '../test/support/fault_injection.dart';
import '../test/support/malformed_response_recovery.dart';
import '../test/support/matchers.dart';
import '../test/support/processing_fixture.dart';
import 'support/capture_rig.dart';
import 'support/harness.dart';

const String _valid =
    '{"fields":{"serial":{"value":"SN458923","confidence":0.9,"evidence":["photo-1"]}}}';

void main() {
  final Map<Dependency, Future<void> Function(FaultInjector)> cases =
      <Dependency, Future<void> Function(FaultInjector)>{
        Dependency.camera: _camera,
        Dependency.microphone: _microphone,
        Dependency.storage: _storage,
        Dependency.provider: (FaultInjector faults) =>
            _provider(faults, Dependency.provider),
        Dependency.key: (FaultInjector faults) =>
            _provider(faults, Dependency.key),
        Dependency.response: _response,
        Dependency.bundle: _bundle,
        Dependency.database: _database,
        Dependency.process: _process,
      };
  test('every injectable failure boundary has an executable recovery case', () {
    expect(missingFaultCases(cases.keys), isEmpty);
  });
  for (final MapEntry<Dependency, Future<void> Function(FaultInjector)> entry
      in cases.entries) {
    test(
      '${entry.key.name}: evidence survives failure and retry succeeds after clear',
      () async {
        final FaultInjector faults = FaultInjector();
        addTearDown(faults.clear);
        await entry.value(faults);
        expect(faults.check(entry.key), isNull);
      },
    );
  }
}

Future<CaptureRig> _capture() async {
  final TestApp app = await bootTestApp();
  addTearDown(app.dispose);
  final CaptureRig rig = await CaptureRig.open(app);
  valueOf(await rig.controller.setTemplate(CaptureRig.templateId));
  await rig.shoot();
  valueOf(await rig.controller.setCaption(null, 'Original evidence'));
  return rig;
}

Future<void> _preserved(CaptureRig rig, CaptureSession before) async {
  expect(rig.session.toJson(), before.toJson());
  for (final PhotoDraft photo in before.photos) {
    expect(
      rig.file(photo.relativePath).readAsBytesSync(),
      utf8.encode(photo.id),
    );
    expect(
      valueOf(await rig.container.read(photoRepositoryProvider).byId(photo.id)),
      isNotNull,
    );
  }
  expect(rig.app.outboundCallCount, 0);
}

Future<void> _camera(FaultInjector faults) async {
  final CaptureRig rig = await _capture();
  final CaptureSession before = rig.session;
  final CameraService camera = CameraService.fake();
  addTearDown(camera.stop);
  faults.fail(Dependency.camera, const PermissionFailure());
  final Result<Uint8List> denied = await faults.run(
    Dependency.camera,
    camera.takePicture,
  );
  expect(denied, isA<FailureResult<Uint8List>>());
  expect(
    (denied as FailureResult<Uint8List>).failure.recoveryAction,
    isNotEmpty,
  );
  await _preserved(rig, before);
  faults.clear();
  expect(
    await faults.run(Dependency.camera, camera.takePicture),
    isA<Success<Uint8List>>(),
  );
  await rig.shoot();
  expect(rig.session.photos, hasLength(2));
}

Future<void> _microphone(FaultInjector faults) async {
  final CaptureRig rig = await _capture();
  final CaptureSession before = rig.session;
  final AudioRecorderService recorder = AudioRecorderService.fake();
  addTearDown(recorder.stop);
  faults.fail(Dependency.microphone, const PermissionFailure());
  expect(
    await faults.run(
      Dependency.microphone,
      () => recorder.start('audio/retry.wav'),
    ),
    isA<FailureResult<void>>(),
  );
  await _preserved(rig, before);
  faults.clear();
  expect(
    await faults.run(
      Dependency.microphone,
      () => recorder.start('audio/retry.wav'),
    ),
    isA<Success<void>>(),
  );
  expect(await recorder.stop(), isA<Success<Duration>>());
}

Future<void> _storage(FaultInjector faults) async {
  final CaptureRig rig = await _capture();
  final CaptureSession before = rig.session;
  final Directory documents = await Directory.systemTemp.createTemp(
    'tapture-fault-storage-',
  );
  addTearDown(() => documents.delete(recursive: true));
  final StorageRoot root = StorageRoot.fake(documentsDirectory: documents);
  const String path = 'evidence/original.jpg';
  Future<Result<WrittenFile>> write(List<int> bytes) => FileWriter(
    storageRoot: root,
    fullDisk: faults.check(Dependency.storage) != null,
  ).write(Stream<List<int>>.value(bytes), path);
  valueOf(await write(<int>[1, 2, 3]));
  faults.fail(Dependency.storage, const StorageFailure());
  final Result<WrittenFile> failed = await write(<int>[4, 5, 6]);
  expect(failed, isA<FailureResult<WrittenFile>>());
  expect(
    (failed as FailureResult<WrittenFile>).failure.recoveryAction,
    isNotEmpty,
  );
  final Directory base = valueOf(await root.resolve());
  expect(await File('${base.path}/$path').readAsBytes(), <int>[1, 2, 3]);
  await _preserved(rig, before);
  faults.clear();
  valueOf(await write(<int>[4, 5, 6]));
  expect(await File('${base.path}/$path').readAsBytes(), <int>[4, 5, 6]);
}

Future<void> _provider(FaultInjector faults, Dependency dependency) async {
  final ProcessingFixture fixture = await ProcessingFixture.open(
    plateText: 'GRUNDFOS 240V',
  );
  await fixture.addField('serial', required: true);
  final ProcessingJob job = await fixture.job();
  final String photoPath =
      '${fixture.projectFolder}/${(await fixture.db.select(fixture.db.photos).getSingle()).relativePath}';
  final List<int> original = await File(photoPath).readAsBytes();
  faults.fail(
    dependency,
    dependency == Dependency.key
        ? const ProviderFailure(kind: ProviderFailureKind.authentication)
        : const NetworkFailure(),
  );
  final _FaultAi provider = _FaultAi(
    faults,
    dependency,
    ScriptedExtraction(<String>[_valid]),
  );
  final worker = fixture.worker(
    provider: provider,
    ocr: CountingOcr('GRUNDFOS 240V'),
  );
  await worker.perform(JobStage.prepare, job);
  await worker.perform(JobStage.onDevice, job);
  await worker.perform(JobStage.detect, job);
  await expectLater(
    worker.perform(JobStage.online, job),
    throwsA(isA<Failure>()),
  );
  expect(await File(photoPath).readAsBytes(), original);
  expect((await fixture.storedRecord()).id, fixture.record.id);
  faults.clear();
  await worker.perform(JobStage.online, job);
  expect(
    (await fixture.db.select(fixture.db.processingResults).get()).any(
      (ProcessingResult row) => row.parsedOk && row.rawResponse == _valid,
    ),
    isTrue,
  );
}

Future<void> _response(FaultInjector faults) =>
    verifyMalformedResponseRecovery(faults);

Future<void> _bundle(FaultInjector faults) async {
  final BundleFixture fixture = await seedProjectForBundle();
  addTearDown(() async {
    await fixture.db.close();
    await fixture.root.parent.delete(recursive: true);
  });
  final FixedClock clock = FixedClock(DateTime.utc(2026, 10));
  final StoredBundle output =
      valueOf(
            await BundleWriter(
              db: fixture.db,
              storageRoot: fixture.storageRoot,
              files: FileReader(storageRoot: fixture.storageRoot),
              clock: clock,
              ids: UuidV7Service.sequence(clock),
              deviceId: 'test-device',
              device: () async => const DeviceDescriptor.fake(),
            ).write(projectId: fixture.projectId, cancel: CancellationToken()),
          )
          as StoredBundle;
  final File source = File('${fixture.root.path}/${output.relativePath}');
  faults.fail(Dependency.bundle, const CorruptionFailure());
  final File corrupt = File('${fixture.root.path}/corrupt.zip');
  await corrupt.writeAsBytes((await source.readAsBytes()).take(20).toList());
  expect(
    await BundleReader.inspect(
      PickedFile(corrupt, 'corrupt.zip', await corrupt.length()),
    ),
    isA<FailureResult<InspectedBundle>>(),
  );
  expect(await source.length(), output.byteLength);
  expect(await fixture.db.select(fixture.db.records).get(), hasLength(3));
  faults.clear();
  expect(
    await BundleReader.inspect(
      PickedFile(source, 'valid.zip', await source.length()),
    ),
    isA<Success<InspectedBundle>>(),
  );
}

Future<({CaptureRig rig, AppDatabase db, Directory directory, File file})>
_durable() async {
  final CaptureRig rig = await _capture();
  final Directory directory = await Directory.systemTemp.createTemp(
    'tapture-fault-db-',
  );
  final File file = File('${directory.path}/tapture.sqlite');
  await rig.app.db.customStatement('VACUUM INTO ?', <Object?>[file.path]);
  final AppDatabase db = AppDatabase.open(directoryPath: directory.path);
  await db.customStatement('PRAGMA busy_timeout=0');
  addTearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });
  return (rig: rig, db: db, directory: directory, file: file);
}

CaptureRecordWriter _writer(AppDatabase db, CaptureRig rig) =>
    CaptureRecordWriter(
      db: db,
      clock: rig.app.clock,
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(rig.app.clock),
    );

Future<void> _database(FaultInjector faults) async {
  final fixture = await _durable();
  final CaptureSession before = fixture.rig.session;
  final raw.Database lock = raw.sqlite3.open(fixture.file.path);
  addTearDown(lock.close);
  faults.fail(Dependency.database, const StorageFailure());
  lock.execute('BEGIN IMMEDIATE');
  try {
    final Result<String> failed = await _writer(
      fixture.db,
      fixture.rig,
    ).persist(before);
    expect(failed, isA<FailureResult<String>>());
    expect(
      (failed as FailureResult<String>).failure.message,
      'The database is busy.',
    );
    expect(await fixture.db.select(fixture.db.records).get(), isEmpty);
    await _preserved(fixture.rig, before);
  } finally {
    lock.execute('ROLLBACK');
  }
  faults.clear();
  final String record = valueOf(
    await _writer(fixture.db, fixture.rig).persist(before),
  );
  expect((await fixture.db.select(fixture.db.records).getSingle()).id, record);
}

Future<void> _process(FaultInjector faults) async {
  final fixture = await _durable();
  final CaptureSession before = fixture.rig.session;
  final String payload =
      (await fixture.db.select(fixture.db.captureSessions).getSingle())
          .payloadJson;
  faults.fail(
    Dependency.process,
    const ProviderFailure(message: 'Injected process interruption.'),
  );
  final File config = File('.dart_tool/package_config.json').absolute;
  final Map<String, Object?> packages =
      jsonDecode(await config.readAsString()) as Map<String, Object?>;
  final Map<String, Object?> flutter = (packages['packages']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .singleWhere(
        (Map<String, Object?> package) => package['name'] == 'flutter',
      );
  final String rootUri = flutter['rootUri']! as String;
  final Uri flutterRoot = config.uri.resolve(
    rootUri.endsWith('/') ? rootUri : '$rootUri/',
  );
  final String dart = File.fromUri(
    flutterRoot.resolve(
      '../../bin/cache/dart-sdk/bin/${Platform.isWindows ? 'dart.exe' : 'dart'}',
    ),
  ).path;
  final List<String> args = <String>[
    'run',
    '--verbosity=error',
    '--packages=${config.path}',
    File('test/support/crash_capture_child.dart').absolute.path,
    fixture.file.path,
  ];
  // dart run resolves SQLite's native build assets before starting the writer.
  final Process child = await Process.start(
    dart,
    args,
    workingDirectory: config.parent.parent.path,
  );
  final Future<String> errors = child.stderr.transform(utf8.decoder).join();
  addTearDown(() async {
    child.kill();
    await child.exitCode;
  });
  final String ready = await child.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .first
      .timeout(const Duration(seconds: 30));
  expect(ready, 'TAPTURE_CAPTURE_TRANSACTION_OPEN');
  expect(faults.check(Dependency.process), isNotNull);
  expect(child.kill(), isTrue);
  expect(await child.exitCode, isNot(0), reason: await errors);
  expect(
    (await fixture.db.select(fixture.db.captureSessions).getSingle())
        .payloadJson,
    payload,
  );
  await _preserved(fixture.rig, before);
  faults.clear();
  final String record = valueOf(
    await _writer(fixture.db, fixture.rig).persist(before),
  );
  expect((await fixture.db.select(fixture.db.records).getSingle()).id, record);
}

final class _FaultAi implements AiService {
  const _FaultAi(this.faults, this.dependency, this.delegate);
  final FaultInjector faults;
  final Dependency dependency;
  final AiService delegate;
  @override
  bool get isAvailable => delegate.isAvailable;
  @override
  Future<Result<ExtractFieldsResult>> extractFields(
    ExtractFieldsRequest request,
  ) => faults.run(dependency, () => delegate.extractFields(request));
  @override
  Future<Result<ReadTextResult>> readText(ReadTextRequest request) =>
      faults.run(dependency, () => delegate.readText(request));
  @override
  Future<Result<RefineTextResult>> refineText(RefineTextRequest request) =>
      faults.run(dependency, () => delegate.refineText(request));
  @override
  Future<Result<TranscribeResult>> transcribe(TranscribeRequest request) =>
      faults.run(dependency, () => delegate.transcribe(request));
}

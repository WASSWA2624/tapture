import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart' as record;
import 'package:tapture/core/audio/audio_recorder_plugin.dart';
import 'package:tapture/core/audio/audio_recorder_service.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';

const String _target = 'projects/p1/audio/take.wav';

/// Bytes the fake plugin writes: a RIFF header stub and a few samples.
final List<int> _take = <int>[
  ...'RIFF'.codeUnits,
  1,
  2,
  3,
  4,
  ...'WAVE'.codeUnits,
];

/// Hand-written stand-in for the plugin (FE-TEST-03): file mode only, the
/// way the real plugins record WAV.
final class _FakeRecorder implements record.AudioRecorder {
  _FakeRecorder({this.permission = true, this.startError});

  final bool permission;
  final Object? startError;
  record.RecordConfig? config;
  String? path;
  bool streamed = false;

  @override
  Future<bool> hasPermission({bool request = true}) async => permission;

  @override
  Future<void> start(record.RecordConfig config, {required String path}) async {
    final Object? error = startError;
    if (error != null) {
      throw error;
    }
    this.config = config;
    this.path = path;
  }

  @override
  Future<Stream<Uint8List>> startStream(record.RecordConfig config) async {
    streamed = true;
    throw UnsupportedError('stream mode');
  }

  @override
  Future<String?> stop() async {
    final String? target = path;
    if (target != null) {
      await File(target).writeAsBytes(_take);
    }
    return target;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Stream<record.Amplitude> onAmplitudeChanged(Duration interval) {
    return const Stream<record.Amplitude>.empty();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory documents;
  late StorageRoot root;

  setUp(() {
    documents = Directory.systemTemp.createTempSync('tapture_audio_plugin_');
    root = StorageRoot.fake(documentsDirectory: documents);
  });

  tearDown(() {
    if (documents.existsSync()) {
      documents.deleteSync(recursive: true);
    }
  });

  Future<String> rootPath() async {
    final Result<Directory> resolved = await root.resolve();
    return (resolved as Success<Directory>).value.path;
  }

  test(
    'start records WAV in file mode at 16 kHz mono beside the target',
    () async {
      final _FakeRecorder fake = _FakeRecorder();
      final AudioRecorderPlugin plugin = AudioRecorderPlugin(
        writer: FileWriter(storageRoot: root),
        storageRoot: root,
        recorder: fake,
      );

      expect(await plugin.start(_target), isA<Success<void>>());

      expect(fake.streamed, isFalse);
      expect(fake.config?.encoder, record.AudioEncoder.wav);
      expect(fake.config?.sampleRate, AppConstants.audio.sampleRate);
      expect(fake.config?.numChannels, AppConstants.audio.channels);
      expect(fake.path, '${await rootPath()}/$_target.recording');
      await plugin.stop();
    },
  );

  test(
    'stop publishes the take with its hash and removes the staging file',
    () async {
      final AudioRecorderPlugin plugin = AudioRecorderPlugin(
        writer: FileWriter(storageRoot: root),
        storageRoot: root,
        recorder: _FakeRecorder(),
      );
      await plugin.start(_target);

      final Result<Duration> stopped = await plugin.stop();

      expect(stopped, isA<Success<Duration>>());
      final AudioRecording completed = plugin.completed!;
      final String base = await rootPath();
      final File published = File('$base/$_target');
      expect(completed.relativePath, _target);
      expect(completed.mimeType, 'audio/wav');
      expect(published.readAsBytesSync().take(4), 'RIFF'.codeUnits);
      expect(completed.sha256, sha256.convert(_take).toString());
      expect(completed.byteLength, _take.length);
      expect(File('$base/$_target.recording').existsSync(), isFalse);
    },
  );

  test('a failed copy keeps the staging file and reports failed', () async {
    final AudioRecorderPlugin plugin = AudioRecorderPlugin(
      writer: FileWriter(storageRoot: root, fullDisk: true),
      storageRoot: root,
      recorder: _FakeRecorder(),
    );
    final List<AudioRecorderPhase> phases = <AudioRecorderPhase>[];
    final StreamSubscription<AudioRecorderState> sub = plugin.state.listen(
      (AudioRecorderState state) => phases.add(state.phase),
    );
    addTearDown(sub.cancel);
    await plugin.start(_target);

    final Result<Duration> stopped = await plugin.stop();
    await Future<void>.delayed(Duration.zero);

    expect(stopped, isA<FailureResult<Duration>>());
    expect(plugin.completed, isNull);
    expect(phases.last, AudioRecorderPhase.failed);
    final String base = await rootPath();
    expect(File('$base/$_target.recording').existsSync(), isTrue);
    expect(File('$base/$_target').existsSync(), isFalse);
  });

  test('a start that throws returns the plain start failure', () async {
    final AudioRecorderPlugin plugin = AudioRecorderPlugin(
      writer: FileWriter(storageRoot: root),
      storageRoot: root,
      recorder: _FakeRecorder(startError: StateError('native refused')),
    );

    final Result<void> started = await plugin.start(_target);

    final Failure failure = (started as FailureResult<void>).failure;
    expect(failure.message, Copy.audioStartFailed);
    expect(failure.recoveryAction, Copy.audioStartFailedRecovery);
  });

  test('a denied microphone keeps the permission failure', () async {
    final AudioRecorderPlugin plugin = AudioRecorderPlugin(
      writer: FileWriter(storageRoot: root),
      storageRoot: root,
      recorder: _FakeRecorder(permission: false),
    );

    final Result<void> started = await plugin.start(_target);

    expect((started as FailureResult<void>).failure, isA<PermissionFailure>());
  });

  test('a path that leaves the storage folder is refused', () async {
    final _FakeRecorder fake = _FakeRecorder();
    final AudioRecorderPlugin plugin = AudioRecorderPlugin(
      writer: FileWriter(storageRoot: root),
      storageRoot: root,
      recorder: fake,
    );

    final Result<void> started = await plugin.start('../outside.wav');

    expect((started as FailureResult<void>).failure, isA<ValidationFailure>());
    expect(fake.path, isNull);
  });
}

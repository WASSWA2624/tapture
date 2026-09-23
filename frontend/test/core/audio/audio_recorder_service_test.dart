import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/audio/audio_recorder_service.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';

void main() {
  test(
    'fake recorder publishes metadata only after its file is flushed',
    () async {
      final Directory documents = Directory.systemTemp.createTempSync(
        'tapture_audio_recorder_',
      );
      addTearDown(() {
        if (documents.existsSync()) documents.deleteSync(recursive: true);
      });
      final StorageRoot root = StorageRoot.fake(documentsDirectory: documents);
      final AudioRecorderService recorder = AudioRecorderService.fake(
        writer: FileWriter(storageRoot: root),
        tick: const Duration(milliseconds: 5),
      );

      expect(
        await recorder.start('projects/p1/audio/clip.wav'),
        isA<Success<void>>(),
      );
      expect(recorder.completed, isNull);
      await Future<void>.delayed(const Duration(milliseconds: 25));
      await recorder.pause();
      final Duration paused = _ok(await recorder.stop());

      expect(paused, greaterThan(Duration.zero));
      final AudioRecording completed = recorder.completed!;
      expect(completed.relativePath, 'projects/p1/audio/clip.wav');
      expect(completed.byteLength, greaterThan(0));
      expect(completed.sha256, hasLength(64));
      final Directory resolved = _ok(await root.resolve());
      expect(
        File('${resolved.path}/${completed.relativePath}').existsSync(),
        isTrue,
      );
    },
  );

  test('permission failure publishes no completed clip', () async {
    const PermissionFailure denied = PermissionFailure(
      message: 'Microphone denied.',
      recoveryAction: 'Allow microphone access.',
    );
    final AudioRecorderService recorder = AudioRecorderService.fake(
      startFailure: denied,
    );

    final Result<void> started = await recorder.start('audio/clip.wav');

    expect(started, isA<FailureResult<void>>());
    expect(recorder.completed, isNull);
  });

  test('a full disk never publishes a completed clip', () async {
    final Directory documents = Directory.systemTemp.createTempSync(
      'tapture_audio_full_',
    );
    addTearDown(() {
      if (documents.existsSync()) documents.deleteSync(recursive: true);
    });
    final AudioRecorderService recorder = AudioRecorderService.fake(
      writer: FileWriter(
        storageRoot: StorageRoot.fake(documentsDirectory: documents),
        fullDisk: true,
      ),
      tick: const Duration(milliseconds: 5),
    );

    await recorder.start('projects/p1/audio/clip.wav');
    await Future<void>.delayed(const Duration(milliseconds: 15));
    final Result<Duration> stopped = await recorder.stop();

    expect(stopped, isA<FailureResult<Duration>>());
    expect(recorder.completed, isNull);
  });
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

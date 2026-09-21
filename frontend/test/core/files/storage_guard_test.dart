import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_guard.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/files/volume_stats.dart';
import 'package:tapture/core/lifecycle/lifecycle_observer.dart';

void main() {
  test(
    'a fake volume crosses ample, low and critical at the constants',
    () async {
      final _Volume volume = _Volume(AppConstants.storage.lowBytes);
      final StorageGuard guard = await _open(volume);

      expect(_ok(await guard.check()), HeadroomState.ample);

      volume.bytes = AppConstants.storage.lowBytes - 1;
      expect(_ok(await guard.check()), HeadroomState.low);

      volume.bytes = AppConstants.storage.criticalBytes;
      expect(_ok(await guard.check()), HeadroomState.low);

      volume.bytes = AppConstants.storage.criticalBytes - 1;
      expect(_ok(await guard.check()), HeadroomState.critical);
    },
  );

  test('a low session warns once and still admits capture', () async {
    final _Volume volume = _Volume(AppConstants.storage.lowBytes - 1);
    final StorageGuard guard = await _open(volume);

    expect(_ok(await guard.beginSession()), HeadroomState.low);
    expect(guard.takeLowWarning(), isTrue);
    expect(guard.takeLowWarning(), isFalse);
    expect(_ok(await guard.admitCapture()), HeadroomState.low);

    expect(_ok(await guard.beginSession()), HeadroomState.low);
    expect(guard.takeLowWarning(), isTrue);
  });

  test(
    'critical refuses a new capture and names export and cache cleanup',
    () async {
      final _Volume volume = _Volume(AppConstants.storage.criticalBytes - 1);
      final StorageGuard guard = await _open(volume);

      expect(_ok(await guard.beginSession()), HeadroomState.critical);
      expect(guard.takeLowWarning(), isFalse);

      final Result<HeadroomState> refused = await guard.admitCapture();
      final Failure failure = refused.fold(
        (Failure value) => value,
        (_) => fail('critical capture should be refused'),
      );

      expect(failure, isA<StorageFailure>());
      expect(failure.message.toLowerCase(), contains('photo'));
      expect(failure.recoveryAction, isNotNull);
      expect(failure.recoveryAction!.toLowerCase(), contains('export'));
      expect(failure.recoveryAction!.toLowerCase(), contains('cache'));
    },
  );

  test('an in-flight save completes after the volume turns critical', () async {
    final _Volume volume = _Volume(AppConstants.storage.lowBytes);
    final StorageGuard guard = await _open(volume);
    expect(_ok(await guard.beginSession()), HeadroomState.ample);

    final Completer<void> started = Completer<void>();
    final Completer<Result<String>> finish = Completer<Result<String>>();
    final Future<Result<String>> save = guard.completeSave(() async {
      started.complete();
      return finish.future;
    });

    await started.future;
    volume.bytes = 0;
    expect(_ok(await guard.check()), HeadroomState.critical);
    expect(
      (await guard.admitCapture()).fold((Failure _) => true, (_) => false),
      isTrue,
    );

    finish.complete(const Success<String>('written'));
    expect(_ok(await save), 'written');
  });

  test('resume polls again and a shutter does not', () async {
    var reads = 0;
    final _Volume volume = _Volume(AppConstants.storage.lowBytes);
    final LifecycleObserver observer = LifecycleObserver.fake();
    final StorageGuard guard = await _open(
      volume,
      lifecycle: observer.states,
      onRead: () => reads += 1,
    );

    final Completer<HeadroomState> dropped = Completer<HeadroomState>();
    final StreamSubscription<HeadroomState> subscription = guard.watch().listen(
      (HeadroomState state) {
        if (state == HeadroomState.critical && !dropped.isCompleted) {
          dropped.complete(state);
        }
      },
    );
    addTearDown(subscription.cancel);

    expect(_ok(await guard.beginSession()), HeadroomState.ample);
    expect(reads, 1);
    expect(_ok(await guard.admitCapture()), HeadroomState.ample);
    expect(_ok(await guard.admitCapture()), HeadroomState.ample);
    expect(reads, 1);

    volume.bytes = 0;
    await observer.handle(AppLifecycleState.resumed);
    expect(await dropped.future, HeadroomState.critical);
    expect(reads, 2);
  });

  test('the fake volume reports the known byte counts', () async {
    const int free = 300;
    const int used = 100;
    const int total = 400;
    final StorageGuard guard = await _open(
      _Volume(free),
      totalBytes: () => total,
      usedBytes: () => used,
    );
    final VolumeStats stats = _ok(await guard.volume());
    expect(stats.totalBytes, total);
    expect(stats.usedBytes, used);
    expect(stats.freeBytes, free);
  });

  test('a failed volume read is a failure, not ample', () async {
    final StorageGuard guard = await _open(_Volume(1 << 30), volumeFails: true);
    expect(await guard.volume(), isA<FailureResult<VolumeStats>>());
    final Result<HeadroomState> checked = await guard.check();
    expect(checked, isA<FailureResult<HeadroomState>>());
    expect(checked.fold((Failure _) => true, (_) => false), isTrue);
  });
}

final class _Volume {
  _Volume(this.bytes);

  int bytes;
}

Future<StorageGuard> _open(
  _Volume volume, {
  Stream<AppLifecycleState>? lifecycle,
  void Function()? onRead,
  int Function()? totalBytes,
  int Function()? usedBytes,
  bool volumeFails = false,
}) async {
  final Directory documents = Directory.systemTemp.createTempSync(
    'tapture-guard-',
  );
  addTearDown(() {
    if (documents.existsSync()) {
      documents.deleteSync(recursive: true);
    }
  });
  final StorageRoot storage = StorageRoot.fake(documentsDirectory: documents);
  _ok(await storage.resolve());
  final StorageGuard guard = StorageGuard.fake(
    storageRoot: storage,
    lifecycle: lifecycle,
    volumeFails: volumeFails,
    totalBytes: totalBytes,
    usedBytes: usedBytes,
    freeBytes: () {
      onRead?.call();
      return volume.bytes;
    },
  );
  addTearDown(guard.dispose);
  return guard;
}

T _ok<T>(Result<T> result) {
  return result.fold((Failure failure) {
    fail('${failure.message} ${failure.recoveryAction}');
  }, (T value) => value);
}

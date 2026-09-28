import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/camera/camera_service.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

const CameraDescription _back = CameraDescription(
  name: 'back',
  lensDirection: CameraLensDirection.back,
  sensorOrientation: 90,
);

void main() {
  late _Controllers controllers;
  late CameraService camera;
  late List<CameraPreviewState> states;

  setUp(() {
    controllers = _Controllers();
    camera = CameraService.device(
      cameras: () async => const <CameraDescription>[_back],
      open: controllers.open,
    );
    states = <CameraPreviewState>[];
    addTearDown(camera.previewState.listen(states.add).cancel);
  });

  test('a stop while the first open waits on the permission prompt does not '
      'leave the next start stuck on starting', () async {
    final Future<Result<void>> first = camera.start();
    await pumpEventQueue();
    expect(controllers.opened, hasLength(1));

    // The prompt makes the app inactive; granting it resumes the app.
    expect(await camera.stop(), isA<Success<void>>());
    controllers.ready = true;
    final Future<Result<void>> second = camera.start();
    controllers.opened.single.finish();

    expect(await first, isA<FailureResult<void>>());
    expect(await second, isA<Success<void>>());
    await pumpEventQueue();
    expect(controllers.opened, hasLength(2));
    expect(controllers.opened.first.released, isTrue);
    expect(controllers.opened.last.released, isFalse);
    expect(states, <CameraPreviewState>[
      CameraPreviewState.starting,
      CameraPreviewState.starting,
      CameraPreviewState.running,
    ]);
    expect(await camera.start(), isA<Success<void>>());
    expect(controllers.opened, hasLength(2));
  });

  test('a second start while the first is opening joins it', () async {
    final Future<Result<void>> first = camera.start();
    final Future<Result<void>> again = camera.start();
    expect(identical(first, again), isTrue);

    await pumpEventQueue();
    controllers.opened.single.finish();

    expect(await first, isA<Success<void>>());
    expect(controllers.opened, hasLength(1));
  });

  test('a stop releases a running preview; a start reopens it', () async {
    controllers.ready = true;
    expect(await camera.start(), isA<Success<void>>());

    expect(await camera.stop(), isA<Success<void>>());
    expect(controllers.opened.single.released, isTrue);
    expect(await camera.start(), isA<Success<void>>());

    expect(controllers.opened, hasLength(2));
    await pumpEventQueue();
    expect(states, <CameraPreviewState>[
      CameraPreviewState.starting,
      CameraPreviewState.running,
      CameraPreviewState.starting,
      CameraPreviewState.starting,
      CameraPreviewState.running,
    ]);
  });

  test('a device with no camera reports the preview failed', () async {
    final CameraService none = CameraService.device(
      cameras: () async => const <CameraDescription>[],
      open: controllers.open,
    );
    final List<CameraPreviewState> seen = <CameraPreviewState>[];
    addTearDown(none.previewState.listen(seen.add).cancel);

    final Result<void> started = await none.start();

    expect(started, isA<FailureResult<void>>());
    expect((started as FailureResult<void>).failure, isA<ProviderFailure>());
    await pumpEventQueue();
    expect(seen, <CameraPreviewState>[
      CameraPreviewState.starting,
      CameraPreviewState.failed,
    ]);
    expect(controllers.opened, isEmpty);
  });
}

/// The controllers the service opened. Each waits in [initialize] until
/// [_FakeController.finish], as the first open waits on the permission
/// prompt, unless [ready] was set when it was made.
final class _Controllers {
  final List<_FakeController> opened = <_FakeController>[];
  bool ready = false;

  CameraController open(CameraDescription _) {
    final _FakeController controller = _FakeController(ready: ready);
    opened.add(controller);
    return controller;
  }
}

final class _FakeController extends CameraController {
  _FakeController({required bool ready})
    : super(_back, ResolutionPreset.high, enableAudio: false) {
    if (ready) {
      _opened.complete();
    }
  }

  final Completer<void> _opened = Completer<void>();

  /// Whether the service released this controller.
  bool released = false;

  /// Lets a waiting [initialize] finish, as granting the prompt does.
  void finish() => _opened.complete();

  @override
  Future<void> initialize() async {
    await _opened.future;
    value = value.copyWith(isInitialized: true);
  }

  @override
  Future<double> getMinZoomLevel() async => 1;

  @override
  Future<double> getMaxZoomLevel() async => 4;

  @override
  Future<void> setZoomLevel(double zoom) async {}

  @override
  Future<void> setFlashMode(FlashMode mode) async {}

  @override
  Future<void> dispose() async {
    released = true;
    await super.dispose();
  }
}

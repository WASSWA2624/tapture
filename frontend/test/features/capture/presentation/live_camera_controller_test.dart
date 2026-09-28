import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/camera/camera_service.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/capture/presentation/live_camera_controller.dart';

void main() {
  /// A container holding the controller for [camera] alive for the test.
  ProviderContainer containerFor(CameraService camera) {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final ProviderSubscription<LiveCameraState> hold = container.listen(
      liveCameraControllerProvider(camera),
      (LiveCameraState? _, LiveCameraState _) {},
    );
    addTearDown(hold.close);
    return container;
  }

  test('a shot is written before the shutter takes another', () async {
    final Uint8List frame = Uint8List.fromList(<int>[1, 2, 3]);
    final CameraService camera = CameraService.fake(pictureBytes: frame);
    final ProviderContainer container = containerFor(camera);
    final LiveCameraController controller = container.read(
      liveCameraControllerProvider(camera).notifier,
    );
    final Completer<void> writing = Completer<void>();
    final List<Uint8List> written = <Uint8List>[];

    final Future<Result<void>> first = controller.shoot((Uint8List bytes) {
      written.add(bytes);
      return writing.future;
    });
    await pumpEventQueue();
    expect(container.read(liveCameraControllerProvider(camera)).saving, isTrue);

    final Result<void> second = await controller.shoot((Uint8List bytes) {
      written.add(bytes);
      return Future<void>.value();
    });
    expect(second, isA<Success<void>>());
    expect(written, <Uint8List>[frame]);

    writing.complete();
    expect(await first, isA<Success<void>>());
    expect(
      container.read(liveCameraControllerProvider(camera)).saving,
      isFalse,
    );
  });

  test('a failed shot hands back the failure and writes nothing', () async {
    final CameraService camera = CameraService.fake(
      takeFailure: const ProviderFailure(message: Copy.photoNoCamera),
    );
    final ProviderContainer container = containerFor(camera);
    final List<Uint8List> written = <Uint8List>[];

    final LiveCameraController controller = container.read(
      liveCameraControllerProvider(camera).notifier,
    );
    final Result<void> shot = await controller.shoot((Uint8List bytes) async {
      written.add(bytes);
    });

    expect(shot, isA<FailureResult<void>>());
    expect((shot as FailureResult<void>).failure.message, Copy.photoNoCamera);
    expect(written, isEmpty);
    expect(
      container.read(liveCameraControllerProvider(camera)).saving,
      isFalse,
    );
  });

  test('the grid starts as the camera has it and follows the controls', () {
    final CameraService camera = CameraService.fake();
    final ProviderContainer container = containerFor(camera);
    expect(container.read(liveCameraControllerProvider(camera)).grid, isFalse);

    container.read(liveCameraControllerProvider(camera).notifier).setGrid(true);

    expect(container.read(liveCameraControllerProvider(camera)).grid, isTrue);
  });
}

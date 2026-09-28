import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/camera/camera_service.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/features/capture/presentation/camera_view.dart';
import 'package:tapture/features/capture/presentation/live_camera_screen.dart';

void main() {
  testWidgets('the shutter hands the shot on and waits for it to be written', (
    WidgetTester tester,
  ) async {
    final Uint8List frame = Uint8List.fromList(<int>[1, 2, 3]);
    final Completer<void> writing = Completer<void>();
    final List<Uint8List> written = <Uint8List>[];
    Future<void> write(Uint8List bytes) {
      written.add(bytes);
      return writing.future;
    }

    await _open(tester, CameraService.fake(pictureBytes: frame), write);

    await tester.tap(_shutter);
    await tester.pump();

    expect(written, <Uint8List>[frame]);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(_shutterButton(tester).onPressed, isNull);

    writing.complete();
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(_shutterButton(tester).onPressed, isNotNull);
  });

  testWidgets('a failed shot says why and writes nothing', (
    WidgetTester tester,
  ) async {
    final List<Uint8List> written = <Uint8List>[];
    await _open(
      tester,
      CameraService.fake(
        takeFailure: const ProviderFailure(message: Copy.photoNoCamera),
      ),
      (Uint8List bytes) async {
        written.add(bytes);
      },
    );

    await tester.tap(_shutter);
    await tester.pumpAndSettle();

    expect(find.text(Copy.photoNoCamera), findsOneWidget);
    expect(written, isEmpty);
    expect(_shutterButton(tester).onPressed, isNotNull);
  });

  testWidgets('turning the grid on draws it over the preview', (
    WidgetTester tester,
  ) async {
    final CameraService camera = CameraService.fake();
    await _open(tester, camera, (Uint8List _) async {});
    final Finder grid = find.descendant(
      of: find.byType(CameraView),
      matching: find.byType(CustomPaint),
    );
    expect(grid, findsNothing);

    await tester.tap(find.byIcon(AppIcons.gridOff));
    await tester.pumpAndSettle();

    expect(camera.gridEnabled, isTrue);
    expect(grid, findsOneWidget);
  });

  testWidgets('going inactive while the camera is still opening leaves the '
      'open running', (WidgetTester tester) async {
    final _OpeningCamera camera = _OpeningCamera();
    await _open(tester, camera, (Uint8List _) async {});

    // The first-run permission prompt makes the app inactive, then resumed.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(camera.calls, <String>['start', 'resume']);
  });

  testWidgets('going inactive releases a running preview and resuming '
      'opens it again', (WidgetTester tester) async {
    await _open(tester, CameraService.fake(), (Uint8List _) async {});
    expect(find.text(CameraPreviewState.running.name), findsOneWidget);

    // Pause and resume report their state asynchronously; give it a frame to
    // reach the view before reading it.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    await tester.pump();
    expect(find.text(CameraPreviewState.starting.name), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(find.text(CameraPreviewState.running.name), findsOneWidget);
  });
}

Future<void> _open(
  WidgetTester tester,
  CameraService camera,
  Future<void> Function(Uint8List bytes) onCaptured,
) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: LiveCameraScreen(camera: camera, onCaptured: onCaptured),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final Finder _shutter = find.byIcon(AppIcons.shutter);

IconButton _shutterButton(WidgetTester tester) {
  return tester.widget<IconButton>(
    find.ancestor(of: _shutter, matching: find.byType(IconButton)),
  );
}

/// A camera whose first open is still waiting, as it does behind the
/// permission prompt. It records what the view asks of it.
final class _OpeningCamera implements CameraService {
  final List<String> calls = <String>[];
  final StreamController<CameraPreviewState> _states =
      StreamController<CameraPreviewState>.broadcast();
  final Completer<Result<void>> _opening = Completer<Result<void>>();

  @override
  Stream<CameraPreviewState> get previewState => _states.stream;

  @override
  Size get previewSize => Size.zero;

  @override
  CameraFlashMode get flashMode => CameraFlashMode.off;

  @override
  bool get gridEnabled => false;

  @override
  double get zoom => 1;

  @override
  double get minZoom => 1;

  @override
  double get maxZoom => 1;

  @override
  Future<Result<void>> start() {
    calls.add('start');
    _states.add(CameraPreviewState.starting);
    return _opening.future;
  }

  @override
  Future<Result<void>> stop() async {
    calls.add('stop');
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> pause() async {
    calls.add('pause');
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> resume() {
    calls.add('resume');
    return _opening.future;
  }

  @override
  Future<Result<Uint8List>> takePicture() async {
    return const FailureResult<Uint8List>(
      ProviderFailure(message: Copy.photoNoCamera),
    );
  }

  @override
  Future<CameraFlashMode> cycleFlash() async => CameraFlashMode.off;

  @override
  Future<void> setFlash(CameraFlashMode mode) async {}

  @override
  Future<void> focusAt(double x, double y) async {}

  @override
  Future<double> setZoom(double factor) async => 1;

  @override
  Future<void> setGridEnabled(bool enabled) async {}
}

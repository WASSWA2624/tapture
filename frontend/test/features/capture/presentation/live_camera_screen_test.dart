import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/camera/camera.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/feedback/haptics.dart';
import 'package:tapture/core/permissions/permissions_service.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/camera_view.dart';
import 'package:tapture/features/capture/presentation/live_camera_screen.dart';
import 'package:tapture/features/projects/projects.dart'
    show projectSettingsStoreProvider;
import 'package:tapture/features/settings/settings.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/pump_app.dart';

void main() {
  testWidgets('the shutter hands the shot on and waits for it to be written', (
    WidgetTester tester,
  ) async {
    final Uint8List frame = Uint8List.fromList(<int>[1, 2, 3]);
    final Completer<Result<PhotoDraft>> writing =
        Completer<Result<PhotoDraft>>();
    final List<Uint8List> written = <Uint8List>[];
    final List<String> played = <String>[];

    await _open(
      tester,
      CameraService.fake(pictureBytes: frame),
      onCaptured: (Uint8List bytes) {
        written.add(bytes);
        return writing.future;
      },
      haptics: Haptics.fake(played: played),
    );

    await tester.tap(_shutter);
    await tester.pump();

    expect(written, <Uint8List>[frame]);
    expect(_shutterAction(tester).busy, isTrue);
    expect(played, isEmpty);

    writing.complete(Success<PhotoDraft>(_photo('a')));
    await tester.pump();
    await tester.pump();

    expect(_shutterAction(tester).busy, isFalse);
    expect(_shutterAction(tester).onPressed, isNotNull);
    expect(played, <String>['shutter']);
  });

  testWidgets('a failed shot says why and writes nothing', (
    WidgetTester tester,
  ) async {
    final List<Uint8List> written = <Uint8List>[];
    await _open(
      tester,
      CameraService.fake(
        takeFailure: ProviderFailure(message: Copy.photoNoCamera),
      ),
      onCaptured: (Uint8List bytes) async {
        written.add(bytes);
        return Success<PhotoDraft>(_photo('a'));
      },
    );

    await tester.tap(_shutter);
    await tester.pumpAndSettle();

    expect(find.text(Copy.photoNoCamera), findsOneWidget);
    expect(written, isEmpty);
    expect(_shutterAction(tester).onPressed, isNotNull);
  });

  testWidgets(
    'a failed write shows the error snack and keeps the screen open',
    (WidgetTester tester) async {
      const String full = 'The device is full.';
      int calls = 0;
      await _open(
        tester,
        CameraService.fake(),
        onCaptured: (Uint8List _) async {
          calls++;
          if (calls == 1) {
            return const FailureResult<PhotoDraft>(
              StorageFailure(message: full),
            );
          }
          throw StateError('disk went away');
        },
      );

      await tester.tap(_shutter);
      await tester.pumpAndSettle();

      expect(find.text(full), findsOneWidget);
      expect(find.byType(LiveCameraScreen), findsOneWidget);
      expect(_shutterAction(tester).onPressed, isNotNull);

      tester
          .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
          .hideCurrentSnackBar();
      await tester.pumpAndSettle();
      await tester.tap(_shutter);
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(find.byType(LiveCameraScreen), findsOneWidget);
      expect(_shutterAction(tester).busy, isFalse);
    },
  );

  testWidgets('turning the grid on draws it over the preview', (
    WidgetTester tester,
  ) async {
    await _open(tester, CameraService.fake());
    final Finder grid = find.descendant(
      of: find.byType(CameraView),
      matching: find.byType(CustomPaint),
    );
    expect(grid, findsNothing);

    await tester.tap(find.widgetWithText(AppButton, Copy.captureGrid));
    await tester.pumpAndSettle();

    expect(grid, findsOneWidget);
    expect(_selected(tester, Copy.captureGrid), isTrue);
  });

  testWidgets('going inactive while the camera is still opening leaves the '
      'open running', (WidgetTester tester) async {
    final _OpeningCamera camera = _OpeningCamera();
    await _open(tester, camera, settle: false);

    // The first-run permission prompt makes the app inactive, then resumed.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(camera.calls, <String>['start', 'resume']);
    expect(find.byType(AppSkeleton), findsOneWidget);
  });

  testWidgets('going inactive releases a running preview and resuming '
      'opens it again', (WidgetTester tester) async {
    await _open(tester, CameraService.fake());
    expect(find.byKey(CameraView.previewKey), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppSkeleton), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(CameraView.previewKey), findsOneWidget);
  });

  testWidgets('paused then resumed reopens the preview', (
    WidgetTester tester,
  ) async {
    await _open(tester, CameraService.fake());

    for (final AppLifecycleState state in <AppLifecycleState>[
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }
    await tester.pump();
    expect(find.byKey(CameraView.previewKey), findsNothing);
    expect(find.byType(AppSkeleton), findsOneWidget);

    for (final AppLifecycleState state in <AppLifecycleState>[
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }
    await tester.pump();
    expect(find.byKey(CameraView.previewKey), findsOneWidget);
  });

  testWidgets('resume shows the starting placeholder until running', (
    WidgetTester tester,
  ) async {
    final _OpeningCamera camera = _OpeningCamera();
    await _open(tester, camera, settle: false);
    camera.finishOpening();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(CameraView.previewKey), findsOneWidget);

    camera.reopenSlowly();
    for (final AppLifecycleState state in <AppLifecycleState>[
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }
    expect(find.byType(AppSkeleton), findsOneWidget);
    expect(find.byKey(CameraView.previewKey), findsNothing);

    camera.finishOpening();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(CameraView.previewKey), findsOneWidget);
  });

  testWidgets('closing the screen while the camera is starting stops and '
      'releases it', (WidgetTester tester) async {
    final _OpeningCamera camera = _OpeningCamera();
    await pumpApp(
      tester,
      Builder(
        builder: (BuildContext context) => Center(
          child: AppButton(
            label: Copy.captureTakePhoto,
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => _screen(camera)),
            ),
          ),
        ),
      ),
      overrides: _overrides(),
    );
    await tester.tap(find.text(Copy.captureTakePhoto));
    await tester.pumpAndSettle();
    expect(camera.calls, <String>['start']);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(LiveCameraScreen), findsNothing);
    expect(camera.calls, <String>['start', 'stop']);
  });

  testWidgets('an unavailable camera shows the no-camera message', (
    WidgetTester tester,
  ) async {
    await _open(tester, const CameraService.unavailable());

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(Copy.photoNoCamera), findsOneWidget);
    expect(_shutterAction(tester).onPressed, isNull);
  });

  testWidgets('a refused camera shows its reason and can try again', (
    WidgetTester tester,
  ) async {
    final PermissionFailure refused = PermissionFailure(
      message: Copy.photoNoCamera,
      recoveryAction: Copy.barcodeAllowCamera,
    );
    await _open(tester, CameraService.fake(startFailure: refused));

    final AppErrorState error = tester.widget<AppErrorState>(
      find.byType(AppErrorState),
    );
    expect(error.failure, refused);
    expect(find.text(Copy.photoNoCamera), findsOneWidget);
    expect(find.text(Copy.tryAgain), findsOneWidget);
  });

  testWidgets('a denied camera explains why before the system asks', (
    WidgetTester tester,
  ) async {
    final _OpeningCamera camera = _OpeningCamera();
    await _open(
      tester,
      camera,
      permission: PermissionState.denied,
      settle: false,
    );
    await tester.pump();

    expect(find.text(Copy.captureCameraReason), findsOneWidget);
    expect(find.byType(AppPrimaryAction), findsNothing);
    expect(camera.calls, isEmpty);

    await tester.tap(find.text(Copy.captureAllowCamera));
    await tester.pump();

    expect(camera.calls, <String>['start']);
    expect(find.byType(AppPrimaryAction), findsOneWidget);
  });

  testWidgets('returning from the settings page with the camera allowed '
      'opens it', (WidgetTester tester) async {
    final _SettingsPermissions permissions = _SettingsPermissions();
    await pumpApp(
      tester,
      _screen(CameraService.fake()),
      overrides: <Override>[
        permissionsServiceProvider.overrideWithValue(permissions),
        hapticsProvider.overrideWithValue(Haptics.fake(played: <String>[])),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text(Copy.captureCameraReason), findsOneWidget);

    await tester.tap(find.text(Copy.captureOpenCameraSettings));
    await tester.pumpAndSettle();
    expect(permissions.settingsOpened, 1);
    expect(find.byType(AppPrimaryAction), findsNothing);

    // The operator allows the camera in settings and comes back.
    permissions.camera = PermissionState.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text(Copy.captureCameraReason), findsNothing);
    expect(find.byType(AppPrimaryAction), findsOneWidget);
    expect(find.byKey(CameraView.previewKey), findsOneWidget);
  });

  testWidgets('a portrait surface gives a portrait preview box', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _open(tester, CameraService.fake());

    final Size box = tester.getSize(find.byKey(CameraView.previewKey));
    expect(box.height, greaterThan(box.width));

    tester.view.physicalSize = const Size(800, 400);
    await tester.pumpAndSettle();
    final Size landscape = tester.getSize(find.byKey(CameraView.previewKey));
    expect(landscape.width, greaterThan(landscape.height));
  });

  testWidgets('flash, zoom and grid survive closing and reopening the camera', (
    WidgetTester tester,
  ) async {
    final CameraService camera = CameraService.fake();
    final SettingsStore settings = SettingsStore.fake();
    await _open(tester, camera, settings: settings);

    await tester.tap(find.widgetWithText(AppButton, Copy.captureFlashOff));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, Copy.captureGrid));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, Copy.captureZoomIn));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(AppButton, Copy.captureFlashAuto),
      findsOneWidget,
    );

    // Leave the camera, then open it again on the same device.
    await tester.pumpWidget(const SizedBox.shrink());
    await _open(tester, camera, settings: settings);

    expect(
      find.widgetWithText(AppButton, Copy.captureFlashAuto),
      findsOneWidget,
    );
    expect(_selected(tester, Copy.captureGrid), isTrue);
    expect(camera.zoom, 1 + 0.5);
    expect(settings.read(SettingKeys.flash), CameraFlashMode.auto.name);
    expect(settings.read(SettingKeys.grid), isTrue);

    // A fresh camera after a restart takes the remembered flash.
    final CameraService restarted = CameraService.fake();
    await tester.pumpWidget(const SizedBox.shrink());
    await _open(tester, restarted, settings: settings);
    expect(restarted.flashMode, CameraFlashMode.auto);
    expect(
      find.widgetWithText(AppButton, Copy.captureFlashAuto),
      findsOneWidget,
    );
  });

  testWidgets('camera controls are 48dp, labelled and pass a11y in the '
      'outdoor theme', (WidgetTester tester) async {
    await _open(tester, CameraService.fake(), outdoor: true);

    for (final String label in <String>[
      Copy.captureFlashOff,
      Copy.captureGrid,
      Copy.captureZoomOut,
      Copy.captureZoomIn,
      Copy.captureDocumentMode,
    ]) {
      final Finder control = find.widgetWithText(AppButton, label);
      expect(control, meetsTapTarget(), reason: label);
      expect(control, hasSemanticLabel(label), reason: label);
    }
    expect(_shutter, meetsTapTarget());
    await expectNoA11yIssues(tester);
  });

  testWidgets('a dark shot offers keep and retake and stays in the tray', (
    WidgetTester tester,
  ) async {
    final List<PhotoDraft> tray = <PhotoDraft>[];
    final List<PhotoDraft> retaken = <PhotoDraft>[];
    await _open(
      tester,
      CameraService.fake(pictureBytes: _fixture('dark')),
      onCaptured: (Uint8List _) async {
        final PhotoDraft photo = _photo('dark');
        tray.add(photo);
        return Success<PhotoDraft>(photo);
      },
      onRetake: (PhotoDraft photo) async {
        retaken.add(photo);
        return const Success<void>(null);
      },
    );

    await tester.tap(_shutter);
    await _settle(tester, until: find.text(Copy.captureQualityDark));

    expect(find.text(Copy.captureQualityDark), findsOneWidget);
    expect(find.text(Copy.captureKeepPhoto), findsOneWidget);
    expect(find.text(Copy.captureRetakePhoto), findsOneWidget);
    expect(tray.map((PhotoDraft photo) => photo.id), <String>['dark']);
    expect(_shutterAction(tester).onPressed, isNotNull);

    await tester.tap(find.text(Copy.captureKeepPhoto));
    await tester.pump();
    expect(find.text(Copy.captureQualityDark), findsNothing);
    expect(retaken, isEmpty);
    expect(tray, hasLength(1));

    await tester.tap(_shutter);
    await _settle(tester, until: find.text(Copy.captureRetakePhoto));
    await tester.tap(find.text(Copy.captureRetakePhoto));
    await tester.pump();
    expect(retaken.single.id, 'dark');
    expect(find.text(Copy.captureQualityDark), findsNothing);
  });

  testWidgets('document mode offers the straightened copy beside the '
      'original', (WidgetTester tester) async {
    final List<({PhotoDraft original, PhotoDraft corrected})> stored =
        <({PhotoDraft original, PhotoDraft corrected})>[];
    await _open(
      tester,
      CameraService.fake(pictureBytes: _pageOnDesk()),
      onCaptured: (Uint8List _) async => Success<PhotoDraft>(_photo('page')),
      onCorrected: (PhotoDraft original, PhotoDraft corrected, Uint8List _) {
        stored.add((original: original, corrected: corrected));
        return Future<bool>.value(true);
      },
    );

    await tester.tap(find.widgetWithText(AppButton, Copy.captureDocumentMode));
    await tester.pump();
    await tester.tap(_shutter);
    await _settle(tester, until: find.text(Copy.captureUseCorrected));

    expect(find.text(Copy.capturePageBoundaryFound), findsOneWidget);
    await tester.tap(find.text(Copy.captureUseCorrected));
    await tester.pump();

    expect(stored.single.original.id, 'page');
    expect(stored.single.corrected.derivedFrom, 'page');
    expect(stored.single.corrected.id, isNot('page'));
    expect(stored.single.corrected.relativePath, startsWith('photos/'));
    expect(find.text(Copy.capturePageBoundaryFound), findsNothing);
  });

  testWidgets('document mode without a page captures normally and says so', (
    WidgetTester tester,
  ) async {
    final List<PhotoDraft> tray = <PhotoDraft>[];
    await _open(
      tester,
      CameraService.fake(pictureBytes: _fixture('clean')),
      onCaptured: (Uint8List _) async {
        tray.add(_photo('plain'));
        return Success<PhotoDraft>(tray.last);
      },
    );

    await tester.tap(find.widgetWithText(AppButton, Copy.captureDocumentMode));
    await tester.pump();
    await tester.tap(_shutter);
    await _settle(tester, until: find.text(Copy.captureNoPageBoundary));

    expect(find.text(Copy.captureNoPageBoundary), findsOneWidget);
    expect(tray, hasLength(1));
    expect(_shutterAction(tester).onPressed, isNotNull);
  });
}

Future<void> _open(
  WidgetTester tester,
  CameraService camera, {
  Future<Result<PhotoDraft>> Function(Uint8List bytes)? onCaptured,
  Future<Result<void>> Function(PhotoDraft photo)? onRetake,
  Future<bool> Function(PhotoDraft, PhotoDraft, Uint8List)? onCorrected,
  PermissionState permission = PermissionState.granted,
  Haptics? haptics,
  SettingsStore? settings,
  bool outdoor = false,
  bool settle = true,
}) async {
  await pumpApp(
    tester,
    _screen(
      camera,
      onCaptured: onCaptured,
      onRetake: onRetake,
      onCorrected: onCorrected,
    ),
    outdoor: outdoor,
    overrides: _overrides(
      permission: permission,
      haptics: haptics,
      settings: settings,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

LiveCameraScreen _screen(
  CameraService camera, {
  Future<Result<PhotoDraft>> Function(Uint8List bytes)? onCaptured,
  Future<Result<void>> Function(PhotoDraft photo)? onRetake,
  Future<bool> Function(PhotoDraft, PhotoDraft, Uint8List)? onCorrected,
}) {
  return LiveCameraScreen(
    camera: camera,
    onCaptured:
        onCaptured ??
        (Uint8List _) async => Success<PhotoDraft>(_photo('shot')),
    onRetake: onRetake ?? (PhotoDraft _) async => const Success<void>(null),
    onCorrected:
        onCorrected ??
        (PhotoDraft _, PhotoDraft _, Uint8List _) => Future<bool>.value(true),
  );
}

List<Override> _overrides({
  PermissionState permission = PermissionState.granted,
  Haptics? haptics,
  SettingsStore? settings,
}) {
  return <Override>[
    permissionsServiceProvider.overrideWithValue(
      PermissionsService.fake(
        states: <AppPermission, PermissionState>{
          AppPermission.camera: permission,
        },
      ),
    ),
    hapticsProvider.overrideWithValue(
      haptics ?? Haptics.fake(played: <String>[]),
    ),
    if (settings != null)
      projectSettingsStoreProvider.overrideWithValue(settings),
  ];
}

/// Pumps real time for the isolate runner, then a frame, until [until] is
/// on screen.
Future<void> _settle(WidgetTester tester, {required Finder until}) async {
  for (int attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    if (until.evaluate().isNotEmpty) {
      return;
    }
  }
}

PhotoDraft _photo(String id) {
  return PhotoDraft(
    id: id,
    projectId: 'p1',
    relativePath: 'photos/$id.jpg',
    sha256: 'sha-$id',
  );
}

Uint8List _fixture(String name) {
  final img.Image shot = img.Image(width: 256, height: 192);
  for (int y = 0; y < shot.height; y++) {
    for (int x = 0; x < shot.width; x++) {
      final int level = name == 'dark'
          ? 20
          : ((x ~/ 16 + y ~/ 16).isEven ? 90 : 160);
      shot.setPixelRgb(x, y, level, level, level);
    }
  }
  return img.encodePng(shot);
}

/// A tilted light page on a dark desk.
Uint8List _pageOnDesk() {
  final img.Image desk = img.Image(width: 480, height: 360)
    ..clear(img.ColorRgb8(40, 38, 36));
  img.fillPolygon(
    desk,
    vertices: <img.Point>[
      img.Point(120, 50),
      img.Point(390, 80),
      img.Point(365, 310),
      img.Point(95, 285),
    ],
    color: img.ColorRgb8(235, 235, 230),
  );
  return img.encodeJpg(desk, quality: 92);
}

final Finder _shutter = find.widgetWithText(
  AppPrimaryAction,
  Copy.captureTakePhoto,
);

AppPrimaryAction _shutterAction(WidgetTester tester) {
  return tester.widget<AppPrimaryAction>(_shutter);
}

bool _selected(WidgetTester tester, String label) {
  return tester
      .widget<Semantics>(
        find.ancestor(
          of: find.widgetWithText(AppButton, label),
          matching: find.byWidgetPredicate(
            (Widget widget) =>
                widget is Semantics && widget.properties.toggled != null,
          ),
        ),
      )
      .properties
      .toggled!;
}

/// A camera whose open waits, as it does behind the permission prompt. It
/// records what the view asks of it.
/// Camera permission that stays refused until the test allows it, as the
/// settings page does.
final class _SettingsPermissions implements PermissionsService {
  PermissionState camera = PermissionState.permanentlyDenied;
  int settingsOpened = 0;

  @override
  Future<PermissionState> status(AppPermission permission) async => camera;

  @override
  Future<Result<PermissionState>> request(AppPermission permission) async {
    if (camera == PermissionState.granted) {
      return const Success<PermissionState>(PermissionState.granted);
    }
    settingsOpened++;
    return FailureResult<PermissionState>(
      PermissionFailure(message: Copy.captureCameraReason),
    );
  }
}

final class _OpeningCamera implements CameraService {
  final List<String> calls = <String>[];
  final StreamController<CameraPreviewState> _states =
      StreamController<CameraPreviewState>.broadcast();
  Completer<Result<void>> _opening = Completer<Result<void>>();

  /// Lets the waiting open finish with a running preview.
  void finishOpening() {
    _states.add(CameraPreviewState.running);
    _opening.complete(const Success<void>(null));
  }

  /// Makes the next open wait again.
  void reopenSlowly() {
    _opening = Completer<Result<void>>();
  }

  @override
  Stream<CameraPreviewState> get previewState => _states.stream;

  @override
  Size get previewSize => const Size(1280, 720);

  @override
  CameraFlashMode get flashMode => CameraFlashMode.off;

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
    _states.add(CameraPreviewState.starting);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> resume() {
    calls.add('resume');
    _states.add(CameraPreviewState.starting);
    return _opening.future;
  }

  @override
  Future<Result<Uint8List>> takePicture() async {
    return FailureResult<Uint8List>(
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
}

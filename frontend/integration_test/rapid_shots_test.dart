import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/camera/camera.dart';
import 'package:tapture/core/db/app_database.dart' hide CaptureSession;
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/feedback/haptics.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/data/drift_capture_persistence.dart';
import 'package:tapture/features/capture/data/drift_photo_repository.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/capture/presentation/live_camera_controller.dart';
import 'package:tapture/features/capture/presentation/live_camera_state.dart';

import '../test/support/factories.dart';
import '../test/support/fakes/fake_id_service.dart';
import '../test/support/matchers.dart';

/// Task 012: ten shots in a row, each written through the capture session
/// before the shutter takes the next (§22.1).
void main() {
  test('ten rapid shots produce ten files and ten rows with distinct hashes '
      'and correct order', () async {
    final AppDatabase db = await seededDatabase();
    addTearDown(db.close);
    final Directory root = await Directory.systemTemp.createTemp(
      'tapture-rapid-shots-',
    );
    addTearDown(() => root.delete(recursive: true));
    final Project project = await db.select(db.projects).getSingle();
    final StorageRoot storage = StorageRoot.fake(documentsDirectory: root);
    final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 29, 9));
    final DriftPhotoRepository photos = DriftPhotoRepository(
      db: db,
      writer: FileWriter(storageRoot: storage),
      reader: FileReader(storageRoot: storage),
      clock: clock,
      deviceId: 'device-a',
      ids: FakeIdService(prefix: 'row'),
      storageRoot: storage,
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        photoRepositoryProvider.overrideWithValue(photos),
        capturePersistenceProvider.overrideWithValue(
          DriftCapturePersistence(
            db: db,
            photos: photos,
            clock: clock,
            deviceId: 'device-a',
            ids: FakeIdService(prefix: 'change'),
          ),
        ),
        hapticsProvider.overrideWithValue(Haptics.fake(played: <String>[])),
      ],
    );
    addTearDown(container.dispose);
    final _FrameCamera camera = _FrameCamera();
    final ProviderSubscription<LiveCameraState> open = container.listen(
      liveCameraControllerProvider(camera),
      (LiveCameraState? _, LiveCameraState _) {},
    );
    addTearDown(open.close);
    final LiveCameraController shutter = container.read(
      liveCameraControllerProvider(camera).notifier,
    );
    final CaptureController capture = container.read(
      captureControllerProvider(project.id).notifier,
    );

    for (int index = 0; index < 10; index++) {
      final Result<void> shot = await shutter.shoot((Uint8List bytes) async {
        final PhotoDraft draft = PhotoDraft(
          id: 'shot-$index',
          projectId: project.id,
          captureSessionId: container
              .read(captureControllerProvider(project.id))
              .id,
          relativePath: 'photos/shot-$index.jpg',
          storedFilename: 'shot-$index.jpg',
          sha256: '',
          sortOrder: index,
        );
        final Result<void> added = await capture.addPhoto(draft, bytes: bytes);
        return added.map((_) => draft);
      });
      expect(shot, isA<Success<void>>(), reason: 'shot $index');
    }

    final CaptureSession session = container.read(
      captureControllerProvider(project.id),
    );
    expect(session.photos.map((PhotoDraft photo) => photo.id), <String>[
      for (int index = 0; index < 10; index++) 'shot-$index',
    ]);
    final List<Photo> rows = (await db.select(db.photos).get())
      ..sort((Photo a, Photo b) => a.sortOrder.compareTo(b.sortOrder));
    expect(rows, hasLength(10));
    expect(rows.map((Photo row) => row.sortOrder), <int>[
      for (int index = 0; index < 10; index++) index,
    ]);
    expect(rows.map((Photo row) => row.sha256).toSet(), hasLength(10));
    final String projectFolder =
        '${valueOf(await storage.resolve()).path}/projects/'
        '${project.folderName}';
    final List<File> files = Directory(
      '$projectFolder/photos',
    ).listSync().whereType<File>().toList();
    expect(files, hasLength(10));
    for (final Photo row in rows) {
      final File file = File('$projectFolder/${row.relativePath}');
      expect(sha256.convert(file.readAsBytesSync()).toString(), row.sha256);
    }
  });
}

/// A camera whose every shot is a different frame, as a real one is.
final class _FrameCamera implements CameraService {
  final CameraService _preview = CameraService.fake();
  int _frames = 0;

  @override
  Future<Result<Uint8List>> takePicture() async {
    _frames++;
    return Success<Uint8List>(
      Uint8List.fromList(<int>[
        0xFF,
        0xD8,
        for (int i = 0; i < 4096; i++) (i * _frames) & 0xFF,
      ]),
    );
  }

  @override
  Stream<CameraPreviewState> get previewState => _preview.previewState;
  @override
  Size get previewSize => _preview.previewSize;
  @override
  CameraFlashMode get flashMode => _preview.flashMode;
  @override
  double get zoom => _preview.zoom;
  @override
  double get minZoom => _preview.minZoom;
  @override
  double get maxZoom => _preview.maxZoom;
  @override
  Future<Result<void>> start() => _preview.start();
  @override
  Future<Result<void>> stop() => _preview.stop();
  @override
  Future<Result<void>> pause() => _preview.pause();
  @override
  Future<Result<void>> resume() => _preview.resume();
  @override
  Future<CameraFlashMode> cycleFlash() => _preview.cycleFlash();
  @override
  Future<void> setFlash(CameraFlashMode mode) => _preview.setFlash(mode);
  @override
  Future<void> focusAt(double x, double y) => _preview.focusAt(x, y);
  @override
  Future<double> setZoom(double factor) => _preview.setZoom(factor);
}

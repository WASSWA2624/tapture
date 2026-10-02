import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/camera/camera_preview_surface.dart';
import 'package:tapture/core/camera/camera_service.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/permissions/permissions_service.dart';
import 'package:tapture/features/capture/capture.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart'
    show CaptureController;
import 'package:tapture/features/capture/presentation/capture_headroom.dart';
import 'package:tapture/features/capture/presentation/capture_photo_intake.dart';
import 'package:tapture/features/capture/presentation/live_camera_controller.dart';
import 'package:tapture/features/capture/presentation/live_camera_state.dart';
import 'package:tapture/features/projects/projects.dart' show Project;

/// Measures real camera shutter through durable photo and capture-session writes.
Future<Map<String, Object?>> measureDeviceShutter(
  WidgetTester tester, {
  required ProviderContainer container,
  required sqlite.AppDatabase database,
  required Project project,
  required String templateId,
  required StorageRoot root,
}) async {
  final PermissionState permission = await container
      .read(permissionsServiceProvider)
      .status(AppPermission.camera);
  if (permission != PermissionState.granted) {
    throw TestFailure(
      'Device setup required: grant Camera through Tapture’s camera rationale before the opt-in run. Current state: ${permission.name}.',
    );
  }
  final CameraService camera = container.read(cameraServiceProvider);
  if (camera is! CameraPreviewSurface) {
    throw TestFailure(
      'Device setup required: a real Android/iOS preview camera.',
    );
  }
  WidgetRef? captureRef;
  final OverlayEntry overlay = OverlayEntry(
    builder: (_) => Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        captureRef = ref;
        return const SizedBox.shrink();
      },
    ),
  );
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .overlay!
      .insert(overlay);
  final cameraListener = container.listen<LiveCameraState>(
    liveCameraControllerProvider(camera),
    (_, _) {},
  );
  final captureListener = container.listen<CaptureSession>(
    captureControllerProvider(project.id),
    (_, _) {},
  );
  final headroomListener = container.listen<CaptureHeadroomView>(
    captureHeadroomProvider,
    (_, _) {},
  );
  try {
    await tester.pump();
    final LiveCameraController live = container.read(
      liveCameraControllerProvider(camera).notifier,
    );
    await live.start();
    expect(
      container.read(liveCameraControllerProvider(camera)).preview,
      CameraPreviewState.running,
    );
    final CaptureController capture = container.read(
      captureControllerProvider(project.id).notifier,
    );
    (await capture.setTemplate(templateId, version: 1)).getOrThrow();
    (await capture.setValue('serial', 'metric-camera')).getOrThrow();
    final admitted = await CapturePhotoIntake.admit(captureRef!);
    admitted?.getOrThrow();
    PhotoDraft? stored;
    final Stopwatch timer = Stopwatch()..start();
    (await live.shoot((Uint8List bytes) async {
      final result = await CapturePhotoIntake.store(
        captureRef!,
        sessionKey: project.id,
        projectId: project.id,
        bytes: bytes,
      );
      stored = result.getOrThrow();
      return result;
    })).getOrThrow();
    timer.stop();
    final PhotoDraft photo =
        stored ?? (throw TestFailure('The real shutter produced no photo.'));
    final sqlite.Photo row = await (database.select(
      database.photos,
    )..where((p) => p.id.equals(photo.id))).getSingle();
    final String path = 'projects/${project.folderName}/${row.relativePath}';
    final Uint8List persisted = (await FileReader(
      storageRoot: root,
    ).read(path)).getOrThrow();
    expect(persisted.length, row.fileSize);
    expect(sha256.convert(persisted).toString(), row.sha256);
    final CaptureSession? session =
        (await container
                .read(capturePersistenceProvider)
                .loadSession(project.id))
            .getOrThrow();
    expect(session?.photos.map((p) => p.id), contains(photo.id));
    final String recordId = (await capture.saveRaw(
      container.read(captureRecordWriterProvider)!.persist,
    )).getOrThrow();
    return <String, Object?>{
      'metric': 'shutter',
      'milliseconds': timer.elapsedMilliseconds,
      'scope':
          'native takePicture through durable file, photo row and capture-session commit',
      'photoBytes': row.fileSize,
      'recordId': recordId,
    };
  } finally {
    await camera.stop();
    cameraListener.close();
    captureListener.close();
    headroomListener.close();
    overlay.remove();
    overlay.dispose();
    await tester.pump();
  }
}

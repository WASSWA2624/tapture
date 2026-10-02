import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart' hide CaptureSession;
import 'package:tapture/core/feedback/haptics.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_relocation.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/features/capture/data/capture_record_writer.dart';
import 'package:tapture/features/capture/data/drift_capture_persistence.dart';
import 'package:tapture/features/capture/data/drift_photo_repository.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/processing/processing.dart';
import 'package:tapture/features/settings/data/settings_store.dart';

import '../../test/support/matchers.dart';
import 'harness.dart';

/// The capture path as `main` wires it — photo files under a storage root,
/// the Drift session store, the record writer with folder relocation, and
/// the processing queue — over a booted [TestApp]'s database and clock.
final class CaptureRig {
  CaptureRig._(this.app, this.container, this._project, this._documents);

  /// The booted app whose database the rig writes.
  final TestApp app;

  /// The providers capture reads, overridden with the real stores.
  final ProviderContainer container;

  final Directory _project;
  final Directory _documents;
  bool _disposed = false;

  /// Opens the rig. Files land under an owned temporary storage root.
  /// By default test teardown disposes it; measured callers disable that
  /// registration and dispose explicitly before sampling retained memory.
  static Future<CaptureRig> open(
    TestApp app, {
    bool registerTearDown = true,
  }) async {
    final Directory documents = Directory.systemTemp.createTempSync(
      'tapture-it-capture-',
    );
    ProviderContainer? ownedContainer;
    try {
      final StorageRoot storage = StorageRoot.fake(
        documentsDirectory: documents,
      );
      final IdService ids = UuidV7Service.sequence(app.clock);
      final DriftPhotoRepository photos = DriftPhotoRepository(
        db: app.db,
        writer: FileWriter(storageRoot: storage),
        reader: FileReader(storageRoot: storage),
        clock: app.clock,
        deviceId: _device,
        ids: ids,
        storageRoot: storage,
      );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          hapticsProvider.overrideWithValue(Haptics.fake(played: <String>[])),
          captureClockProvider.overrideWithValue(app.clock),
          photoRepositoryProvider.overrideWithValue(photos),
          capturePersistenceProvider.overrideWithValue(
            DriftCapturePersistence(
              db: app.db,
              photos: photos,
              clock: app.clock,
              deviceId: _device,
              ids: ids,
            ),
          ),
          captureRecordWriterProvider.overrideWithValue(
            CaptureRecordWriter(
              db: app.db,
              clock: app.clock,
              deviceId: _device,
              ids: ids,
              operatorName: () => 'Ada',
              relocation: FileRelocation(
                db: app.db,
                storageRoot: storage,
                clock: app.clock,
                deviceId: _device,
                ids: ids,
              ),
            ),
          ),
          processingRepositoryProvider.overrideWithValue(
            ProcessingRepositoryImpl(
              db: app.db,
              clock: app.clock,
              deviceId: _device,
              ids: ids,
              settings: SettingsStore.fake(),
            ),
          ),
        ],
      );
      ownedContainer = container;
      final Project project = await (app.db.select(
        app.db.projects,
      )..where(($ProjectsTable row) => row.id.equals(projectId))).getSingle();
      final Directory root = valueOf(await storage.resolve());
      final CaptureRig rig = CaptureRig._(
        app,
        container,
        Directory('${root.path}/projects/${project.folderName}'),
        documents,
      );
      if (registerTearDown) addTearDown(rig.dispose);
      return rig;
    } on Object {
      ownedContainer?.dispose();
      if (await documents.exists()) await documents.delete(recursive: true);
      rethrow;
    }
  }

  /// The project the harness seeds.
  static const String projectId = 'project-1';

  /// Its template.
  static const String templateId = 'template-1';

  /// The capture of the harness project, as the capture page drives it.
  CaptureController get controller =>
      container.read(captureControllerProvider(projectId).notifier);

  /// The session being captured.
  CaptureSession get session =>
      container.read(captureControllerProvider(projectId));

  /// Takes one photo into the session under [key]: its bytes on disk and a
  /// photos row first, then the tray. Written under `_unfiled` as a shutter
  /// is before any context level is set. Default shot bytes differ; [bytes]
  /// supplies an actual encoded image for media and memory scenarios.
  Future<PhotoDraft> shoot({String key = projectId, Uint8List? bytes}) async {
    final CaptureSession current = container.read(
      captureControllerProvider(key),
    );
    final String id = container.read(captureIdsProvider).newId();
    final PhotoDraft photo = PhotoDraft(
      id: id,
      projectId: current.projectId.isEmpty ? projectId : current.projectId,
      captureSessionId: current.id,
      originalFilename: '$id.jpg',
      storedFilename: '$id.jpg',
      relativePath: 'photos/_unfiled/$id.jpg',
      sha256: '',
      capturedAt: app.clock.nowUtc(),
      sortOrder: current.photos.length,
    );
    valueOf(
      await container
          .read(captureControllerProvider(key).notifier)
          .addPhoto(photo, bytes: bytes ?? Uint8List.fromList(utf8.encode(id))),
    );
    return photo;
  }

  /// The file at [relativePath] inside the project folder.
  File file(String relativePath) => File('${_project.path}/$relativePath');

  /// Closes controller subscriptions and removes the rig's temporary files.
  /// Idempotence lets measured scenarios clean up before their RSS window.
  Future<void> dispose() async {
    if (!_disposed) {
      _disposed = true;
      container.dispose();
    }
    if (await _documents.exists()) await _documents.delete(recursive: true);
  }
}

const String _device = 'device-a';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/data/drift_capture_persistence.dart';
import 'package:tapture/features/capture/data/drift_photo_repository.dart';
import 'package:tapture/features/capture/domain/capture_photo_repository.dart';
import 'package:tapture/features/capture/domain/capture_session.dart'
    as capture;
import 'package:tapture/features/capture/domain/owned_capture_persistence.dart';
import 'package:tapture/features/capture/domain/photo_derivation.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';
import 'package:tapture/features/capture/domain/photo_rotate.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';

import '../../../support/factories.dart';
import '../../../support/fakes/fake_capture_photo_repository.dart';

void main() {
  for (final String inconsistency in const <String>[
    'missing project',
    'different project',
    'capture stored as edit',
    'edit stored as capture',
    'different edit record',
    'empty candidate project',
  ]) {
    test('an owned Drift update refuses $inconsistency without changing '
        'any row', () async {
      final _Store store = await _Store.open();
      final bool editing =
          inconsistency == 'edit stored as capture' ||
          inconsistency == 'different edit record' ||
          inconsistency == 'empty candidate project';
      final capture.CaptureSession session = _ownedSession(
        store.project.id,
      ).copyWith(editing: editing, recordId: 'record-1');
      final capture.CaptureSession sibling = session.copyWith(
        id: 'sibling',
        editing: !editing,
        recordId: 'record-sibling',
      );
      final Map<String, Object?> corrupted = session.toJson();
      switch (inconsistency) {
        case 'missing project':
          corrupted.remove('projectId');
        case 'different project':
          corrupted['projectId'] = 'project-other';
        case 'capture stored as edit':
          corrupted['editing'] = true;
        case 'edit stored as capture':
          corrupted['editing'] = false;
        case 'different edit record':
          corrupted['recordId'] = 'record-other';
        case 'empty candidate project':
          corrupted['projectId'] = '';
      }
      final capture.CaptureSession candidate = session.copyWith(
        projectId: inconsistency == 'empty candidate project'
            ? ''
            : session.projectId,
        values: const <String, Object?>{'inspection': 'OLD'},
      );
      _ok(await store.persistence.saveSession(session));
      _ok(await store.persistence.saveSession(sibling));
      await (store.db.update(
        store.db.captureSessions,
      )..where((row) => row.projectId.equals(session.storageKey))).write(
        CaptureSessionsCompanion(
          payloadJson: Value<String>(jsonEncode(corrupted)),
        ),
      );
      final List<CaptureSession> before = await store.db
          .select(store.db.captureSessions)
          .get();
      expect(
        await store.reopen().saveOwnedSession(
          candidate,
          owner: _owner(session),
        ),
        isA<FailureResult<void>>(),
      );
      expect(await store.db.select(store.db.captureSessions).get(), before);
      expect(
        _ok(await store.reopen().loadSession(sibling.storageKey))?.toJson(),
        sibling.toJson(),
      );
    });
  }

  for (final bool resetsSession in <bool>[true, false]) {
    test('a controller field intent arriving at Drift after '
        '${resetsSession ? 'a confirmed reset' : 'a confirmed template change'} '
        'is refused and stays absent after reopening', () async {
      final _Store store = await _Store.open();
      final _DelayedOwnedPersistence delayed = _DelayedOwnedPersistence(
        store.persistence,
      );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          capturePersistenceProvider.overrideWithValue(delayed),
          captureClockProvider.overrideWithValue(store._clock),
          captureIdsProvider.overrideWithValue(
            UuidV7Service.sequence(store._clock),
          ),
        ],
      );
      addTearDown(container.dispose);
      final CaptureController controller = container.read(
        captureControllerProvider(store.project.id).notifier,
      );
      _ok(await controller.setTemplate('template-1', version: 1));
      final capture.CaptureSession original = controller.state;
      final Future<Result<void>> oldIntent = controller.setValue(
        'inspection',
        'OLD',
        owner: _owner(original),
      );
      await delayed.writeStarted;
      expect(
        _ok(await store.reopen().loadSession(store.project.id))?.toJson(),
        original.toJson(),
      );

      if (resetsSession) {
        _ok(await controller.discardSession());
        expect(controller.state.id, isNot(original.id));
      } else {
        _ok(await controller.setTemplate('template-2', version: 2));
        expect(controller.state.templateId, 'template-2');
        expect(controller.state.templateVersion, 2);
      }
      _ok(await controller.setValue('confirmed', 'CURRENT'));
      final capture.CaptureSession current = controller.state;
      final CaptureSession durable = await store.db
          .select(store.db.captureSessions)
          .getSingle();
      expect(durable.payloadJson, jsonEncode(current.toJson()));

      delayed.releaseWrite();
      expect(await oldIntent, isA<FailureResult<void>>());

      expect(controller.state.toJson(), current.toJson());
      expect(controller.state.values.containsKey('inspection'), isFalse);
      expect(
        await store.db.select(store.db.captureSessions).getSingle(),
        durable,
      );
      expect(
        _ok(await store.reopen().loadSession(store.project.id))?.toJson(),
        current.toJson(),
      );

      final ProviderContainer reopened = ProviderContainer(
        overrides: <Override>[
          capturePersistenceProvider.overrideWithValue(store.reopen()),
          captureClockProvider.overrideWithValue(store._clock),
          captureIdsProvider.overrideWithValue(
            UuidV7Service.sequence(store._clock),
          ),
        ],
      );
      addTearDown(reopened.dispose);
      final CaptureController restored = reopened.read(
        captureControllerProvider(store.project.id).notifier,
      );
      final capture.CaptureSession? recovery = await restored.interrupted();
      expect(recovery?.toJson(), current.toJson());
      _ok(await restored.replaceSession(recovery!));
      expect(restored.state.toJson(), current.toJson());
      expect(restored.state.values.containsKey('inspection'), isFalse);
      expect(
        _ok(await store.reopen().loadSession(store.project.id))?.toJson(),
        current.toJson(),
      );
    });
  }

  for (final int? version in <int?>[null, 0, 7]) {
    test('an owned Drift update preserves its row identity at version '
        '$version', () async {
      final _Store store = await _Store.open();
      final capture.CaptureSession session = _ownedSession(
        store.project.id,
        version: version,
      );
      _ok(await store.persistence.saveSession(session));
      final CaptureSession before = await store.db
          .select(store.db.captureSessions)
          .getSingle();
      final capture.CaptureSession updated = session.copyWith(
        values: const <String, Object?>{'inspection': null, 'count': 3},
        valueSources: const <String, String>{'inspection': 'TYPED'},
      );

      _ok(
        await store.reopen().saveOwnedSession(updated, owner: _owner(session)),
      );

      final CaptureSession after = await store.db
          .select(store.db.captureSessions)
          .getSingle();
      expect(after.id, before.id);
      expect(after.projectId, before.projectId);
      expect(after.createdAt, before.createdAt);
      expect(after.rev, before.rev + 1);
      expect(after.payloadJson, jsonEncode(updated.toJson()));
      expect(
        _ok(await store.reopen().loadSession(session.storageKey))?.toJson(),
        updated.toJson(),
      );
    });
  }

  final List<({String reason, String id, String template, int? version})>
  mismatches = <({String reason, String id, String template, int? version})>[
    (
      reason: 'session id',
      id: 'session-other',
      template: 'template-1',
      version: 7,
    ),
    (
      reason: 'template id',
      id: 'session-1',
      template: 'template-other',
      version: 7,
    ),
    (
      reason: 'template version',
      id: 'session-1',
      template: 'template-1',
      version: 8,
    ),
    (
      reason: 'null version',
      id: 'session-1',
      template: 'template-1',
      version: null,
    ),
  ];
  for (final mismatch in mismatches) {
    test('a Drift owner with a different ${mismatch.reason} cannot '
        'change the durable draft', () async {
      final _Store store = await _Store.open();
      final capture.CaptureSession session = _ownedSession(store.project.id);
      _ok(await store.persistence.saveSession(session));
      final List<CaptureSession> before = await store.db
          .select(store.db.captureSessions)
          .get();

      expect(
        await store.reopen().saveOwnedSession(
          session.copyWith(
            values: const <String, Object?>{'inspection': 'Late'},
          ),
          owner: (
            sessionId: mismatch.id,
            templateId: mismatch.template,
            templateVersion: mismatch.version,
          ),
        ),
        isA<FailureResult<void>>(),
      );

      expect(await store.db.select(store.db.captureSessions).get(), before);
      expect(
        _ok(await store.reopen().loadSession(session.storageKey))?.toJson(),
        session.toJson(),
      );
    });

    test('a Drift candidate with a different ${mismatch.reason} cannot '
        'change the durable draft', () async {
      final _Store store = await _Store.open();
      final capture.CaptureSession session = _ownedSession(store.project.id);
      _ok(await store.persistence.saveSession(session));
      final List<CaptureSession> before = await store.db
          .select(store.db.captureSessions)
          .get();
      final capture.CaptureSession candidate = _ownedSession(
        store.project.id,
        id: mismatch.id,
        template: mismatch.template,
        version: mismatch.version,
      );

      expect(
        await store.reopen().saveOwnedSession(
          candidate,
          owner: _owner(session),
        ),
        isA<FailureResult<void>>(),
      );

      expect(await store.db.select(store.db.captureSessions).get(), before);
    });
  }

  for (final int? storedVersion in <int?>[null, 0]) {
    test('Drift keeps unselected and legacy version ownership distinct '
        'for $storedVersion', () async {
      final _Store store = await _Store.open();
      final capture.CaptureSession session = _ownedSession(
        store.project.id,
        version: storedVersion,
      );
      final int? differentVersion = storedVersion == null ? 0 : null;
      _ok(await store.persistence.saveSession(session));
      final List<CaptureSession> before = await store.db
          .select(store.db.captureSessions)
          .get();

      expect(
        await store.reopen().saveOwnedSession(
          session,
          owner: (
            sessionId: session.id,
            templateId: session.templateId,
            templateVersion: differentVersion,
          ),
        ),
        isA<FailureResult<void>>(),
      );
      expect(await store.db.select(store.db.captureSessions).get(), before);
      expect(
        await store.reopen().saveOwnedSession(
          _ownedSession(store.project.id, version: differentVersion),
          owner: _owner(session),
        ),
        isA<FailureResult<void>>(),
      );
      expect(await store.db.select(store.db.captureSessions).get(), before);
    });
  }

  test('a missing Drift owner cannot recreate a cleared draft', () async {
    final _Store store = await _Store.open();
    final capture.CaptureSession session = _ownedSession(store.project.id);
    final capture.CaptureSession edit = session.copyWith(
      id: 'record-1',
      recordId: 'record-1',
      editing: true,
    );
    _ok(await store.persistence.saveSession(session));
    _ok(await store.persistence.saveSession(edit));
    _ok(await store.reopen().clearSession(session.storageKey));
    final List<CaptureSession> before = await store.db
        .select(store.db.captureSessions)
        .get();

    expect(
      await store.persistence.saveOwnedSession(session, owner: _owner(session)),
      isA<FailureResult<void>>(),
    );

    expect(await store.db.select(store.db.captureSessions).get(), before);
    expect(_ok(await store.reopen().loadSession(session.storageKey)), isNull);
    expect(
      _ok(await store.reopen().loadSession(edit.storageKey))?.toJson(),
      edit.toJson(),
    );
  });

  for (final String corruption in <String>[
    'not JSON',
    '[]',
    '{"id":"session-1","templateId":"template-1","templateVersion":"7"}',
  ]) {
    test('a corrupt Drift owner refuses an update and preserves '
        '$corruption', () async {
      final _Store store = await _Store.open();
      final capture.CaptureSession session = _ownedSession(store.project.id);
      _ok(await store.persistence.saveSession(session));
      await store.db
          .update(store.db.captureSessions)
          .write(
            CaptureSessionsCompanion(payloadJson: Value<String>(corruption)),
          );
      final List<CaptureSession> before = await store.db
          .select(store.db.captureSessions)
          .get();

      expect(
        await store.reopen().saveOwnedSession(session, owner: _owner(session)),
        isA<FailureResult<void>>(),
      );

      expect(await store.db.select(store.db.captureSessions).get(), before);
    });
  }

  test('a project session round-trips through Drift with its photos and '
      'values, and clears', () async {
    final _Store store = await _Store.open();
    final capture.CaptureSession session = capture.CaptureSession(
      id: 'session-1',
      projectId: store.project.id,
      templateId: 'template-1',
      contextSnapshot: const <String, String>{'country': 'Uganda'},
      photos: <PhotoDraft>[
        PhotoDraft(
          id: 'photo-1',
          projectId: store.project.id,
          captureSessionId: 'session-1',
          relativePath: 'photos/_unfiled/photo-1.jpg',
          sha256: 'photo-sha',
          sortOrder: 0,
          rotationDegrees: 90,
        ),
      ],
      captions: const <String, String>{
        '': 'Record note',
        'photo-1': 'Photo note',
      },
      values: const <String, Object?>{'serial': 'SN-42', 'count': 3},
      valueSources: const <String, String>{'serial': 'BARCODE'},
      isDirty: true,
    );

    _ok(await store.persistence.saveSession(session));
    // A new store over the same database, as after a restart.
    final capture.CaptureSession? restored = _ok(
      await store.reopen().loadSession(store.project.id),
    );
    expect(restored?.toJson(), session.toJson());
    expect(restored?.photos.single.rotationDegrees, 90);
    expect(restored?.captions['photo-1'], 'Photo note');
    expect(restored?.values['serial'], 'SN-42');

    _ok(await store.persistence.clearSession(store.project.id));
    expect(_ok(await store.persistence.loadSession(store.project.id)), isNull);
  });

  test('a record edit is stored beside the project new capture', () async {
    final _Store store = await _Store.open();
    final capture.CaptureSession fresh = capture.CaptureSession(
      id: 'session-1',
      projectId: store.project.id,
      templateId: 'template-1',
      contextSnapshot: const <String, String>{},
      captions: const <String, String>{'': 'New capture'},
      isDirty: true,
    );
    final capture.CaptureSession edit = capture.CaptureSession(
      id: 'record-1',
      projectId: store.project.id,
      templateId: 'template-1',
      contextSnapshot: const <String, String>{},
      recordId: 'record-1',
      editing: true,
      captions: const <String, String>{'': 'Edited'},
      isDirty: true,
    );

    _ok(await store.persistence.saveSession(fresh));
    _ok(await store.persistence.saveSession(edit));
    expect(await store.db.select(store.db.captureSessions).get(), hasLength(2));
    expect(
      _ok(await store.persistence.loadSession(store.project.id))?.recordCaption,
      'New capture',
    );
    expect(
      _ok(await store.persistence.loadSession(edit.storageKey))?.recordCaption,
      'Edited',
    );

    _ok(await store.persistence.clearSession(edit.storageKey));
    expect(_ok(await store.persistence.loadSession(edit.storageKey)), isNull);
    expect(
      _ok(await store.persistence.loadSession(store.project.id))?.recordCaption,
      'New capture',
    );
  });

  test('every keystroke is in the stored session before the page is '
      'left', () async {
    final _Store store = await _Store.open();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        capturePersistenceProvider.overrideWith((Ref _) => store.persistence),
      ],
    );
    addTearDown(container.dispose);
    final CaptureController controller = container.read(
      captureControllerProvider(store.project.id).notifier,
    );

    for (final String typed in <String>['P', 'Pu', 'Pum', 'Pump']) {
      _ok(await controller.setCaption(null, typed));
    }
    for (final String typed in <String>['S', 'SN', 'SN-', 'SN-4']) {
      _ok(await controller.setValue('serial', typed));
    }

    // Read from a second store, as a relaunch after a kill would: the
    // controller was never disposed and nothing flushed it.
    final capture.CaptureSession? stored = _ok(
      await store.reopen().loadSession(store.project.id),
    );
    expect(stored?.recordCaption, 'Pump');
    expect(stored?.values['serial'], 'SN-4');
  });

  test('a derived and rotated photo is still active after reload', () async {
    final _Store store = await _Store.open(onDisk: true);
    final DateTime shot = DateTime.utc(2026, 9, 29, 8);
    final PhotoDraft original = PhotoDraft(
      id: 'original',
      projectId: store.project.id,
      captureSessionId: 'session-1',
      originalFilename: 'original.jpg',
      storedFilename: 'original.jpg',
      relativePath: 'photos/_unfiled/original.jpg',
      sha256: '',
      capturedAt: shot,
    );
    final PhotoDraft kept = _ok(
      await store.persistence.savePhoto(
        original,
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
      ),
    );
    final PhotoDraft crop = _ok(
      await store.persistence.savePhoto(
        original.copyWith(
          id: 'crop',
          originalFilename: 'crop.png',
          storedFilename: 'crop.png',
          relativePath: 'photos/_unfiled/crop.png',
          mimeType: 'image/png',
          derivedFrom: 'original',
          capturedAt: shot.add(const Duration(minutes: 1)),
        ),
        bytes: Uint8List.fromList(<int>[9, 9]),
      ),
    );
    // Rotation is metadata written on the crop's own row.
    final PhotoDraft turned = _ok(
      await store.persistence.savePhoto(PhotoRotate.apply(crop, 90)),
    );
    _ok(
      await store.persistence.saveSession(
        capture.CaptureSession(
          id: 'session-1',
          projectId: store.project.id,
          templateId: '',
          contextSnapshot: const <String, String>{},
          photos: <PhotoDraft>[kept, turned],
          isDirty: true,
        ),
      ),
    );

    final capture.CaptureSession? restored = _ok(
      await store.reopen().loadSession(store.project.id),
    );
    final List<PhotoDraft> active = _ok(
      PhotoDerivation.select(restored!.photos),
    );
    expect(active.single.id, 'crop');
    expect(active.single.rotationDegrees, 90);
    expect(active.single.derivedFrom, 'original');
    final Photo row = await (store.db.select(
      store.db.photos,
    )..where((table) => table.id.equals('crop'))).getSingle();
    expect(row.rotationDegrees, 90);
    expect(row.derivedFrom, 'original');
    // The original's bytes are exactly what the shutter wrote.
    expect(_ok(await store.photos.readBytes(restored.photos.first)), <int>[
      1,
      2,
      3,
    ]);
  });
}

/// Holds only the originating field intent before the real Drift owner check.
final class _DelayedOwnedPersistence implements OwnedCapturePersistence {
  _DelayedOwnedPersistence(this._inner);

  final OwnedCapturePersistence _inner;
  final Completer<void> _started = Completer<void>();
  final Completer<void> _release = Completer<void>();

  Future<void> get writeStarted => _started.future;

  void releaseWrite() => _release.complete();

  @override
  PhotoRepository get photos => _inner.photos;

  @override
  Future<Result<PhotoDraft>> savePhoto(PhotoDraft photo, {Uint8List? bytes}) =>
      _inner.savePhoto(photo, bytes: bytes);

  @override
  Future<Result<void>> deletePhoto(String photoId, {required String reason}) =>
      _inner.deletePhoto(photoId, reason: reason);

  @override
  Future<Result<void>> saveSession(capture.CaptureSession session) =>
      _inner.saveSession(session);

  @override
  Future<Result<void>> saveOwnedSession(
    capture.CaptureSession session, {
    required ({String sessionId, String templateId, int? templateVersion})
    owner,
  }) async {
    _started.complete();
    await _release.future;
    return _inner.saveOwnedSession(session, owner: owner);
  }

  @override
  Future<Result<capture.CaptureSession?>> loadSession(String key) =>
      _inner.loadSession(key);

  @override
  Future<Result<void>> clearSession(String key) => _inner.clearSession(key);
}

capture.CaptureSession _ownedSession(
  String projectId, {
  String id = 'session-1',
  String template = 'template-1',
  int? version = 7,
}) => capture.CaptureSession(
  id: id,
  projectId: projectId,
  templateId: template,
  templateVersion: version,
  contextSnapshot: const <String, String>{'country': 'Uganda'},
  captions: const <String, String>{'': 'Original evidence'},
  values: const <String, Object?>{'inspection': 'Before'},
  valueSources: const <String, String>{'inspection': 'TYPED'},
  isDirty: true,
);

({String sessionId, String templateId, int? templateVersion}) _owner(
  capture.CaptureSession session,
) => (
  sessionId: session.id,
  templateId: session.templateId,
  templateVersion: session.templateVersion,
);

/// A capture store over a seeded database, reopened as a relaunch would.
final class _Store {
  _Store._(this.db, this.project, this.photos, this._clock);

  final AppDatabase db;
  final Project project;
  final CapturePhotoRepository photos;
  final FixedClock _clock;

  late final DriftCapturePersistence persistence = reopen();

  /// Opens the store. [onDisk] writes photo files under a temporary root;
  /// otherwise photo rows and bytes stay in a fake.
  static Future<_Store> open({bool onDisk = false}) async {
    final AppDatabase db = await seededDatabase();
    addTearDown(db.close);
    final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 23, 16, 35));
    final Project project = await db.select(db.projects).getSingle();
    final Directory folder = Directory.systemTemp.createTempSync(
      'tapture-capture-store-',
    );
    addTearDown(() => folder.deleteSync(recursive: true));
    final CapturePhotoRepository photos;
    if (onDisk) {
      final StorageRoot storage = StorageRoot.fake(documentsDirectory: folder);
      photos = DriftPhotoRepository(
        db: db,
        writer: FileWriter(storageRoot: storage),
        reader: FileReader(storageRoot: storage),
        clock: clock,
        deviceId: 'device-a',
        ids: UuidV7Service.sequence(clock),
        storageRoot: storage,
      );
    } else {
      photos = FakeCapturePhotoRepository(thumbs: folder);
    }
    return _Store._(db, project, photos, clock);
  }

  /// A fresh store over the same database and files.
  DriftCapturePersistence reopen() {
    return DriftCapturePersistence(
      db: db,
      photos: photos,
      clock: _clock,
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(_clock),
    );
  }
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/features/capture/data/capture_persistence_impl.dart';
import 'package:tapture/features/capture/domain/capture_persistence.dart';
import 'package:tapture/features/capture/domain/capture_record_persistence.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/capture_session_key.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';

import '../../../support/fakes/fake_photo_repository.dart';

void main() {
  late FakePhotoRepository photos;
  late _Tracked sessions;
  late _Records records;
  late ProviderContainer container;
  final String key = CaptureSessionKey.edit('r1');

  setUp(() {
    photos = FakePhotoRepository();
    sessions = _Tracked(
      CapturePersistenceImpl(photos: photos, store: TextStore.memory()),
    );
    records = _Records();
    container = ProviderContainer(
      overrides: <Override>[
        photoRepositoryProvider.overrideWith((Ref _) => photos),
        capturePersistenceProvider.overrideWith((Ref _) => sessions),
        captureRecordWriterProvider.overrideWith((Ref _) => records),
      ],
    );
  });

  tearDown(() {
    photos.dispose();
    container.dispose();
  });

  test('an edit key starts an empty edit of that record', () {
    final CaptureSession session = container.read(
      captureControllerProvider(key),
    );
    expect(session.editing, isTrue);
    expect(session.recordId, 'r1');
    expect(session.storageKey, key);
  });

  test(
    'loadRecord fills the session and stores it under the edit key',
    () async {
      final CaptureController controller = container.read(
        captureControllerProvider(key).notifier,
      );
      _ok(await controller.loadRecord('r1'));

      expect(controller.state.photos.map((PhotoDraft p) => p.id), <String>[
        'f1',
        'f2',
      ]);
      expect(controller.state.captions['f1'], 'Valve');
      final CaptureSession? stored = _ok(await sessions.loadSession(key));
      expect(stored?.recordId, 'r1');
    },
  );

  test('removing a filed photo waits for Save to tombstone it', () async {
    final CaptureController controller = container.read(
      captureControllerProvider(key).notifier,
    );
    _ok(await controller.loadRecord('r1'));

    _ok(await controller.removePhoto('f1'));
    expect(sessions.deleted, isEmpty);
    expect(controller.state.photos.map((PhotoDraft p) => p.id), <String>['f2']);
    expect(controller.state.isDirty, isTrue);

    _ok(await controller.saveEdits());
    expect(records.updates.single.photos.map((PhotoDraft p) => p.id), <String>[
      'f2',
    ]);
    expect(_ok(await sessions.loadSession(key)), isNull);
    expect(controller.state.isDirty, isFalse);
  });

  test('a photo added in an edit stays off the record, and discard drops '
      'only it', () async {
    final CaptureController controller = container.read(
      captureControllerProvider(key).notifier,
    );
    _ok(await controller.loadRecord('r1'));
    final PhotoDraft source = controller.state.photos.first;

    // A crop copies its source, record id included.
    _ok(
      await controller.addPhoto(
        source.copyWith(
          id: 'crop',
          relativePath: 'photos/crop.png',
          sha256: 'crop-sha',
          derivedFrom: source.id,
        ),
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
      ),
    );
    final PhotoDraft crop = controller.state.photos.last;
    expect(crop.id, 'crop');
    expect(crop.recordId, isNull);
    expect(sessions.savedPhotos.last.recordId, isNull);

    _ok(await controller.discardSession());
    expect(sessions.deleted, <String>['crop']);
    expect(controller.state.photos, isEmpty);
    expect(controller.state.editing, isTrue);
    expect(_ok(await sessions.loadSession(key)), isNull);
  });

  test('reverting a filed edit, turning and ordering wait for Save', () async {
    records.derived = true;
    final CaptureController controller = container.read(
      captureControllerProvider(key).notifier,
    );
    _ok(await controller.loadRecord('r1'));
    final int saves = sessions.savedPhotos.length;

    _ok(await controller.revertPhoto('f2'));
    _ok(
      await controller.setPhoto(
        controller.state.photos.first.copyWith(rotationDegrees: 90),
      ),
    );
    _ok(await controller.reorderPhotos(<String>['f1']));
    _ok(await controller.setPhotoType('f1', 'serial'));

    expect(sessions.savedPhotos, hasLength(saves));
    expect(sessions.deleted, isEmpty);
    expect(controller.state.photos.single.rotationDegrees, 90);
    expect(controller.state.photos.single.photoType, 'serial');
  });

  test(
    'the edit and the project new capture keep their own sessions',
    () async {
      final CaptureController fresh = container.read(
        captureControllerProvider('p1').notifier,
      );
      _ok(await fresh.setCaption(null, 'New capture'));
      final CaptureController edit = container.read(
        captureControllerProvider(key).notifier,
      );
      _ok(await edit.loadRecord('r1'));
      _ok(await edit.setCaption(null, 'Edited'));
      _ok(await edit.saveEdits());

      expect(
        _ok(await sessions.loadSession('p1'))?.recordCaption,
        'New capture',
      );
      expect(
        container.read(captureControllerProvider('p1')).recordCaption,
        'New capture',
      );
      expect(records.updates.single.recordCaption, 'Edited');
    },
  );

  test('a failing update keeps every change', () async {
    records.failUpdate = true;
    final CaptureController controller = container.read(
      captureControllerProvider(key).notifier,
    );
    _ok(await controller.loadRecord('r1'));
    _ok(await controller.removePhoto('f1'));

    final Result<void> saved = await controller.saveEdits();

    expect(saved, isA<FailureResult<void>>());
    expect(controller.state.photos.map((PhotoDraft p) => p.id), <String>['f2']);
    expect(controller.state.isDirty, isTrue);
    final CaptureSession? stored = _ok(await sessions.loadSession(key));
    expect(stored?.photos.map((PhotoDraft p) => p.id), <String>['f2']);
  });
}

/// A record store holding record `r1` with two filed photos.
final class _Records implements CaptureRecordPersistence {
  final List<CaptureSession> updates = <CaptureSession>[];
  bool failUpdate = false;

  /// Whether `f2` is a filed crop of `f1`.
  bool derived = false;

  @override
  Future<Result<String>> persist(CaptureSession session) async {
    return Success<String>(session.id);
  }

  @override
  Future<Result<CaptureSession>> load(String recordId) async {
    return Success<CaptureSession>(
      CaptureSession(
        id: recordId,
        projectId: 'p1',
        templateId: 't1',
        contextSnapshot: const <String, String>{'site': 'A'},
        recordId: recordId,
        editing: true,
        photos: <PhotoDraft>[
          PhotoDraft(
            id: 'f1',
            projectId: 'p1',
            recordId: recordId,
            relativePath: 'photos/f1.jpg',
            sha256: 'f1-sha',
            hasCaption: true,
          ),
          PhotoDraft(
            id: 'f2',
            projectId: 'p1',
            recordId: recordId,
            relativePath: 'photos/f2.jpg',
            sha256: 'f2-sha',
            sortOrder: 1,
            derivedFrom: derived ? 'f1' : null,
          ),
        ],
        captions: const <String, String>{'': 'Boiler', 'f1': 'Valve'},
      ),
    );
  }

  @override
  Future<Result<void>> update(CaptureSession edited) async {
    if (failUpdate) {
      return const FailureResult<void>(
        StorageFailure(message: 'The database could not complete that write.'),
      );
    }
    updates.add(edited);
    return const Success<void>(null);
  }
}

/// Session persistence that notes photo writes and deletes.
final class _Tracked implements CapturePersistence {
  _Tracked(this._inner);

  final CapturePersistence _inner;
  final List<String> deleted = <String>[];
  final List<PhotoDraft> savedPhotos = <PhotoDraft>[];

  @override
  PhotoRepository get photos => _inner.photos;

  @override
  Future<Result<PhotoDraft>> savePhoto(
    PhotoDraft photo, {
    Uint8List? bytes,
  }) async {
    savedPhotos.add(photo);
    return Success<PhotoDraft>(photo);
  }

  @override
  Future<Result<void>> deletePhoto(String photoId, {required String reason}) {
    deleted.add(photoId);
    return _inner.deletePhoto(photoId, reason: reason);
  }

  @override
  Future<Result<void>> saveSession(CaptureSession session) =>
      _inner.saveSession(session);

  @override
  Future<Result<CaptureSession?>> loadSession(String key) =>
      _inner.loadSession(key);

  @override
  Future<Result<void>> clearSession(String key) => _inner.clearSession(key);
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

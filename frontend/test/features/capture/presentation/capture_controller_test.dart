import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/features/capture/data/capture_persistence_impl.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/save_and_analyse.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';

import '../../../support/fakes/fake_photo_repository.dart';

void main() {
  late FakePhotoRepository photos;
  late ProviderContainer container;

  setUp(() {
    photos = FakePhotoRepository();
    container = ProviderContainer(
      overrides: <Override>[
        photoRepositoryProvider.overrideWith((Ref _) => photos),
        capturePersistenceProvider.overrideWith(
          (Ref ref) =>
              CapturePersistenceImpl(photos: photos, store: TextStore.memory()),
        ),
      ],
    );
  });

  tearDown(() {
    photos.dispose();
    container.dispose();
  });

  test('addPhoto persists before next state', () async {
    final CaptureController controller = container.read(
      captureControllerProvider('p1').notifier,
    );
    final Result<void> result = await controller.addPhoto(
      const PhotoDraft(
        id: 'ph1',
        projectId: 'p1',
        relativePath: 'photos/a.jpg',
        sha256: 'hash1',
      ),
    );
    expect(result, isA<Success<void>>());
    expect(controller.state.photos, hasLength(1));
    final loaded = await photos.byId('ph1');
    expect(loaded.getOrElse(() => null)?.sha256, 'hash1');
  });

  test('failed write leaves emitted state unchanged', () async {
    final CaptureController controller = container.read(
      captureControllerProvider('p1').notifier,
    );
    final CaptureSession before = controller.state;
    final Result<void> result = await controller.addPhoto(
      const PhotoDraft(id: 'bad', projectId: '', relativePath: '', sha256: 'x'),
    );
    expect(result, isA<FailureResult<void>>());
    expect(controller.state.photos, before.photos);
  });

  test(
    'undo restores the photo in its original position with its caption',
    () async {
      final CaptureController controller = container.read(
        captureControllerProvider('p1').notifier,
      );
      for (int index = 0; index < 3; index++) {
        await controller.addPhoto(
          PhotoDraft(
            id: 'photo-$index',
            projectId: 'p1',
            relativePath: 'photos/$index.jpg',
            sha256: 'hash-$index',
            sortOrder: index,
            photoType: 'nameplate',
          ),
        );
      }
      await controller.setCaption('photo-1', 'The original label');
      final Result<PhotoDraft?> removed = await controller.removePhoto(
        'photo-1',
      );
      expect(
        controller.state.photos.map((PhotoDraft photo) => photo.id),
        <String>['photo-0', 'photo-2'],
      );
      expect(
        await controller.undoRemove((removed as Success<PhotoDraft?>).value!),
        isA<Success<void>>(),
      );
      expect(
        controller.state.photos.map((PhotoDraft photo) => photo.id),
        <String>['photo-0', 'photo-1', 'photo-2'],
      );
      expect(controller.state.captions['photo-1'], 'The original label');
      expect(controller.state.photos[1].photoType, 'nameplate');
    },
  );

  test('incomplete reorder cannot drop photos', () async {
    final CaptureController controller = container.read(
      captureControllerProvider('p1').notifier,
    );
    await controller.addPhoto(
      const PhotoDraft(
        id: 'photo',
        projectId: 'p1',
        relativePath: 'photos/photo.jpg',
        sha256: 'hash',
      ),
    );
    expect(
      await controller.reorderPhotos(const <String>[]),
      isA<FailureResult<void>>(),
    );
    expect(controller.state.photos.single.id, 'photo');
  });

  test('discard failure retains the interrupted recovery session', () async {
    final CaptureController controller = container.read(
      captureControllerProvider('p1').notifier,
    );
    final CaptureSession interrupted = controller.state.copyWith(
      photos: const <PhotoDraft>[
        PhotoDraft(
          id: 'missing-row',
          projectId: 'p1',
          relativePath: 'photos/photo.jpg',
          sha256: 'hash',
        ),
      ],
      captions: const <String, String>{'': 'Preserved draft'},
    );
    await controller.replaceSession(interrupted);
    expect(await controller.discardSession(), isA<FailureResult<void>>());
    expect(controller.state, same(interrupted));
    final CaptureSession? recovery =
        (await container.read(capturePersistenceProvider).loadSession('p1')
                as Success<CaptureSession?>)
            .value;
    expect(recovery?.recordCaption, 'Preserved draft');
  });

  test(
    'enqueue retry reuses the committed record without another raw write',
    () async {
      final CaptureController controller = container.read(
        captureControllerProvider('p1').notifier,
      );
      await controller.addPhoto(
        const PhotoDraft(
          id: 'ph1',
          projectId: 'p1',
          relativePath: 'photos/a.jpg',
          sha256: 'hash1',
        ),
      );
      var persistCalls = 0;
      var enqueueCalls = 0;

      Future<Result<String>> persist(CaptureSession _) async {
        persistCalls += 1;
        return const Success<String>('record-1');
      }

      Future<Result<ProcessingJob>> enqueue(String recordId) async {
        enqueueCalls += 1;
        if (enqueueCalls == 1) {
          return const FailureResult<ProcessingJob>(
            NetworkFailure(message: 'Offline.', recoveryAction: 'Retry.'),
          );
        }
        return Success<ProcessingJob>(
          ProcessingJob(id: 'job-1', recordId: recordId),
        );
      }

      final first = await controller.saveAndAnalyse(
        persist: persist,
        enqueue: enqueue,
      );
      expect(
        (first as Success<SaveAndAnalyseResult>).value.enqueueFailed,
        isTrue,
      );
      expect(controller.state.recordId, 'record-1');
      expect(controller.state.photos, hasLength(1));

      final second = await controller.saveAndAnalyse(
        persist: persist,
        enqueue: enqueue,
      );
      expect(
        (second as Success<SaveAndAnalyseResult>).value.enqueueFailed,
        isFalse,
      );
      expect(persistCalls, 1);
      expect(enqueueCalls, 2);
      expect(controller.state.photos, isEmpty);
      expect(controller.state.recordId, isNull);
    },
  );
}

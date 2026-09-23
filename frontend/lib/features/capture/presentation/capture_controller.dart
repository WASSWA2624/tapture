import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/data/capture_persistence_impl.dart';
import 'package:tapture/features/capture/domain/audio_draft.dart';
import 'package:tapture/features/capture/domain/caption_apply.dart';
import 'package:tapture/features/capture/domain/capture_persistence.dart';
import 'package:tapture/features/capture/domain/capture_reset.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';
import 'package:tapture/features/capture/domain/save_and_analyse.dart';
import 'package:tapture/features/capture/domain/save_raw.dart';
import 'package:tapture/features/processing/processing.dart';

/// Default photo repository stub — [main] / tests override.
final Provider<PhotoRepository> photoRepositoryProvider =
    Provider<PhotoRepository>((Ref _) {
      return _MemoryPhotoRepository();
    });

/// Session + photo persistence. Tests override with a memory store.
final Provider<CapturePersistence> capturePersistenceProvider =
    Provider<CapturePersistence>((Ref ref) {
      return CapturePersistenceImpl(
        photos: ref.watch(photoRepositoryProvider),
        store: TextStore.memory(),
      );
    });

/// Capture session for a project id. Persist before every emit.
final captureControllerProvider =
    NotifierProvider.family<CaptureController, CaptureSession, String>(
      CaptureController.new,
    );

/// Intent methods — the only way the session changes.
final class CaptureController extends Notifier<CaptureSession> {
  /// Creates a controller bound to [projectId] (family argument).
  CaptureController(this.projectId);

  /// Open project id.
  final String projectId;

  CapturePersistence get _persistence => ref.read(capturePersistenceProvider);

  IdService get _ids => UuidV7Service(const SystemClock());

  @override
  CaptureSession build() {
    return CaptureSession(
      id: _ids.newId(),
      projectId: projectId,
      templateId: '',
      contextSnapshot: const <String, String>{},
    );
  }

  /// Seeds or replaces the live session (recovery / tests).
  Future<Result<void>> replaceSession(CaptureSession session) async {
    final Result<void> saved = await _persistence.saveSession(session);
    return saved.fold(FailureResult<void>.new, (_) {
      state = session;
      return const Success<void>(null);
    });
  }

  /// Adds [photo] after durable write.
  Future<Result<void>> addPhoto(PhotoDraft photo, {Uint8List? bytes}) async {
    final Result<PhotoDraft> saved = await _persistence.savePhoto(
      photo,
      bytes: bytes,
    );
    return saved.fold(FailureResult<void>.new, (PhotoDraft stored) async {
      final CaptureSession next = state.copyWith(
        photos: <PhotoDraft>[...state.photos, stored],
        isDirty: true,
      );
      final Result<void> session = await _persistence.saveSession(next);
      return session.fold(FailureResult<void>.new, (_) {
        state = next;
        return const Success<void>(null);
      });
    });
  }

  /// Adds an already-flushed audio clip and persists recovery state before it
  /// appears in the capture session.
  Future<Result<void>> addAudio(AudioDraft clip) async {
    final CaptureSession next = state.copyWith(
      audio: <AudioDraft>[...state.audio, clip],
      isDirty: true,
    );
    final Result<void> saved = await _persistence.saveSession(next);
    return saved.fold(FailureResult<void>.new, (_) {
      state = next;
      return const Success<void>(null);
    });
  }

  /// Removes [photoId] after tombstone; leaves emitted state unchanged on
  /// failure.
  Future<Result<PhotoDraft?>> removePhoto(String photoId) async {
    PhotoDraft? removed;
    for (final PhotoDraft photo in state.photos) {
      if (photo.id == photoId) {
        removed = photo;
        break;
      }
    }
    if (removed == null) {
      return const Success<PhotoDraft?>(null);
    }
    final Result<void> deleted = await _persistence.deletePhoto(
      photoId,
      reason: 'operator-delete',
    );
    return deleted.fold(FailureResult<PhotoDraft?>.new, (_) async {
      final CaptureSession next = state.copyWith(
        photos: state.photos
            .where((PhotoDraft p) => p.id != photoId)
            .toList(growable: false),
        captions: Map<String, String>.of(state.captions)..remove(photoId),
        isDirty: true,
      );
      final Result<void> session = await _persistence.saveSession(next);
      return session.fold(FailureResult<PhotoDraft?>.new, (_) {
        state = next;
        return Success<PhotoDraft?>(removed);
      });
    });
  }

  /// Restores a previously removed photo at its sort position.
  Future<Result<void>> undoRemove(PhotoDraft photo) => addPhoto(photo);

  /// Reorders photos to [orderedIds] and persists immediately.
  Future<Result<void>> reorderPhotos(List<String> orderedIds) async {
    final Map<String, PhotoDraft> byId = <String, PhotoDraft>{
      for (final PhotoDraft photo in state.photos) photo.id: photo,
    };
    final List<PhotoDraft> ordered = <PhotoDraft>[];
    for (var i = 0; i < orderedIds.length; i++) {
      final PhotoDraft? photo = byId[orderedIds[i]];
      if (photo != null) {
        ordered.add(photo.copyWith(sortOrder: i));
      }
    }
    for (final PhotoDraft photo in ordered) {
      final Result<PhotoDraft> saved = await _persistence.savePhoto(photo);
      if (saved is FailureResult<PhotoDraft>) {
        return FailureResult<void>(saved.failure);
      }
    }
    final CaptureSession next = state.copyWith(photos: ordered, isDirty: true);
    final Result<void> session = await _persistence.saveSession(next);
    return session.fold(FailureResult<void>.new, (_) {
      state = next;
      return const Success<void>(null);
    });
  }

  /// Sets caption for [photoId] (`null` / empty id = record caption).
  Future<Result<void>> setCaption(String? photoId, String text) async {
    final String key = photoId ?? '';
    final Map<String, String> captions = Map<String, String>.of(state.captions)
      ..[key] = text;
    List<PhotoDraft> photos = state.photos;
    if (photoId != null && photoId.isNotEmpty) {
      photos = <PhotoDraft>[
        for (final PhotoDraft photo in state.photos)
          photo.id == photoId
              ? photo.copyWith(hasCaption: text.isNotEmpty)
              : photo,
      ];
    }
    final CaptureSession next = state.copyWith(
      captions: captions,
      photos: photos,
      isDirty: true,
    );
    final Result<void> session = await _persistence.saveSession(next);
    return session.fold(FailureResult<void>.new, (_) {
      state = next;
      return const Success<void>(null);
    });
  }

  /// Applies caption writes from [CaptionApply].
  Future<Result<void>> applyCaptions(List<CaptionWrite> writes) async {
    final Map<String, String> captions = Map<String, String>.of(state.captions);
    final Map<String, PhotoDraft> photos = <String, PhotoDraft>{
      for (final PhotoDraft photo in state.photos) photo.id: photo,
    };
    for (final CaptionWrite write in writes) {
      captions[write.photoId] = write.text;
      final PhotoDraft? photo = photos[write.photoId];
      if (photo != null) {
        photos[write.photoId] = photo.copyWith(
          hasCaption: write.text.isNotEmpty,
        );
      }
    }
    final CaptureSession next = state.copyWith(
      captions: captions,
      photos: photos.values.toList(growable: false),
      isDirty: true,
    );
    final Result<void> session = await _persistence.saveSession(next);
    return session.fold(FailureResult<void>.new, (_) {
      state = next;
      return const Success<void>(null);
    });
  }

  /// Sets an inline field value.
  Future<Result<void>> setValue(String fieldKey, Object? value) async {
    final Map<String, Object?> values = Map<String, Object?>.of(state.values)
      ..[fieldKey] = value;
    final CaptureSession next = state.copyWith(values: values, isDirty: true);
    final Result<void> session = await _persistence.saveSession(next);
    return session.fold(FailureResult<void>.new, (_) {
      state = next;
      return const Success<void>(null);
    });
  }

  /// Updates photo type on [photoId].
  Future<Result<void>> setPhotoType(String photoId, String type) async {
    final List<PhotoDraft> photos = <PhotoDraft>[
      for (final PhotoDraft photo in state.photos)
        photo.id == photoId ? photo.copyWith(photoType: type) : photo,
    ];
    for (final PhotoDraft photo in photos) {
      if (photo.id == photoId) {
        final Result<PhotoDraft> saved = await _persistence.savePhoto(photo);
        if (saved is FailureResult<PhotoDraft>) {
          return FailureResult<void>(saved.failure);
        }
      }
    }
    final CaptureSession next = state.copyWith(photos: photos, isDirty: true);
    final Result<void> session = await _persistence.saveSession(next);
    return session.fold(FailureResult<void>.new, (_) {
      state = next;
      return const Success<void>(null);
    });
  }

  /// Updates a photo draft (rotation, crop link, …).
  Future<Result<void>> setPhoto(PhotoDraft photo) async {
    final Result<PhotoDraft> saved = await _persistence.savePhoto(photo);
    return saved.fold(FailureResult<void>.new, (PhotoDraft stored) async {
      final List<PhotoDraft> photos = <PhotoDraft>[
        for (final PhotoDraft row in state.photos)
          row.id == stored.id ? stored : row,
      ];
      final CaptureSession next = state.copyWith(photos: photos, isDirty: true);
      final Result<void> session = await _persistence.saveSession(next);
      return session.fold(FailureResult<void>.new, (_) {
        state = next;
        return const Success<void>(null);
      });
    });
  }

  /// Sets the template for this session.
  Future<Result<void>> setTemplate(String templateId) async {
    final CaptureSession next = state.copyWith(
      templateId: templateId,
      isDirty: true,
    );
    final Result<void> session = await _persistence.saveSession(next);
    return session.fold(FailureResult<void>.new, (_) {
      state = next;
      return const Success<void>(null);
    });
  }

  /// Sets the context snapshot.
  Future<Result<void>> setContext(Map<String, String> snapshot) async {
    final CaptureSession next = state.copyWith(
      contextSnapshot: snapshot,
      isDirty: true,
    );
    final Result<void> session = await _persistence.saveSession(next);
    return session.fold(FailureResult<void>.new, (_) {
      state = next;
      return const Success<void>(null);
    });
  }

  /// Raw save path.
  Future<Result<String>> saveRaw(
    Future<Result<String>> Function(CaptureSession session) persist,
  ) async {
    final String? committedId = state.recordId;
    if (committedId != null) {
      final Result<void> completed = await _completeSave(committedId);
      return completed.map((_) => committedId);
    }
    final Result<String> saved = await SaveRaw.run(
      session: state,
      persist: persist,
    );
    return saved.fold(FailureResult<String>.new, (String recordId) async {
      final Result<void> completed = await _completeSave(recordId);
      return completed.map((_) => recordId);
    });
  }

  /// Save and analyse path.
  Future<Result<SaveAndAnalyseResult>> saveAndAnalyse({
    required Future<Result<String>> Function(CaptureSession session) persist,
    required Future<Result<ProcessingJob>> Function(String recordId) enqueue,
  }) async {
    final Result<SaveAndAnalyseResult> saved = await SaveAndAnalyse.run(
      session: state,
      persist: persist,
      enqueue: enqueue,
    );
    return saved.fold(FailureResult<SaveAndAnalyseResult>.new, (
      SaveAndAnalyseResult result,
    ) async {
      if (result.enqueueFailed) {
        final CaptureSession committed = state.copyWith(
          recordId: result.recordId,
          isDirty: false,
        );
        // The raw record transaction is already durable. Keep that fact in
        // memory even if checkpointing the resumable session fails, so Retry
        // never attempts another raw write in this process.
        state = committed;
        final Result<void> persisted = await _persistence.saveSession(
          committed,
        );
        return persisted.fold(
          FailureResult<SaveAndAnalyseResult>.new,
          (_) => Success<SaveAndAnalyseResult>(result),
        );
      }
      final Result<void> completed = await _completeSave(result.recordId);
      return completed.map((_) => result);
    });
  }

  Future<Result<void>> _completeSave(String recordId) async {
    final CaptureSession committed = state.copyWith(
      recordId: recordId,
      isDirty: false,
    );
    // The record transaction has committed at this point. Reflect it locally
    // before checkpoint/cleanup so a retry cannot duplicate raw evidence.
    state = committed;
    final Result<void> checkpoint = await _persistence.saveSession(committed);
    if (checkpoint case FailureResult<void>()) {
      return checkpoint;
    }
    final Result<void> cleared = await _persistence.clearSession(projectId);
    if (cleared case FailureResult<void>()) {
      return cleared;
    }
    final CaptureSession next = CaptureReset.next(
      previous: committed,
      ids: _ids,
    );
    state = next;
    return const Success<void>(null);
  }

  /// Discards the interrupted session after confirm.
  Future<Result<void>> discardSession() async {
    for (final PhotoDraft photo in state.photos) {
      await _persistence.deletePhoto(photo.id, reason: 'session-discard');
    }
    await _persistence.clearSession(projectId);
    state = CaptureSession(
      id: _ids.newId(),
      projectId: projectId,
      templateId: state.templateId,
      contextSnapshot: state.contextSnapshot,
    );
    return const Success<void>(null);
  }
}

final class _MemoryPhotoRepository implements PhotoRepository {
  final Map<String, PhotoAsset> _rows = <String, PhotoAsset>{};

  @override
  Stream<List<PhotoAsset>> watchByRecord(String recordId) {
    return Stream<List<PhotoAsset>>.value(
      _rows.values
          .where((PhotoAsset row) => row.recordId == recordId)
          .toList(growable: false),
    );
  }

  @override
  Future<Result<PhotoAsset?>> byId(String id) async {
    return Success<PhotoAsset?>(_rows[id]);
  }

  @override
  Future<Result<PhotoAsset>> save(PhotoAsset photo) async {
    _rows[photo.id] = photo;
    return Success<PhotoAsset>(photo);
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) async {
    _rows.remove(id);
    return const Success<void>(null);
  }
}

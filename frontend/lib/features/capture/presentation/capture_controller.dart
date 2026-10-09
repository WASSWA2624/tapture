import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/audio/audio_recorder_service.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/feedback/haptics.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/lifecycle/deleted_entity.dart';
import 'package:tapture/core/lifecycle/lifecycle_observer.dart';
import 'package:tapture/core/location/location_service.dart';
import 'package:tapture/core/security/coordinate_removal_events.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/domain/audio_draft.dart';
import 'package:tapture/features/capture/domain/caption_apply.dart';
import 'package:tapture/features/capture/domain/capture_device_source.dart';
import 'package:tapture/features/capture/domain/capture_document_repository.dart';
import 'package:tapture/features/capture/domain/capture_persistence.dart';
import 'package:tapture/features/capture/domain/capture_photo_repository.dart';
import 'package:tapture/features/capture/domain/capture_record_persistence.dart';
import 'package:tapture/features/capture/domain/capture_reset.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/capture_session_key.dart';
import 'package:tapture/features/capture/domain/document_draft.dart';
import 'package:tapture/features/capture/domain/owned_capture_persistence.dart';
import 'package:tapture/features/capture/domain/pending_audio_draft.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';
import 'package:tapture/features/capture/domain/save_and_analyse.dart';
import 'package:tapture/features/capture/domain/save_raw.dart';
import 'package:tapture/features/capture/domain/template_usage.dart';
import 'package:tapture/features/processing/processing.dart';
import 'package:tapture/features/projects/projects.dart'
    show Project, ProjectSettings, projectRepositoryProvider;
import 'package:tapture/features/quality/quality.dart'
    show qualityRepositoryProvider;
import 'package:tapture/features/templates/templates.dart'
    show FieldDef, TemplateDef, TemplateVersioning;
import 'package:tapture/features/transcripts/transcripts.dart'
    show
        LiveTranscriptKey,
        LiveTranscriptStatus,
        TranscriptSessionPhase,
        liveTranscriptControllerProvider;

import 'capture_device_providers.dart';
import 'capture_template_providers.dart';

/// Default photo repository stub — [main] / tests override.
final Provider<PhotoRepository> photoRepositoryProvider =
    Provider<PhotoRepository>((Ref _) {
      return _MemoryPhotoRepository();
    });

/// Session + photo persistence. Tests override with a memory store.
final Provider<CapturePersistence> capturePersistenceProvider =
    Provider<CapturePersistence>((Ref ref) {
      return _MemoryCapturePersistence(ref.watch(photoRepositoryProvider));
    });

/// Production supplies the Drift-backed transaction writer. Tests may inject
/// a focused in-memory implementation without crossing presentation into data.
final Provider<CaptureRecordPersistence?> captureRecordWriterProvider =
    Provider<CaptureRecordPersistence?>((Ref _) => null);

/// Durable original-document storage; bootstrap supplies the concrete service.
final Provider<CaptureDocumentRepository?> captureDocumentRepositoryProvider =
    Provider<CaptureDocumentRepository?>((Ref _) => null);

/// The clock capture stamps photos and session ids with. Tests freeze it.
final Provider<Clock> captureClockProvider = Provider<Clock>(
  (Ref _) => const SystemClock(),
);

/// The app profile identifier supplied to the writer; absent before bootstrap.
final Provider<String?> captureDeviceIdProvider = Provider<String?>(
  (Ref _) => null,
);

/// Ids for new sessions, photos and audio, read from [captureClockProvider].
final Provider<IdService> captureIdsProvider = Provider<IdService>(
  (Ref ref) => UuidV7Service(ref.watch(captureClockProvider)),
);

/// The project's template ids, most recently captured with first, from the
/// record writer when it can tell. Empty otherwise.
final captureRecentTemplatesProvider =
    FutureProvider.family<List<String>, String>((
      Ref ref,
      String projectId,
    ) async {
      final CaptureRecordPersistence? records = ref.watch(
        captureRecordWriterProvider,
      );
      if (records case final TemplateUsage usage when projectId.isNotEmpty) {
        final Result<List<String>> recent = await usage.recentTemplateIds(
          projectId,
        );
        return recent.getOrElse(() => const <String>[]);
      }
      return const <String>[];
    });

/// Capture session for a session key: a project id for a new capture, and
/// [CaptureSessionKey.edit] for a saved record's edit (D6). Persist before
/// every emit.
final captureControllerProvider =
    NotifierProvider.family<CaptureController, CaptureSession, String>(
      CaptureController.new,
    );

/// Intent methods — the only way the session changes.
final class CaptureController extends Notifier<CaptureSession> {
  /// Creates a controller bound to [key] (family argument).
  CaptureController(this.key);

  /// The session key: a project id, or `edit:<recordId>`.
  final String key;

  CapturePersistence get _persistence => ref.read(capturePersistenceProvider);

  IdService get _ids => ref.read(captureIdsProvider);

  final Map<String, CoordinateRemoval> _removedCoordinates =
      <String, CoordinateRemoval>{};
  final Set<String> _removedPhotoCoordinates = <String>{};
  int _coordinateRemovalRevision = 0;

  @override
  CaptureSession build() {
    final CaptureDeviceSource source = ref.watch(
      captureDeviceSourceProvider(key),
    );
    final StreamSubscription<void> readings = source.changes.listen((_) {
      if (ref.mounted) ref.notifyListeners();
    });
    ref.onDispose(() => unawaited(readings.cancel()));
    final StreamSubscription<AppLifecycleState> lifecycle = ref
        .read(lifecycleObserverProvider)
        .states
        .listen((AppLifecycleState event) {
          if (ref.mounted && event == AppLifecycleState.resumed) {
            _refreshDeviceSource(state);
          }
        });
    ref.onDispose(() => unawaited(lifecycle.cancel()));
    if (!CaptureSessionKey.isEdit(key)) {
      ref.listen<AsyncValue<List<TemplateDef>>>(
        captureProjectTemplatesProvider(key),
        (_, _) => _bindDeviceSource(state),
      );
    }
    ref.listen<CoordinateRemoval?>(coordinateRemovalEventsProvider, (
      CoordinateRemoval? _,
      CoordinateRemoval? event,
    ) {
      if (event == null || event.projectId != state.projectId) return;
      _coordinateRemovalRevision += 1;
      _removedCoordinates[state.id] = event;
      _removedPhotoCoordinates.addAll(
        state.photos.map((PhotoDraft photo) => photo.id),
      );
      _emit(state);
    });
    return _empty();
  }

  CaptureSession _withoutRemovedCoordinates(CaptureSession session) {
    final CoordinateRemoval? removal = _removedCoordinates[session.id];
    return removal == null
        ? session
        : session.withoutCoordinates(
            removal.keysFor(
              session.templateId,
              session.templateVersion,
              recordId: session.recordId,
            ),
          );
  }

  PhotoDraft _withoutPhotoCoordinates(PhotoDraft photo, String sessionId) =>
      _removedPhotoCoordinates.contains(photo.id) ||
          _removedCoordinates.containsKey(
            photo.captureSessionId.isEmpty ? sessionId : photo.captureSessionId,
          )
      ? photo.copyWith(clearCoordinates: true)
      : photo;

  void _emit(CaptureSession session) {
    state = _withoutRemovedCoordinates(session);
    _bindDeviceSource(state);
  }

  void _bindDeviceSource(CaptureSession session) {
    final CaptureDeviceSource source = ref.read(
      captureDeviceSourceProvider(key),
    );
    final List<TemplateDef>? templates = session.editing
        ? null
        : ref.read(captureProjectTemplatesProvider(key)).asData?.value;
    final TemplateDef? template = templates
        ?.where((TemplateDef candidate) => candidate.id == session.templateId)
        .firstOrNull;
    // Match first-save attribution: a recovered contentful draft without a
    // pin cannot opt into sources introduced by a newer current header.
    final int? version =
        session.templateVersion ??
        (template != null && template.version > 1 && session.hasContent
            ? 0
            : template?.version);
    final TemplateDef? shape = template == null
        ? null
        : TemplateVersioning.shapeFor(template, version!);
    source.bind(session, shape?.fields ?? const <FieldDef>[]);
  }

  void _refreshDeviceSource(CaptureSession session) {
    // An empty binding invalidates even a recovery of the identical owner.
    // The current pinned shape then starts exactly one eligible background read.
    ref
        .read(captureDeviceSourceProvider(key))
        .bind(session, const <FieldDef>[]);
    _bindDeviceSource(session);
  }

  Future<Result<void>> _saveSession(
    CaptureSession session, {
    ({String sessionId, String templateId, int? templateVersion})? owner,
  }) async {
    while (true) {
      final int revision = _coordinateRemovalRevision;
      final CapturePersistence persistence = _persistence;
      final CaptureSession clean = _withoutRemovedCoordinates(session);
      final Result<void> saved;
      if (owner == null) {
        saved = await persistence.saveSession(clean);
      } else if (persistence is OwnedCapturePersistence) {
        saved = await persistence.saveOwnedSession(clean, owner: owner);
      } else {
        return _changeNotSaved();
      }
      if (saved is FailureResult<void> ||
          revision == _coordinateRemovalRevision) {
        return saved;
      }
    }
  }

  Future<Result<PhotoDraft>> _savePhoto(
    PhotoDraft photo, {
    Uint8List? bytes,
  }) async {
    final String sessionId = state.id;
    PhotoDraft next = photo;
    while (true) {
      final int revision = _coordinateRemovalRevision;
      final Result<PhotoDraft> saved = await _persistence.savePhoto(
        _withoutPhotoCoordinates(next, sessionId),
        bytes: bytes,
      );
      if (saved is FailureResult<PhotoDraft> ||
          revision == _coordinateRemovalRevision) {
        return saved;
      }
      next = (saved as Success<PhotoDraft>).value;
      // The first pass already copied the original file durably.
      bytes = null;
    }
  }

  CaptureSession _empty() {
    final String? recordId = CaptureSessionKey.recordOf(key);
    if (recordId != null) {
      // Filled by [loadRecord].
      return CaptureSession(
        id: recordId,
        templateId: '',
        contextSnapshot: const <String, String>{},
        recordId: recordId,
        editing: true,
      );
    }
    return CaptureSession(
      id: _ids.newId(),
      projectId: key,
      templateId: '',
      contextSnapshot: const <String, String>{},
    );
  }

  /// Whether [photo] is already filed on the record this session edits.
  /// Changes to it wait for [saveEdits], so leaving an edit without saving
  /// changes nothing on the record (FBK0000148).
  bool _filed(PhotoDraft photo) {
    return state.editing &&
        photo.recordId != null &&
        photo.recordId == state.recordId;
  }

  /// Loads the saved record [recordId] into this edit session and persists
  /// it, so an interrupted edit can resume.
  Future<Result<void>> loadRecord(String recordId) async {
    final CaptureRecordPersistence? records = ref.read(
      captureRecordWriterProvider,
    );
    if (records == null) {
      return FailureResult<void>(_noRecords);
    }
    final Result<CaptureSession> loaded = await records.load(recordId);
    return loaded.fold(FailureResult<void>.new, (CaptureSession session) async {
      final Result<void> saved = await _saveSession(session);
      return saved.fold(FailureResult<void>.new, (_) {
        _emit(session);
        return const Success<void>(null);
      });
    });
  }

  /// Writes this edit to its record, then clears the stored edit. A failure
  /// keeps every change in the session.
  Future<Result<void>> saveEdits() async {
    final CaptureRecordPersistence? records = ref.read(
      captureRecordWriterProvider,
    );
    if (records == null || !state.editing) {
      return FailureResult<void>(_noRecords);
    }
    final Result<void> live = await finishCaptureIfActive();
    if (live is FailureResult<void>) return live;
    final Result<void> audio = await finaliseAudio();
    if (audio is FailureResult<void>) return audio;
    final CaptureSession edited = state;
    final Result<void> updated = await records.update(edited);
    return updated.fold(FailureResult<void>.new, (_) async {
      _emit(edited.copyWith(isDirty: false));
      return _persistence.clearSession(edited.storageKey);
    });
  }

  /// Seeds or replaces the live session (recovery / tests).
  Future<Result<void>> replaceSession(CaptureSession session) async {
    final Result<void> saved = await _saveSession(session);
    return saved.fold(FailureResult<void>.new, (_) {
      ref
          .read(captureDeviceSourceProvider(key))
          .bind(session, const <FieldDef>[]);
      _emit(session);
      return const Success<void>(null);
    });
  }

  /// Brings back a session [discardSession] set aside: its photos lose their
  /// tombstones and it becomes the live session again (the Undo of a
  /// discard). Photos already filed on the record being edited were never
  /// tombstoned.
  Future<Result<void>> restoreDiscarded(CaptureSession discarded) async {
    for (final PhotoDraft photo in discarded.photos) {
      if (discarded.editing &&
          photo.recordId != null &&
          photo.recordId == discarded.recordId) {
        continue;
      }
      final Result<PhotoDraft> restored = await _savePhoto(photo);
      if (restored is FailureResult<PhotoDraft>) {
        return FailureResult<void>(restored.failure);
      }
    }
    return replaceSession(discarded);
  }

  /// The stored copy of this session when an interruption left work in it
  /// to offer back (task 012 step 19); otherwise null.
  ///
  /// For a new capture, a stored session from another project or with
  /// nothing in it is not offered; an empty one only hands its pinned
  /// template to the fresh session, so the pin outlives a restart (step
  /// 22). For an edit, only a changed edit is offered. Nothing here writes
  /// over the stored copy.
  Future<CaptureSession?> interrupted() async {
    final CaptureSession? stored = (await _persistence.loadSession(
      key,
    )).getOrElse(() => null);
    if (stored == null) {
      return null;
    }
    if (CaptureSessionKey.recordOf(key) != null) {
      return stored.editing && stored.isDirty ? stored : null;
    }
    if (stored.projectId.isNotEmpty && stored.projectId != key) {
      return null;
    }
    if (!stored.hasContent) {
      if (stored.templateId.isNotEmpty && ref.mounted) {
        await keepPinnedTemplate(stored.templateId);
      }
      return null;
    }
    return stored;
  }

  /// Stores the live session so it can be offered back after the page is
  /// left or the app is killed. A session with nothing in it, or an edit
  /// with no change, leaves nothing behind.
  Future<Result<void>> checkpoint() async {
    final CaptureSession current = state;
    if (!current.hasContent || (current.editing && !current.isDirty)) {
      return const Success<void>(null);
    }
    return _saveSession(current);
  }

  /// Pins [templateId] to the context [place] in [project]'s settings, so
  /// capture uses it whenever it is back at that context level (spec
  /// section 14.3, task 012 step 22). The session's own template is the
  /// session pin; this one outlives it.
  Future<Result<void>> pinTemplateToPlace({
    required Project project,
    required String templateId,
    required Map<String, String> place,
  }) async {
    final String? pinKey = ProjectSettings.templatePinKey(place);
    if (pinKey == null) {
      return const Success<void>(null);
    }
    return ref
        .read(projectRepositoryProvider)
        .update(
          project.copyWith(
            settings: project.settings.copyWith(
              templatePins: <String, String>{
                ...?project.settings.templatePins,
                pinKey: templateId,
              },
            ),
          ),
        );
  }

  /// Carries the template pinned before a save or a restart into this fresh
  /// session, unless one is already chosen (task 012 step 22).
  Future<Result<void>> keepPinnedTemplate(String templateId) {
    return _store(
      (CaptureSession current) => current.templateId.isNotEmpty
          ? current
          : current.copyWith(templateId: templateId),
    );
  }

  /// Adds [photo] after durable write. In an edit it is kept off the record
  /// until [saveEdits] files it.
  Future<Result<void>> addPhoto(PhotoDraft photo, {Uint8List? bytes}) async {
    final Result<PhotoDraft> saved = await _savePhoto(
      state.editing ? photo.copyWith(clearRecordId: true) : photo,
      bytes: bytes,
    );
    return saved.fold(FailureResult<void>.new, (PhotoDraft stored) {
      return _store(
        (CaptureSession current) => current.copyWith(
          photos: <PhotoDraft>[...current.photos, stored],
          isDirty: true,
        ),
      );
    });
  }

  /// Publishes a durable original document into recovery state.
  Future<Result<void>> addDocument(DocumentDraft document) => _store(
    (CaptureSession current) => current.copyWith(
      documents: <DocumentDraft>[
        ...current.documents.where(
          (DocumentDraft row) => row.id != document.id,
        ),
        document,
      ],
      isDirty: true,
    ),
  );

  /// Validates and stores an original before adding it to the live draft.
  Future<Result<void>> importDocument({
    required Uint8List bytes,
    required String filename,
    required String projectId,
    required String folder,
  }) async {
    final CaptureDocumentRepository? documents = ref.read(
      captureDocumentRepositoryProvider,
    );
    if (documents == null) {
      return FailureResult<void>(
        StorageFailure(
          localizedMessage: Copy.messages.captureDocumentsUnavailable,
          localizedRecovery: Copy.messages.captureDocumentsUnavailableRecovery,
        ),
      );
    }
    final Result<DocumentDraft> imported = await documents.import(
      bytes: bytes,
      filename: filename,
      projectId: projectId,
      folder: folder,
    );
    return imported.fold(FailureResult<void>.new, addDocument);
  }

  /// Adds an already-flushed audio clip and persists recovery state before it
  /// appears in the capture session.
  Future<Result<void>> addAudio(AudioDraft clip) {
    return _store(
      (CaptureSession current) => current.copyWith(
        audio: <AudioDraft>[
          ...current.audio.where((AudioDraft stored) => stored.id != clip.id),
          clip,
        ],
        pendingAudio: current.pendingAudio
            .where((PendingAudioDraft pending) => pending.id != clip.id)
            .toList(growable: false),
        isDirty: true,
      ),
    );
  }

  /// Saves microphone ownership before the adapter is allowed to write bytes.
  Future<Result<void>> stageAudio(PendingAudioDraft take) {
    return _store((CaptureSession current) {
      if (current.pendingAudio.any(
        (PendingAudioDraft row) => row.id == take.id,
      )) {
        return current;
      }
      return current.copyWith(
        pendingAudio: <PendingAudioDraft>[...current.pendingAudio, take],
        isDirty: true,
      );
    });
  }

  /// Registers a published take with the identity and photo ownership saved
  /// when it started. Retrying this operation never duplicates a clip.
  Future<Result<void>> publishAudio(AudioRecording recording) {
    PendingAudioDraft? pending;
    for (final PendingAudioDraft take in state.pendingAudio) {
      if (take.storageRelativePath == recording.relativePath) {
        pending = take;
        break;
      }
    }
    if (pending == null) {
      final String path = recording.relativePath;
      return state.audio.any(
            (AudioDraft clip) => path.endsWith('/${clip.relativePath}'),
          )
          ? Future<Result<void>>.value(const Success<void>(null))
          : Future<Result<void>>.value(
              FailureResult<void>(
                StorageFailure(
                  localizedMessage: Copy.messages.captureSaveFailed,
                ),
              ),
            );
    }
    return addAudio(
      AudioDraft(
        id: pending.id,
        projectId: pending.projectId,
        relativePath: pending.relativePath,
        mimeType: recording.mimeType,
        fileSize: recording.byteLength,
        sha256: recording.sha256,
        durationMs: recording.duration.inMilliseconds,
        photoIds: pending.photoIds,
      ),
    );
  }

  /// Forgets the pending take [pendingId], as when its recording is
  /// discarded or never started. Only the reference goes: the staged or
  /// published file is never touched (rule 1).
  Future<Result<void>> dropAudio(String pendingId) {
    return _store(
      (CaptureSession current) => current.copyWith(
        pendingAudio: current.pendingAudio
            .where((PendingAudioDraft row) => row.id != pendingId)
            .toList(growable: false),
      ),
    );
  }

  /// Stops the caption recorder's live transcript take, when one is still
  /// open, and waits only until its audio is published through
  /// [publishAudio] and linked to its transcript. The transcript itself
  /// finishes afterwards under the speech service, so no save waits for
  /// transcription (rule 3). Without a live take this does nothing.
  Future<Result<void>> finishCaptureIfActive() async {
    final String liveKey = LiveTranscriptKey.capture(key);
    final LiveTranscriptStatus status = ref.read(
      liveTranscriptControllerProvider(liveKey),
    );
    final bool open = switch (status.phase) {
      TranscriptSessionPhase.starting ||
      TranscriptSessionPhase.recording ||
      TranscriptSessionPhase.paused ||
      TranscriptSessionPhase.finishing => true,
      TranscriptSessionPhase.failed => status.retryable,
      TranscriptSessionPhase.idle || TranscriptSessionPhase.saved => false,
    };
    if (!open) {
      return const Success<void>(null);
    }
    final Result<String?> filed = await ref
        .read(liveTranscriptControllerProvider(liveKey).notifier)
        .stop();
    return filed.map((String? _) {});
  }

  /// Finalises a live take or recovers staged takes after a restart. A failed
  /// publication leaves every reference intact so Resume or Save can retry.
  Future<Result<void>> finaliseAudio() async {
    final AudioRecorderService recorder = ref.read(
      audioRecorderServiceProvider,
    );
    for (final PendingAudioDraft pending in List<PendingAudioDraft>.of(
      state.pendingAudio,
    )) {
      AudioRecording? recording = recorder.completed;
      if (recording?.relativePath != pending.storageRelativePath) {
        if (recorder case final AudioRecoveryService recovery) {
          final Result<AudioRecording?> recovered = await recovery.recover(
            pending.storageRelativePath,
          );
          if (recovered case FailureResult<AudioRecording?>(
            :final Failure failure,
          )) {
            return FailureResult<void>(failure);
          }
          recording = (recovered as Success<AudioRecording?>).value;
        } else {
          final Result<Duration> stopped = await recorder.stop();
          if (stopped case FailureResult<Duration>(:final Failure failure)) {
            return FailureResult<void>(failure);
          }
          recording = recorder.completed;
        }
      }
      final Result<void> saved = recording == null
          ? await dropAudio(pending.id)
          : await publishAudio(recording);
      if (saved is FailureResult<void>) return saved;
    }
    return const Success<void>(null);
  }

  /// Removes [photoId] after tombstone; leaves emitted state unchanged on
  /// failure. A photo filed on the record being edited leaves the session
  /// only; [saveEdits] tombstones it.
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
    final Result<void> deleted = _filed(removed)
        ? const Success<void>(null)
        : await _persistence.deletePhoto(photoId, reason: 'operator-delete');
    return deleted.fold(FailureResult<PhotoDraft?>.new, (_) async {
      final CaptureSession next = state.copyWith(
        photos: state.photos
            .where((PhotoDraft p) => p.id != photoId)
            .toList(growable: false),
        // Keep the caption in recovery state so Undo restores the complete
        // evidence. Saving only files captions for photos still in the tray.
        captions: state.captions,
        isDirty: true,
      );
      final Result<void> session = await _saveSession(next);
      return session.fold(FailureResult<PhotoDraft?>.new, (_) {
        _emit(next);
        return Success<PhotoDraft?>(removed);
      });
    });
  }

  /// Restores a previously removed photo at its sort position. A photo filed
  /// on the record being edited was never deleted, so only the session
  /// takes it back.
  Future<Result<void>> undoRemove(PhotoDraft photo) async {
    final Result<PhotoDraft> saved = _filed(photo)
        ? Success<PhotoDraft>(photo)
        : await _savePhoto(photo);
    return saved.fold(FailureResult<void>.new, (PhotoDraft stored) {
      return _store((CaptureSession current) {
        final List<PhotoDraft> photos =
            <PhotoDraft>[
              ...current.photos.where((PhotoDraft row) => row.id != stored.id),
              stored,
            ]..sort(
              (PhotoDraft a, PhotoDraft b) =>
                  a.sortOrder.compareTo(b.sortOrder),
            );
        return current.copyWith(photos: photos, isDirty: true);
      });
    });
  }

  /// Reorders photos to [orderedIds] and persists immediately.
  Future<Result<void>> reorderPhotos(List<String> orderedIds) async {
    if (orderedIds.length != state.photos.length ||
        orderedIds.toSet().length != state.photos.length ||
        !orderedIds.toSet().containsAll(
          state.photos.map((PhotoDraft p) => p.id),
        )) {
      return FailureResult<void>(
        ValidationFailure(
          localizedMessage: Copy.messages.captureOrderIncomplete,
          localizedRecovery: Copy.messages.captureOrderIncompleteRecovery,
        ),
      );
    }
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
      if (_filed(photo)) {
        continue;
      }
      final Result<PhotoDraft> saved = await _savePhoto(photo);
      if (saved is FailureResult<PhotoDraft>) {
        return FailureResult<void>(saved.failure);
      }
    }
    final CaptureSession next = state.copyWith(photos: ordered, isDirty: true);
    final Result<void> session = await _saveSession(next);
    return session.fold(FailureResult<void>.new, (_) {
      _emit(next);
      return const Success<void>(null);
    });
  }

  /// Sets caption for [photoId] (`null` / empty id = record caption).
  Future<Result<void>> setCaption(String? photoId, String text) {
    return _store((CaptureSession current) {
      final String key = photoId ?? '';
      final Map<String, String> captions = Map<String, String>.of(
        current.captions,
      )..[key] = text;
      List<PhotoDraft> photos = current.photos;
      if (photoId != null && photoId.isNotEmpty) {
        photos = <PhotoDraft>[
          for (final PhotoDraft photo in current.photos)
            photo.id == photoId
                ? photo.copyWith(hasCaption: text.isNotEmpty)
                : photo,
        ];
      }
      return current.copyWith(
        captions: captions,
        photos: photos,
        isDirty: true,
      );
    });
  }

  /// Applies caption writes from [CaptionApply].
  Future<Result<void>> applyCaptions(List<CaptionWrite> writes) {
    return _store((CaptureSession current) {
      final Map<String, String> captions = Map<String, String>.of(
        current.captions,
      );
      final Map<String, PhotoDraft> photos = <String, PhotoDraft>{
        for (final PhotoDraft photo in current.photos) photo.id: photo,
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
      return current.copyWith(
        captions: captions,
        photos: photos.values.toList(growable: false),
        isDirty: true,
      );
    });
  }

  /// Keeps [fix] on session [sessionId]; a fix that arrives after the next
  /// session has begun is dropped.
  Future<Result<void>> setLocation(GeoFix fix, {required String sessionId}) {
    if (_removedCoordinates.containsKey(sessionId)) {
      return Future<Result<void>>.value(const Success<void>(null));
    }
    return _store(
      (CaptureSession current) =>
          current.id == sessionId ? current.copyWith(location: fix) : current,
    );
  }

  /// Sets an inline field value.
  Future<Result<void>> setValue(
    String fieldKey,
    Object? value, {
    String source = 'TYPED',
    ({String sessionId, String templateId, int? templateVersion})? owner,
  }) {
    return _store((CaptureSession current) {
      final Map<String, Object?> values = Map<String, Object?>.of(
        current.values,
      )..[fieldKey] = value is DateTime ? value.toIso8601String() : value;
      return current.copyWith(
        values: values,
        isDirty: true,
        valueSources: <String, String>{
          ...current.valueSources,
          fieldKey: source,
        },
        lookupRows: Map<String, String>.of(current.lookupRows)
          ..remove(fieldKey),
      );
    }, owner: owner);
  }

  /// Fills only unverified values and remembers each field's own source row.
  Future<Result<void>> applyLookup(Map<String, String> mapped, String rowId) {
    return _store((CaptureSession current) {
      final Map<String, Object?> values = Map<String, Object?>.of(
        current.values,
      );
      final Map<String, String> sources = Map<String, String>.of(
        current.valueSources,
      );
      final Map<String, String> links = Map<String, String>.of(
        current.lookupRows,
      );
      for (final MapEntry<String, String> entry in mapped.entries) {
        if (values[entry.key] != null &&
            '${values[entry.key]}'.isNotEmpty &&
            sources[entry.key] != 'LOOKUP') {
          continue;
        }
        values[entry.key] = entry.value;
        sources[entry.key] = 'LOOKUP';
        links[entry.key] = rowId;
      }
      return current.copyWith(
        values: values,
        valueSources: sources,
        lookupRows: links,
        isDirty: true,
      );
    });
  }

  /// Updates photo type on [photoId].
  Future<Result<void>> setPhotoType(String photoId, String type) async {
    final List<PhotoDraft> photos = <PhotoDraft>[
      for (final PhotoDraft photo in state.photos)
        photo.id == photoId ? photo.copyWith(photoType: type) : photo,
    ];
    for (final PhotoDraft photo in photos) {
      if (photo.id == photoId && !_filed(photo)) {
        final Result<PhotoDraft> saved = await _savePhoto(photo);
        if (saved is FailureResult<PhotoDraft>) {
          return FailureResult<void>(saved.failure);
        }
      }
    }
    final CaptureSession next = state.copyWith(photos: photos, isDirty: true);
    final Result<void> session = await _saveSession(next);
    return session.fold(FailureResult<void>.new, (_) {
      _emit(next);
      return const Success<void>(null);
    });
  }

  /// Persists [photo]. When [bytes] is set, writes a new derived asset.
  Future<Result<void>> updatePhoto(PhotoDraft photo, {Uint8List? bytes}) {
    if (bytes != null) {
      return addPhoto(photo, bytes: bytes);
    }
    return setPhoto(photo);
  }

  /// Walks one step from [photoId] toward its original without deleting it.
  Future<Result<void>> revertPhoto(String photoId) async {
    PhotoDraft? photo;
    for (final PhotoDraft row in state.photos) {
      if (row.id == photoId) {
        photo = row;
        break;
      }
    }
    if (photo == null || photo.derivedFrom == null) {
      return const Success<void>(null);
    }
    final PhotoRepository repository = _persistence.photos;
    if (repository is CapturePhotoRepository && !_filed(photo)) {
      final Result<void> retired = await repository.retireDerived(photoId);
      if (retired is FailureResult<void>) {
        return retired;
      }
    }
    final CaptureSession next = state.copyWith(
      photos: state.photos
          .where((PhotoDraft row) => row.id != photoId)
          .toList(growable: false),
      isDirty: true,
    );
    final Result<void> session = await _saveSession(next);
    return session.fold(FailureResult<void>.new, (_) {
      _emit(next);
      return const Success<void>(null);
    });
  }

  /// Updates a photo draft (rotation, crop link, …).
  Future<Result<void>> setPhoto(PhotoDraft photo) async {
    final Result<PhotoDraft> saved = _filed(photo)
        ? Success<PhotoDraft>(photo)
        : await _savePhoto(photo);
    return saved.fold(FailureResult<void>.new, (PhotoDraft stored) async {
      final List<PhotoDraft> photos = <PhotoDraft>[
        for (final PhotoDraft row in state.photos)
          row.id == stored.id ? stored : row,
      ];
      final CaptureSession next = state.copyWith(photos: photos, isDirty: true);
      final Result<void> session = await _saveSession(next);
      return session.fold(FailureResult<void>.new, (_) {
        _emit(next);
        return const Success<void>(null);
      });
    });
  }

  /// Sets the template for this session.
  Future<Result<void>> setTemplate(String templateId, {int? version}) {
    return _store(
      (CaptureSession current) => current.copyWith(
        templateId: templateId,
        templateVersion: version,
        isDirty: true,
      ),
    );
  }

  /// Sets the context snapshot.
  Future<Result<void>> setContext(Map<String, String> snapshot) {
    return _store(
      (CaptureSession current) =>
          current.copyWith(contextSnapshot: snapshot, isDirty: true),
    );
  }

  /// Writes [build] onto the session that exists when the save finishes.
  ///
  /// A resume or another edit that lands first is kept; this change is
  /// applied on top of it instead of restoring a stale copy.
  Future<Result<void>> _store(
    CaptureSession Function(CaptureSession current) build, {
    ({String sessionId, String templateId, int? templateVersion})? owner,
  }) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      final CaptureSession base = state;
      if (!_owns(base, owner)) return _changeNotSaved();
      final CaptureSession next = build(base);
      final Result<void> saved = await _saveSession(next, owner: owner);
      if (saved is FailureResult<void>) {
        return saved;
      }
      if (!_owns(state, owner)) return _changeNotSaved();
      if (identical(state, base)) {
        _emit(next);
        return const Success<void>(null);
      }
    }
    return _changeNotSaved();
  }

  bool _owns(
    CaptureSession session,
    ({String sessionId, String templateId, int? templateVersion})? owner,
  ) =>
      owner == null ||
      (session.id == owner.sessionId &&
          session.templateId == owner.templateId &&
          session.templateVersion == owner.templateVersion);

  Result<void> _changeNotSaved() => FailureResult<void>(
    StorageFailure(
      localizedMessage: Copy.messages.captureChangeNotSaved,
      localizedRecovery: Copy.messages.captureChangeNotSavedRecovery,
    ),
  );

  /// Raw save path.
  Future<Result<String>> saveRaw(
    Future<Result<String>> Function(CaptureSession session) persist,
  ) async {
    final Result<void> live = await finishCaptureIfActive();
    if (live case FailureResult<void>(:final Failure failure)) {
      return FailureResult<String>(failure);
    }
    final Result<void> audio = await finaliseAudio();
    if (audio case FailureResult<void>(:final Failure failure)) {
      return FailureResult<String>(failure);
    }
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
    final Result<void> live = await finishCaptureIfActive();
    if (live case FailureResult<void>(:final Failure failure)) {
      return FailureResult<SaveAndAnalyseResult>(failure);
    }
    final Result<void> audio = await finaliseAudio();
    if (audio case FailureResult<void>(:final Failure failure)) {
      return FailureResult<SaveAndAnalyseResult>(failure);
    }
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
        _emit(committed);
        _confirmSaved();
        final Result<void> persisted = await _saveSession(committed);
        return persisted.fold(
          FailureResult<SaveAndAnalyseResult>.new,
          (_) => Success<SaveAndAnalyseResult>(result),
        );
      }
      final Result<void> completed = await _completeSave(result.recordId);
      return completed.map((_) => result);
    });
  }

  /// The record is durable: confirm it in the hand with the save pattern,
  /// which is told apart from the shutter without looking (FE-A11Y-09).
  void _confirmSaved() {
    if (ref.mounted) {
      ref.read(hapticsProvider).save();
      // Duplicate detection (task 015) runs after the save is confirmed and
      // is never awaited, so it cannot delay the confirmation.
      final String? saved = state.recordId;
      if (saved != null) {
        unawaited(
          ref.read(qualityRepositoryProvider).scanRecords(<String>[saved]),
        );
      }
    }
  }

  Future<Result<void>> _completeSave(String recordId) async {
    final CaptureSession committed = state.copyWith(
      recordId: recordId,
      isDirty: false,
    );
    // The record transaction has committed at this point. Reflect it locally
    // before checkpoint/cleanup so a retry cannot duplicate raw evidence.
    _emit(committed);
    _confirmSaved();
    final Result<void> checkpoint = await _saveSession(committed);
    if (checkpoint case FailureResult<void>()) {
      return checkpoint;
    }
    // The next session replaces the saved one in the store, so the pinned
    // template and context outlive a restart as well as the reset.
    final CaptureSession next = CaptureReset.next(
      previous: committed,
      ids: _ids,
    );
    final Result<void> stored = await _saveSession(next);
    if (stored case FailureResult<void>()) {
      return stored;
    }
    _emit(next);
    return const Success<void>(null);
  }

  /// Discards the interrupted session after confirm. An edit drops only the
  /// photos added during it; the record's own photos stay.
  Future<Result<void>> discardSession({CaptureSession? interrupted}) async {
    final CaptureSession target = interrupted ?? state;
    for (final PhotoDraft photo in target.photos) {
      if (_filed(photo)) {
        continue;
      }
      final Result<void> deleted = await _persistence.deletePhoto(
        photo.id,
        reason: 'session-discard',
      );
      if (deleted is FailureResult<void>) return deleted;
    }
    if (state.editing) {
      final Result<void> cleared = await _persistence.clearSession(key);
      if (cleared is FailureResult<void>) return cleared;
      _emit(_empty());
      return const Success<void>(null);
    }
    // The fresh session keeps the pinned template and context, in the store
    // as in memory, and takes the interrupted one's place there.
    final CaptureSession fresh = CaptureSession(
      id: _ids.newId(),
      projectId: key,
      templateId: target.templateId,
      contextSnapshot: target.contextSnapshot,
    );
    final Result<void> stored = await _saveSession(fresh);
    if (stored is FailureResult<void>) return stored;
    _emit(fresh);
    return const Success<void>(null);
  }
}

final StorageFailure _noRecords = StorageFailure(
  localizedMessage: Copy.messages.captureRecordsUnavailable,
  localizedRecovery: Copy.messages.captureRecordsUnavailableRecovery,
);

final class _MemoryPhotoRepository implements PhotoRepository {
  @override
  Stream<List<DeletedEntity>> watchDeleted() =>
      Stream<List<DeletedEntity>>.value(const <DeletedEntity>[]);

  @override
  Future<Result<void>> restore(String id) async =>
      const FailureResult<void>(CancelledFailure());

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

final class _MemoryCapturePersistence implements OwnedCapturePersistence {
  _MemoryCapturePersistence(this._photos);

  final PhotoRepository _photos;
  final Map<String, CaptureSession> _sessions = <String, CaptureSession>{};

  @override
  PhotoRepository get photos => _photos;

  @override
  Future<Result<PhotoDraft>> savePhoto(
    PhotoDraft photo, {
    Uint8List? bytes,
  }) async {
    final Result<PhotoAsset> saved = await _photos.save(photo.asAsset);
    return saved.map(
      (PhotoAsset asset) => photo.copyWith(
        id: asset.id,
        projectId: asset.projectId,
        recordId: asset.recordId,
        relativePath: asset.relativePath,
        sha256: asset.sha256,
      ),
    );
  }

  @override
  Future<Result<void>> deletePhoto(String photoId, {required String reason}) {
    return _photos.delete(photoId, reason: reason);
  }

  @override
  Future<Result<void>> saveSession(CaptureSession session) async {
    _sessions[session.storageKey] = session;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> saveOwnedSession(
    CaptureSession session, {
    required ({String sessionId, String templateId, int? templateVersion})
    owner,
  }) async {
    final CaptureSession? current = _sessions[session.storageKey];
    if (session.projectId.isEmpty ||
        current == null ||
        current.projectId != session.projectId ||
        current.storageKey != session.storageKey ||
        (
              sessionId: current.id,
              templateId: current.templateId,
              templateVersion: current.templateVersion,
            ) !=
            owner ||
        (
              sessionId: session.id,
              templateId: session.templateId,
              templateVersion: session.templateVersion,
            ) !=
            owner) {
      return FailureResult<void>(
        StorageFailure(
          localizedMessage: Copy.messages.captureChangeNotSaved,
          localizedRecovery: Copy.messages.captureChangeNotSavedRecovery,
        ),
      );
    }
    _sessions[session.storageKey] = session;
    return const Success<void>(null);
  }

  @override
  Future<Result<CaptureSession?>> loadSession(String key) async {
    return Success<CaptureSession?>(_sessions[key]);
  }

  @override
  Future<Result<void>> clearSession(String key) async {
    _sessions.remove(key);
    return const Success<void>(null);
  }
}

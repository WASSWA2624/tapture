import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/audio/audio_recorder_service.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_picker.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/network/offline_now.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/photo_markup.dart';
import 'package:tapture/features/capture/domain/audio_draft.dart';
import 'package:tapture/features/capture/domain/caption_apply.dart';
import 'package:tapture/features/capture/domain/capture_photo_repository.dart';
import 'package:tapture/features/capture/domain/capture_record_persistence.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/capture_template_choice.dart';
import 'package:tapture/features/capture/domain/photo_derivation.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';
import 'package:tapture/features/capture/domain/photo_rotate.dart';
import 'package:tapture/features/capture/domain/save_and_analyse.dart';
import 'package:tapture/features/capture/presentation/audio_recorder.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/capture/presentation/capture_recovery_prompt.dart';
import 'package:tapture/features/capture/presentation/capture_target_fields.dart';
import 'package:tapture/features/capture/presentation/gallery_picker.dart';
import 'package:tapture/features/capture/presentation/inline_fields_section.dart';
import 'package:tapture/features/capture/presentation/photo_crop_screen.dart';
import 'package:tapture/features/capture/presentation/photo_doodle_screen.dart';
import 'package:tapture/features/capture/presentation/photo_tray.dart';
import 'package:tapture/features/capture/presentation/photo_viewer_screen.dart';
import 'package:tapture/features/capture/presentation/record_caption_field.dart';
import 'package:tapture/features/context/context.dart';
import 'package:tapture/features/processing/processing.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/templates/templates.dart';

export 'capture_target_fields.dart' show captureProjectTemplatesProvider;

/// Production supplies the Drift-backed transaction writer. Tests may inject
/// a focused in-memory implementation without crossing presentation into data.
final Provider<CaptureRecordPersistence?> captureRecordWriterProvider =
    Provider<CaptureRecordPersistence?>((Ref _) => null);

/// Camera and library picker for capture. Tests override with [PhotoPicker.fake].
final Provider<PhotoPicker> capturePhotoPickerProvider = Provider<PhotoPicker>(
  (Ref _) => PhotoPicker(),
);

/// Templates for the open project, read through the templates barrel.
final StreamProvider<List<TemplateDef>> captureTemplatesProvider =
    StreamProvider<List<TemplateDef>>((Ref ref) {
      final String? projectId = ref.watch(currentProjectProvider);
      if (projectId == null || projectId.isEmpty) {
        return Stream<List<TemplateDef>>.value(const <TemplateDef>[]);
      }
      return ref.watch(templateRepositoryProvider).watchByProject(projectId);
    });

typedef _CaptureUiState = ({String audioId, bool saving});

final _captureUiProvider =
    NotifierProvider.family<_CaptureUiController, _CaptureUiState, String>(
      _CaptureUiController.new,
    );

final class _CaptureUiController extends Notifier<_CaptureUiState> {
  _CaptureUiController(String _);

  final IdService _ids = UuidV7Service(const SystemClock());

  @override
  _CaptureUiState build() => (audioId: _ids.newId(), saving: false);

  void renewAudioId() {
    state = (audioId: _ids.newId(), saving: state.saving);
  }

  void setSaving(bool saving) {
    state = (audioId: state.audioId, saving: saving);
  }
}

/// Capture surface: tray, caption, template choice, saves.
final class CaptureScreen extends ConsumerStatefulWidget {
  /// Creates the screen for [projectId].
  const CaptureScreen({
    required this.projectId,
    this.fields = const <FieldDef>[],
    this.onAddPhoto,
    this.onSaveRaw,
    this.onSaveAndAnalyse,
    this.headroom,
    super.key,
  });

  /// Open project. Empty on the Capture tab root.
  final String projectId;

  /// Template fields for the inline section.
  final List<FieldDef> fields;

  /// When set, replaces the add-photo sheet.
  final VoidCallback? onAddPhoto;

  /// Raw save.
  final VoidCallback? onSaveRaw;

  /// Analyse save.
  final VoidCallback? onSaveAndAnalyse;

  /// Optional storage banner.
  final Widget? headroom;

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final Set<String> _selected = <String>{};
  final Map<String, Uint8List> _bytes = <String, Uint8List>{};
  final Map<String, String> _thumbs = <String, String>{};
  final Set<String> _missing = <String>{};
  String? _derivationNotice;
  bool _restored = false;
  bool _onStage = true;
  String? _chosen;
  final IdService _ids = UuidV7Service(const SystemClock());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_restore());
    });
  }

  @override
  void deactivate() {
    unawaited(_persist());
    super.deactivate();
  }

  /// Project this capture is filed under. A route id stands until the
  /// operator picks another. Empty means none is selected.
  String _projectId() {
    final String? chosen = _chosen;
    if (chosen != null && chosen.isNotEmpty) {
      return chosen;
    }
    if (widget.projectId.isNotEmpty) {
      return widget.projectId;
    }
    return ref.read(currentProjectProvider) ?? '';
  }

  void _chooseProject(String id) {
    setState(() => _chosen = id);
    ref.read(currentProjectProvider.notifier).open(id);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(currentProjectProvider);
    final String projectId = _projectId();
    final AsyncValue<List<TemplateDef>> templateState = ref.watch(
      captureProjectTemplatesProvider(projectId),
    );
    final List<TemplateDef> templates =
        templateState.asData?.value ?? const <TemplateDef>[];
    final bool ready = projectId.isNotEmpty && templates.isNotEmpty;
    final bool visible = _visible(context);
    if (_onStage && !visible) {
      _onStage = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_persist());
      });
    } else if (visible) {
      _onStage = true;
    }
    final CaptureSession session = ref.watch(
      captureControllerProvider(_projectId()),
    );
    final CaptureController controller = ref.read(
      captureControllerProvider(_projectId()).notifier,
    );
    final _CaptureUiState uiState = ref.watch(_captureUiProvider(_projectId()));
    final ContextState? activeContext = _projectId().isEmpty
        ? null
        : ref.watch(projectContextProvider(_projectId())).asData?.value;
    if (activeContext != null) {
      final Map<String, String> snapshot = <String, String>{
        ...activeContext.values,
        ...activeContext.pinned,
      };
      if (!_sameContext(session.contextSnapshot, snapshot)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(controller.setContext(snapshot));
        });
      }
    }
    final Project? project = ref.watch(currentProjectDetailsProvider);
    final String? templateId = CaptureTemplateChoice.resolve(
      templateIds: <String>[
        for (final TemplateDef template in templates) template.id,
      ],
      selection: ref.watch(projectTemplateSelectionProvider),
      sessionTemplateId: session.templateId,
      choice: project?.settings.templateChoice,
    );
    if (templateId != null && session.templateId != templateId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(controller.setTemplate(templateId));
        }
      });
    }
    final bool needsChoice = ready && templateId == null;
    final bool offline = ref.watch(offlineNowProvider);
    const String title = Copy.navCapture;
    final Widget? banner = widget.headroom;
    return AppPage(
      key: const ValueKey<String>('route-capture'),
      title: title,
      showAppBar: false,
      scrollable: true,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppButton(
            label: Copy.captureSaveRaw,
            variant: AppButtonVariant.secondary,
            expand: true,
            busy: uiState.saving,
            onPressed: ready
                ? (widget.onSaveRaw ?? () => unawaited(_save(false)))
                : null,
          ),
          const SizedBox(height: Space.x2),
          AppPrimaryAction(
            label: Copy.captureSaveAndAnalyse,
            busy: uiState.saving,
            // Processing waits for a network; Save raw keeps capture
            // unblocked meanwhile (D3).
            caption: offline ? Copy.captureProcessNeedsNetwork : null,
            onPressed: ready && !offline
                ? (widget.onSaveAndAnalyse ?? () => unawaited(_save(true)))
                : null,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (banner != null) ...<Widget>[banner, _blockGap],
          CaptureTargetFields(
            selectedProjectId: projectId,
            templates: templates,
            templateId: templateId,
            onProjectSelected: _chooseProject,
          ),
          _blockGap,
          PhotoTray(
            photos: _activePhotos(session),
            captions: session.captions,
            selectedIds: _selected,
            thumbPaths: _thumbs,
            missingIds: _missing,
            onAdd: !ready || needsChoice ? null : (widget.onAddPhoto ?? _add),
            onLongPress: (PhotoDraft photo) {
              setState(() {
                if (!_selected.add(photo.id)) {
                  _selected.remove(photo.id);
                }
              });
            },
            onTap: (PhotoDraft photo) => _openViewer(session, photo),
            onRemove: (PhotoDraft photo) {
              unawaited(
                ref
                    .read(captureControllerProvider(_projectId()).notifier)
                    .removePhoto(photo.id),
              );
            },
          ),
          _blockGap,
          RecordCaptionField(
            enabled: ready,
            // The field shows what its targets share, so the next keystroke
            // never copies one photo's caption onto another (FBK0000132).
            value: _captionTargets(session).isEmpty
                ? session.recordCaption
                : CaptionApply.sharedText(
                    ids: _captionTargets(session),
                    captions: session.captions,
                  ),
            onChanged: (String text) async {
              final Result<void> result = await controller.setCaption(
                null,
                text,
              );
              if (result is FailureResult<void>) {
                return false;
              }
              final List<String> ids = _captionTargets(
                ref.read(captureControllerProvider(_projectId())),
              );
              if (ids.isEmpty) {
                return true;
              }
              final Result<void> applied = await controller.applyCaptions(
                CaptionApply.apply(
                  photoIds: ids,
                  text: text,
                  mode: CaptionApplyMode.replace,
                  existing: session.captions,
                ),
              );
              return applied.fold((Failure _) => false, (_) => true);
            },
            onWriteFailed: (String _) {
              showAppSnack(
                context,
                Copy.captureSaveFailed,
                tone: SnackTone.error,
              );
            },
            afterDictation: _RecordAudioButton(
              enabled: ready,
              recorder: ref.watch(audioRecorderServiceProvider),
              relativePath: project == null
                  ? null
                  : 'projects/${project.folderName}/audio/${uiState.audioId}.wav',
              onCompleted: (AudioRecording recording) =>
                  unawaited(_audioStopped(recording)),
            ),
          ),
          // The recorder block carries its own gap and is empty while idle.
          if (project != null) ...<Widget>[
            AudioRecorder(
              recorder: ref.watch(audioRecorderServiceProvider),
              relativePath:
                  'projects/${project.folderName}/audio/${uiState.audioId}.wav',
              onCompleted: (AudioRecording recording) =>
                  unawaited(_audioStopped(recording)),
            ),
            if (session.audio.isNotEmpty) ...<Widget>[
              const SizedBox(height: Space.x2),
              Text(
                Copy.captureAudioCount(session.audio.length),
                style: AppText.caption,
              ),
            ],
          ],
          _blockGap,
          InlineFieldsSection(
            fields: widget.fields,
            values: session.values,
            onChanged: (String key, Object? value) {
              unawaited(controller.setValue(key, value));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _add() async {
    final PhotoPicker picker = ref.read(capturePhotoPickerProvider);
    if (!mounted) {
      return;
    }
    await showAppSheet<void>(
      context,
      title: Copy.captureAddSheetTitle,
      contentSized: true,
      builder: (BuildContext sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (picker.canTakePhoto)
              AppButton(
                label: Copy.captureTakePhoto,
                icon: AppIcons.camera,
                expand: true,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(_take(picker));
                },
              ),
            if (picker.canTakePhoto) const SizedBox(height: Space.x2),
            AppButton(
              label: Copy.captureChoosePhoto,
              icon: AppIcons.photoLibrary,
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                unawaited(_choose(picker));
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _take(PhotoPicker picker) async {
    final Result<List<Uint8List>> result = await picker.take(
      longEdge: GalleryPicker.defaultLongEdge,
    );
    await _imported(result);
  }

  Future<void> _choose(PhotoPicker picker) async {
    final Result<List<Uint8List>> result = await picker.choose(
      limit: GalleryPicker.defaultLimit,
      longEdge: GalleryPicker.defaultLongEdge,
    );
    await _imported(result);
  }

  Future<void> _imported(Result<List<Uint8List>> result) async {
    switch (result) {
      case FailureResult<List<Uint8List>>(:final Failure failure):
        if (mounted) {
          showAppSnack(context, failure.message, tone: SnackTone.error);
        }
      case Success<List<Uint8List>>(:final List<Uint8List> value):
        for (final Uint8List bytes in value) {
          await _storePhoto(bytes, derivedFrom: null);
        }
    }
  }

  Future<void> _storePhoto(
    Uint8List bytes, {
    required String? derivedFrom,
  }) async {
    final String id = _ids.newId();
    final PhotoDraft draft = PhotoDraft(
      id: id,
      projectId: _projectId(),
      captureSessionId: ref.read(captureControllerProvider(_projectId())).id,
      originalFilename: '$id.jpg',
      storedFilename: '$id.jpg',
      relativePath: 'photos/$id.jpg',
      sha256: sha256.convert(bytes).toString(),
      fileSize: bytes.length,
      mimeType: 'image/jpeg',
      capturedAt: const SystemClock().nowUtc(),
      derivedFrom: derivedFrom,
    );
    final Result<void> saved = await ref
        .read(captureControllerProvider(_projectId()).notifier)
        .addPhoto(draft, bytes: bytes);
    if (!mounted) {
      return;
    }
    switch (saved) {
      case FailureResult<void>(:final Failure failure):
        showAppSnack(context, failure.message, tone: SnackTone.error);
      case Success<void>():
        setState(() => _bytes[id] = bytes);
        unawaited(_refreshThumbs(<PhotoDraft>[draft]));
    }
  }

  /// Photos a caption goes to: the ticked ones, and all of them when none
  /// is ticked (FBK0000132).
  List<String> _captionTargets(CaptureSession session) {
    return CaptionApply.targets(
      visibleIds: <String>[
        for (final PhotoDraft photo in _activePhotos(session)) photo.id,
      ],
      selectedIds: _selected,
    );
  }

  List<PhotoDraft> _activePhotos(CaptureSession session) {
    final Result<List<PhotoDraft>> selected = PhotoDerivation.select(
      session.photos,
    );
    switch (selected) {
      case Success<List<PhotoDraft>>(:final List<PhotoDraft> value):
        return value;
      case FailureResult<List<PhotoDraft>>(:final Failure failure):
        if (_derivationNotice != failure.message) {
          _derivationNotice = failure.message;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              showAppSnack(context, failure.message, tone: SnackTone.error);
            }
          });
        }
        return <PhotoDraft>[
          for (final PhotoDraft photo in session.photos)
            if (photo.derivedFrom == null) photo,
        ];
    }
  }

  void _openViewer(CaptureSession session, PhotoDraft photo) {
    final List<PhotoDraft> photos = _activePhotos(session);
    final int index = photos.indexWhere((PhotoDraft row) => row.id == photo.id);
    final CaptureController controller = ref.read(
      captureControllerProvider(_projectId()).notifier,
    );
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext routeContext) {
            return PhotoViewerScreen(
              photos: photos,
              initialIndex: index < 0 ? 0 : index,
              images: _bytes,
              missingIds: _missing,
              captions: session.captions,
              onCaptionChanged: (PhotoDraft current, String text) async {
                final Result<void> saved = await controller
                    .applyCaptions(<CaptionWrite>[
                      CaptionWrite(
                        photoId: current.id,
                        text: text,
                        previousText: ref
                            .read(captureControllerProvider(_projectId()))
                            .captions[current.id],
                      ),
                    ]);
                return saved is Success<void>;
              },
              loadBytes: _readPhoto,
              onRotate: (PhotoDraft current, int degrees) async {
                final Result<void> saved = await controller.updatePhoto(
                  PhotoRotate.apply(current, degrees),
                );
                if (saved is FailureResult<void> && mounted) {
                  showAppSnack(
                    context,
                    saved.failure.message,
                    tone: SnackTone.error,
                  );
                }
                return saved is Success<void>;
              },
              onCrop: (PhotoDraft current) {
                unawaited(_crop(routeContext, current));
              },
              onDraw: (PhotoDraft current) {
                unawaited(_draw(routeContext, current));
              },
              onType: (PhotoDraft current) {
                unawaited(_type(routeContext, current));
              },
              onRevert: (PhotoDraft current) {
                Navigator.of(routeContext).pop();
                unawaited(_revert(current.id));
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _audioStopped(AudioRecording recording) async {
    final _CaptureUiState uiState = ref.read(_captureUiProvider(_projectId()));
    final CaptureSession session = ref.read(
      captureControllerProvider(_projectId()),
    );
    final List<PhotoDraft> visible = _activePhotos(session);
    final List<String> photoIds = _selected.isEmpty
        ? <String>[for (final PhotoDraft photo in visible) photo.id]
        : _selected.toList(growable: false);
    final int audioSegment = recording.relativePath.indexOf('audio/');
    final String projectPath = audioSegment < 0
        ? 'audio/${uiState.audioId}.wav'
        : recording.relativePath.substring(audioSegment);
    final Result<void> saved = await ref
        .read(captureControllerProvider(_projectId()).notifier)
        .addAudio(
          AudioDraft(
            id: uiState.audioId,
            projectId: _projectId(),
            relativePath: projectPath,
            mimeType: recording.mimeType,
            fileSize: recording.byteLength,
            sha256: recording.sha256,
            durationMs: recording.duration.inMilliseconds,
            photoIds: photoIds,
          ),
        );
    if (!mounted) return;
    switch (saved) {
      case FailureResult<void>(:final Failure failure):
        showAppSnack(context, failure.message, tone: SnackTone.error);
      case Success<void>():
        ref.read(_captureUiProvider(_projectId()).notifier).renewAudioId();
    }
  }

  Future<void> _crop(BuildContext routeContext, PhotoDraft photo) async {
    final Uint8List? bytes = await _readPhoto(photo);
    if (!routeContext.mounted) {
      return;
    }
    await Navigator.of(routeContext).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return PhotoCropScreen(
            photo: photo,
            bytes: bytes,
            onCropped: (PhotoDraft derived, Uint8List? png) {
              if (png == null) {
                return;
              }
              unawaited(() async {
                final bool saved = await _commitDerived(photo, derived, png);
                if (saved && context.mounted) {
                  Navigator.of(context).pop();
                }
              }());
            },
            onRevert: (PhotoDraft source) {
              Navigator.of(context).pop();
              unawaited(_revert(source.id));
            },
          );
        },
      ),
    );
  }

  Future<void> _draw(BuildContext routeContext, PhotoDraft photo) async {
    final Uint8List? bytes = await _readPhoto(photo);
    if (bytes == null) {
      if (mounted) {
        showAppSnack(context, Copy.missingPhoto, tone: SnackTone.error);
      }
      return;
    }
    if (!routeContext.mounted) {
      return;
    }
    await Navigator.of(routeContext).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return PhotoDoodleScreen(
            photo: photo,
            bytes: bytes,
            onDrawn: (PhotoDraft derived, Uint8List png) {
              unawaited(() async {
                final bool saved = await _commitDerived(photo, derived, png);
                if (saved && context.mounted) {
                  Navigator.of(context).pop();
                }
              }());
            },
          );
        },
      ),
    );
  }

  Future<void> _revert(String photoId) async {
    final Result<void> reverted = await ref
        .read(captureControllerProvider(_projectId()).notifier)
        .revertPhoto(photoId);
    if (!mounted) {
      return;
    }
    switch (reverted) {
      case FailureResult<void>(:final Failure failure):
        showAppSnack(context, failure.message, tone: SnackTone.error);
      case Success<void>():
        setState(() {
          _bytes.remove(photoId);
          _thumbs.remove(photoId);
          _missing.remove(photoId);
        });
    }
  }

  Future<bool> _commitDerived(
    PhotoDraft source,
    PhotoDraft derived,
    Uint8List png,
  ) async {
    final CaptureController controller = ref.read(
      captureControllerProvider(_projectId()).notifier,
    );
    final Result<void> saved = await controller.updatePhoto(
      derived.copyWith(
        projectId: _projectId(),
        sha256: sha256.convert(png).toString(),
        fileSize: png.length,
      ),
      bytes: png,
    );
    if (!mounted) {
      return false;
    }
    switch (saved) {
      case FailureResult<void>(:final Failure failure):
        showAppSnack(context, failure.message, tone: SnackTone.error);
        return false;
      case Success<void>():
        final CaptureSession session = ref.read(
          captureControllerProvider(_projectId()),
        );
        final String? caption = session.captions[source.id];
        if (caption != null && caption.isNotEmpty) {
          await controller.setCaption(derived.id, caption);
        }
        if (!mounted) {
          return true;
        }
        setState(() => _bytes[derived.id] = png);
        unawaited(_refreshThumbs(<PhotoDraft>[derived]));
        return true;
    }
  }

  Future<Uint8List?> _readPhoto(PhotoDraft photo) async {
    final Uint8List? cached = _bytes[photo.id];
    if (cached != null) {
      return cached;
    }
    final PhotoRepository repository = ref
        .read(capturePersistenceProvider)
        .photos;
    if (repository is! CapturePhotoRepository) {
      return null;
    }
    final Result<Uint8List> bytes = await repository.readBytes(photo);
    switch (bytes) {
      case FailureResult<Uint8List>():
        if (mounted) {
          setState(() => _missing.add(photo.id));
        }
        return null;
      case Success<Uint8List>(:final Uint8List value):
        _bytes[photo.id] = value;
        return value;
    }
  }

  Future<void> _refreshThumbs(List<PhotoDraft> photos) async {
    final PhotoRepository repository = ref
        .read(capturePersistenceProvider)
        .photos;
    if (repository is! CapturePhotoRepository) {
      return;
    }
    final Map<String, String> next = Map<String, String>.of(_thumbs);
    final Set<String> missing = Set<String>.of(_missing);
    for (final PhotoDraft photo in photos) {
      Result<String> thumb = await repository.cachedThumbnailPath(
        photo,
        edge: AppConstants.images.thumbnailEdge,
      );
      final Uint8List? held = _bytes[photo.id];
      if (thumb is FailureResult<String> && held != null) {
        thumb = await repository.cachedThumbnailForBytes(
          photo,
          held,
          edge: AppConstants.images.thumbnailEdge,
        );
      }
      if (thumb is FailureResult<String> && held == null) {
        final Result<Uint8List> read = await repository.readBytes(photo);
        if (read is Success<Uint8List>) {
          _bytes[photo.id] = read.value;
          thumb = await repository.cachedThumbnailForBytes(
            photo,
            read.value,
            edge: AppConstants.images.thumbnailEdge,
          );
        } else {
          missing.add(photo.id);
          next.remove(photo.id);
          continue;
        }
      }
      switch (thumb) {
        case FailureResult<String>():
          missing.remove(photo.id);
        case Success<String>(:final String value):
          missing.remove(photo.id);
          next[photo.id] = value;
      }
    }
    if (mounted) {
      setState(() {
        _thumbs
          ..clear()
          ..addAll(next);
        _missing
          ..clear()
          ..addAll(missing);
      });
    }
  }

  Future<void> _type(BuildContext routeContext, PhotoDraft photo) async {
    final Uint8List? bytes = await _readPhoto(photo);
    if (bytes == null) {
      if (mounted) {
        showAppSnack(context, Copy.missingPhoto, tone: SnackTone.error);
      }
      return;
    }
    if (!routeContext.mounted) {
      return;
    }
    final TextEditingController text = TextEditingController();
    String? error;
    await showAppSheet<void>(
      routeContext,
      title: Copy.photoTypeOn,
      contentSized: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheet) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppTextField(label: Copy.photoTypeOn, controller: text),
                if (error != null) Text(error!),
                AppButton(
                  label: Copy.save,
                  onPressed: () async {
                    final Result<Uint8List> png = await PhotoMarkup.typeOn(
                      bytes,
                      text.text,
                      rotationDegrees: photo.rotationDegrees,
                    );
                    switch (png) {
                      case FailureResult<Uint8List>(:final Failure failure):
                        setSheet(() => error = failure.message);
                      case Success<Uint8List>(:final Uint8List value):
                        final String id = _ids.newId();
                        final bool saved = await _commitDerived(
                          photo,
                          photo.copyWith(
                            id: id,
                            relativePath: 'photos/$id.png',
                            storedFilename: '$id.png',
                            originalFilename: '$id.png',
                            mimeType: 'image/png',
                            derivedFrom: photo.id,
                            rotationDegrees: 0,
                            capturedAt: const SystemClock().nowUtc(),
                          ),
                          value,
                        );
                        if (saved && sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
    text.dispose();
  }

  Future<void> _restore() async {
    if (_restored || !mounted) {
      return;
    }
    _restored = true;
    final Result<CaptureSession?> loaded = await ref
        .read(capturePersistenceProvider)
        .loadSession(_projectId());
    if (!mounted) {
      return;
    }
    final CaptureSession? session = switch (loaded) {
      Success<CaptureSession?>(:final CaptureSession? value) => value,
      FailureResult<CaptureSession?>() => null,
    };
    if (session == null || !_hasContent(session)) {
      return;
    }
    if (session.projectId.isNotEmpty &&
        _projectId().isNotEmpty &&
        session.projectId != _projectId()) {
      return;
    }
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CaptureRecoveryPrompt(
          photoCount: session.photos.length,
          onResume: () {
            Navigator.of(dialogContext).pop();
            unawaited(() async {
              await ref
                  .read(captureControllerProvider(_projectId()).notifier)
                  .replaceSession(session);
              if (mounted) {
                await _refreshThumbs(_activePhotos(session));
              }
            }());
          },
          onDiscard: () async {
            await ref
                .read(captureControllerProvider(_projectId()).notifier)
                .discardSession();
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
          },
        );
      },
    );
  }

  Future<void> _persist() async {
    if (!mounted) {
      return;
    }
    final CaptureSession session = ref.read(
      captureControllerProvider(_projectId()),
    );
    if (!_hasContent(session)) {
      return;
    }
    await ref.read(capturePersistenceProvider).saveSession(session);
  }

  Future<void> _save(bool process) async {
    final _CaptureUiController ui = ref.read(
      _captureUiProvider(_projectId()).notifier,
    );
    if (ref.read(_captureUiProvider(_projectId())).saving || !mounted) {
      return;
    }
    final CaptureRecordPersistence? writer = ref.read(
      captureRecordWriterProvider,
    );
    if (writer == null) {
      showAppSnack(context, Copy.captureSaveFailed, tone: SnackTone.error);
      return;
    }
    ui.setSaving(true);
    final CaptureController controller = ref.read(
      captureControllerProvider(_projectId()).notifier,
    );
    late final Result<Object> result;
    try {
      if (process) {
        result = await controller.saveAndAnalyse(
          persist: writer.persist,
          enqueue: (String recordId) async {
            final Result<String> queued = await ref
                .read(processingRepositoryProvider)
                .enqueue(recordId);
            return queued.map(
              (String jobId) =>
                  SaveAndAnalyse.jobFor(jobId: jobId, recordId: recordId),
            );
          },
        );
      } else {
        result = await controller.saveRaw(writer.persist);
      }
    } finally {
      ui.setSaving(false);
    }
    if (!mounted) {
      return;
    }
    switch (result) {
      case FailureResult<Object>(:final Failure failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          undoLabel: Copy.queueRetry,
          onUndo: () => unawaited(_save(process)),
        );
      case Success<Object>(:final Object value):
        if (value is SaveAndAnalyseResult && value.enqueueFailed) {
          showAppSnack(
            context,
            Copy.captureEnqueueFailed,
            tone: SnackTone.error,
            undoLabel: Copy.queueRetry,
            onUndo: () => unawaited(_save(true)),
          );
          return;
        }
        _bytes.clear();
        _selected.clear();
        showAppSnack(context, Copy.captureSaved, tone: SnackTone.success);
    }
  }

  bool _hasContent(CaptureSession session) {
    if (session.photos.isNotEmpty || session.audio.isNotEmpty) {
      return true;
    }
    if (session.values.isNotEmpty) {
      return true;
    }
    for (final String text in session.captions.values) {
      if (text.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  bool _visible(BuildContext context) {
    bool onStage = true;
    context.visitAncestorElements((Element element) {
      final Widget widget = element.widget;
      if (widget is Offstage && widget.offstage) {
        onStage = false;
        return false;
      }
      return true;
    });
    return onStage;
  }
}

/// Waveform control for the caption field. Hidden while a take is open.
final class _RecordAudioButton extends StatefulWidget {
  const _RecordAudioButton({
    required this.recorder,
    required this.relativePath,
    this.onCompleted,
    this.enabled = true,
  });

  final AudioRecorderService recorder;
  final String? relativePath;
  final ValueChanged<AudioRecording>? onCompleted;

  /// When false, record and stop do not accept a press.
  final bool enabled;

  @override
  State<_RecordAudioButton> createState() => _RecordAudioButtonState();
}

class _RecordAudioButtonState extends State<_RecordAudioButton> {
  AudioRecorderPhase _phase = AudioRecorderPhase.idle;
  StreamSubscription<AudioRecorderState>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.recorder.state.listen((AudioRecorderState next) {
      if (mounted) {
        setState(() => _phase = next.phase);
      }
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  bool get _live =>
      _phase == AudioRecorderPhase.recording ||
      _phase == AudioRecorderPhase.paused;

  @override
  Widget build(BuildContext context) {
    final bool live = _live;
    return AppIconButton(
      key: const ValueKey<String>('capture-record-audio'),
      icon: live ? AppIcons.stop : AppIcons.recordAudio,
      semanticLabel: live ? Copy.captureStopAudio : Copy.captureRecordAudio,
      tooltip: live ? Copy.captureStopAudio : Copy.captureRecordAudio,
      outlined: false,
      onPressed: widget.enabled ? (live ? _stop : _start) : null,
    );
  }

  Future<void> _start() async {
    final String? path = widget.relativePath;
    if (path == null || path.isEmpty) {
      showAppSnack(context, Copy.homeEmptyHeadline, tone: SnackTone.error);
      return;
    }
    final Result<void> result = await widget.recorder.start(path);
    if (!mounted) {
      return;
    }
    result.fold((Failure failure) {
      showAppSnack(context, failure.message, tone: SnackTone.error);
    }, (_) {});
  }

  Future<void> _stop() async {
    final Result<Duration> stopped = await widget.recorder.stop();
    if (!mounted) {
      return;
    }
    stopped.fold(
      (Failure failure) {
        showAppSnack(context, failure.message, tone: SnackTone.error);
      },
      (Duration _) {
        final AudioRecording? completed = widget.recorder.completed;
        if (completed != null) {
          widget.onCompleted?.call(completed);
        }
      },
    );
  }
}

/// Space between the capture page's blocks (FBK0000128).
const Widget _blockGap = SizedBox(height: Space.x4);

bool _sameContext(Map<String, String> left, Map<String, String> right) {
  if (left.length != right.length) return false;
  for (final MapEntry<String, String> entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/markup_ink.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/audio/audio_recorder_service.dart';
import 'package:tapture/core/barcode/barcode_scanner_service.dart';
import 'package:tapture/core/camera/camera_preview_surface.dart';
import 'package:tapture/core/camera/camera_service.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/image_redaction.dart';
import 'package:tapture/core/files/document_picker.dart' as platform;
import 'package:tapture/core/files/image_resize.dart';
import 'package:tapture/core/files/photo_picker.dart';
import 'package:tapture/core/files/photo_privacy_service.dart';
import 'package:tapture/core/files/photo_thumbnails.dart';
import 'package:tapture/core/files/storage_guard.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/location/location_service.dart';
import 'package:tapture/core/network/offline_now.dart';
import 'package:tapture/core/speech/speech_readiness_notifier.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/photo_source_sheet.dart';
import 'package:tapture/core/widgets/responsive/responsive_pair.dart';
import 'package:tapture/core/widgets/state_refresh.dart';
import 'package:tapture/features/capture/domain/audio_draft.dart';
import 'package:tapture/features/capture/domain/caption_apply.dart';
import 'package:tapture/features/capture/domain/capture_photo_repository.dart';
import 'package:tapture/features/capture/domain/capture_record_persistence.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/capture_session_key.dart';
import 'package:tapture/features/capture/domain/capture_template_choice.dart';
import 'package:tapture/features/capture/domain/document_draft.dart';
import 'package:tapture/features/capture/domain/gps_capture.dart';
import 'package:tapture/features/capture/domain/pending_audio_draft.dart';
import 'package:tapture/features/capture/domain/photo_derivation.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_repository.dart';
import 'package:tapture/features/capture/domain/photo_rotate.dart';
import 'package:tapture/features/capture/domain/save_and_analyse.dart';
import 'package:tapture/features/capture/presentation/audio_recorder.dart';
import 'package:tapture/features/capture/presentation/barcode_scanner_screen.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/capture/presentation/capture_document_viewer.dart';
import 'package:tapture/features/capture/presentation/capture_guide_card.dart';
import 'package:tapture/features/capture/presentation/capture_guide_state.dart';
import 'package:tapture/features/capture/presentation/capture_photo_intake.dart';
import 'package:tapture/features/capture/presentation/capture_providers.dart';
import 'package:tapture/features/capture/presentation/capture_recovery_prompt.dart';
import 'package:tapture/features/capture/presentation/capture_storage_guard.dart';
import 'package:tapture/features/capture/presentation/capture_target_fields.dart';
import 'package:tapture/features/capture/presentation/capture_transcribe_button.dart';
import 'package:tapture/features/capture/presentation/document_picker.dart';
import 'package:tapture/features/capture/presentation/gallery_picker.dart';
import 'package:tapture/features/capture/presentation/import_capture_document.dart';
import 'package:tapture/features/capture/presentation/inline_fields_section.dart';
import 'package:tapture/features/capture/presentation/live_camera_screen.dart';
import 'package:tapture/features/capture/presentation/photo_crop_screen.dart';
import 'package:tapture/features/capture/presentation/photo_delete_action.dart';
import 'package:tapture/features/capture/presentation/photo_doodle_screen.dart';
import 'package:tapture/features/capture/presentation/photo_redaction_screen.dart';
import 'package:tapture/features/capture/presentation/photo_tray.dart';
import 'package:tapture/features/capture/presentation/photo_type_screen.dart';
import 'package:tapture/features/capture/presentation/photo_viewer_screen.dart';
import 'package:tapture/features/capture/presentation/record_caption_field.dart';
import 'package:tapture/features/context/context.dart';
import 'package:tapture/features/processing/processing.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/reference/reference.dart';
import 'package:tapture/features/templates/templates.dart';
import 'package:tapture/features/transcripts/transcripts.dart'
    show
        LiveTranscriptKey,
        LiveTranscriptPanel,
        LiveTranscriptStatus,
        TranscriptSessionPhase,
        TranscriptSessionTarget,
        liveTranscriptControllerProvider;

export 'capture_target_fields.dart' show captureProjectTemplatesProvider;

part 'capture_screen_documents.dart';
part 'capture_screen_form.dart';
part 'capture_screen_sessions.dart';

/// Templates for the open project, read through the templates barrel.
final StreamProvider<List<TemplateDef>> captureTemplatesProvider =
    StreamProvider<List<TemplateDef>>((Ref ref) {
      final String? projectId = ref.watch(currentProjectProvider);
      if (projectId == null || projectId.isEmpty) {
        return Stream<List<TemplateDef>>.value(const <TemplateDef>[]);
      }
      return ref.watch(templateRepositoryProvider).watchByProject(projectId);
    });

/// The screen's own state for one session key: the next audio id, whether a
/// save is running, how many captions have been added to photos (which
/// resets the caption field after each add), and whether the stored copy of
/// the session has been checked for an interrupted run.
typedef _CaptureUiState = ({
  String audioId,
  bool saving,
  int captionAdds,
  bool checked,
});

/// Lives as long as a capture page shows the session, so each visit checks
/// the stored copy afresh.
final _captureUiProvider = NotifierProvider.autoDispose
    .family<_CaptureUiController, _CaptureUiState, String>(
      _CaptureUiController.new,
    );

final class _CaptureUiController extends Notifier<_CaptureUiState> {
  _CaptureUiController(String _);

  IdService get _ids => ref.read(captureIdsProvider);

  @override
  _CaptureUiState build() {
    return (
      audioId: _ids.newId(),
      saving: false,
      captionAdds: 0,
      checked: false,
    );
  }

  void renewAudioId() => _set(audioId: _ids.newId());

  void setSaving(bool saving) => _set(saving: saving);

  void captionAdded() => _set(captionAdds: state.captionAdds + 1);

  /// The stored copy has been checked; the page may now write the session.
  void checked() => _set(checked: true);

  void _set({String? audioId, bool? saving, int? captionAdds, bool? checked}) {
    state = (
      audioId: audioId ?? state.audioId,
      saving: saving ?? state.saving,
      captionAdds: captionAdds ?? state.captionAdds,
      checked: checked ?? state.checked,
    );
  }
}

/// Capture surface: tray, caption, template choice, saves. With a
/// [recordId] it edits that saved record's photos, captions and audio
/// instead, and saves them back to it (FBK0000148).
///
/// Only a project is needed to capture, and only one piece of evidence to
/// save (STANDARD rule 3). An interrupted session found on opening is
/// offered back before anything on the page can write, so a fresh session
/// never overwrites it (task 012 step 19, task 073).
final class CaptureScreen extends ConsumerStatefulWidget {
  /// Creates the screen for [projectId].
  const CaptureScreen({required this.projectId, this.recordId, super.key});

  /// Open project. Empty on the Capture tab root.
  final String projectId;

  /// The saved record to edit. Null captures a new record.
  final String? recordId;

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen>
    with StateRefresh {
  final Set<String> _selected = <String>{};
  final Map<String, Uint8List> _bytes = <String, Uint8List>{};
  final Map<String, String> _thumbs = <String, String>{};
  final Map<String, Uint8List> _thumbnailBytes = <String, Uint8List>{};
  final Set<String> _missing = <String>{};
  String? _derivationNotice;
  bool _onStage = true;
  String? _chosen;
  String? _locationSession;

  /// The session key whose stored copy is being checked, so one check runs
  /// per key; [_captureUiProvider] records when it is done.
  String? _checkingKey;

  /// What the open photo preview shows, set again after each new version so
  /// the preview follows crop, draw, type-on and revert (FBK0000150).
  final ValueNotifier<List<PhotoDraft>> _viewerPhotos =
      ValueNotifier<List<PhotoDraft>>(const <PhotoDraft>[]);

  /// The last markup ink and size, offered again by Draw and type-on for
  /// the rest of this visit (FE-SIMP-05).
  MarkupInk _markupInk = MarkupInk.red;
  int _markupSize = 1;

  void _keepMarkupStyle(MarkupInk ink, int size) {
    _markupInk = ink;
    _markupSize = size;
  }

  @override
  void deactivate() {
    unawaited(_persist());
    super.deactivate();
  }

  @override
  void dispose() {
    _viewerPhotos.dispose();
    super.dispose();
  }

  bool get _editing => widget.recordId != null;

  /// The session this page works on: the project's new capture, or the
  /// record's edit, which is stored apart from it (D6).
  String _sessionKey() {
    final String? recordId = widget.recordId;
    return recordId == null ? _projectId() : CaptureSessionKey.edit(recordId);
  }

  void _showNewestInViewer() {
    _viewerPhotos.value = _activePhotos(
      ref.read(captureControllerProvider(_sessionKey())),
    );
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
    refresh(() => _chosen = id);
    ref.read(currentProjectProvider.notifier).open(id);
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    ref.watch(currentProjectProvider);
    final String projectId = _projectId();
    final String key = _sessionKey();
    final _CaptureUiState uiState = ref.watch(_captureUiProvider(key));
    // Each live transcript take gets its own audio id: the next one starts
    // once a take is filed or let go (task 125).
    ref.listen<LiveTranscriptStatus>(
      liveTranscriptControllerProvider(LiveTranscriptKey.capture(key)),
      (LiveTranscriptStatus? previous, LiveTranscriptStatus next) {
        if (_liveTakeEnded(previous, next)) {
          ref.read(_captureUiProvider(key).notifier).renewAudioId();
        }
      },
    );
    if (_checkingKey != key && !uiState.checked) {
      // The stored copy of this session is checked, and an interrupted one
      // offered back, before anything on the page writes to it.
      _checkingKey = key;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_restore(key));
      });
    }
    final AsyncValue<List<TemplateDef>> templateState = ref.watch(
      captureProjectTemplatesProvider(projectId),
    );
    // Most recently used first, then by name (task 012 step 22).
    final List<TemplateDef> templates = CaptureTemplateChoice.ordered(
      templateState.asData?.value ?? const <TemplateDef>[],
      recentIds:
          ref.watch(captureRecentTemplatesProvider(projectId)).asData?.value ??
          const <String>[],
    );
    final CaptureSession session = ref.watch(captureControllerProvider(key));
    final bool settled = uiState.checked;
    if (!_editing && settled && session.id != _locationSession) {
      _locationSession = session.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_captureLocation(session.id, key));
      });
    }
    // Only a project is needed to capture (STANDARD rule 3). An edit is
    // ready once its record has loaded; its template and context are the
    // record's own and stay as they are.
    final bool ready = _editing
        ? session.projectId.isNotEmpty
        : projectId.isNotEmpty && settled;
    final bool visible = _visible(context);
    if (_onStage && !visible) {
      _onStage = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_persist());
      });
    } else if (visible) {
      _onStage = true;
    }
    final CaptureController controller = ref.read(
      captureControllerProvider(key).notifier,
    );
    final ContextState? activeContext = _projectId().isEmpty
        ? null
        : ref.watch(projectContextProvider(_projectId())).asData?.value;
    // Where capture is now: the live context, or the session's own until
    // the live one has loaded.
    final Map<String, String> place = activeContext == null
        ? session.contextSnapshot
        : <String, String>{...activeContext.values, ...activeContext.pinned};
    if (activeContext != null && !_editing && settled) {
      if (!_sameContext(session.contextSnapshot, place)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(controller.setContext(place));
        });
      }
    }
    final Project? project = ref.watch(currentProjectDetailsProvider);
    // A template pinned to this place applies whenever capture is here
    // again (spec section 14, task 012 step 22).
    final String? placePin = _editing
        ? null
        : project?.settings.templatePinFor(place);
    final String? templateId = CaptureTemplateChoice.resolve(
      templateIds: <String>[
        for (final TemplateDef template in templates) template.id,
      ],
      selection: ref.watch(projectTemplateSelectionProvider),
      sessionTemplateId: session.templateId,
      choice: project?.settings.templateChoice,
      contextPin: placePin,
    );
    if (!_editing &&
        settled &&
        templateId != null &&
        (session.templateId != templateId ||
            (session.templateVersion == null && !session.hasContent))) {
      final TemplateDef selected = templates.firstWhere(
        (TemplateDef template) => template.id == templateId,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(
            controller.setTemplate(templateId, version: selected.version),
          );
        }
      });
    }
    final bool offline = ref.watch(offlineNowProvider);
    // What the chosen template asks for (FBK0000157, D14).
    CaptureGuide guide = const CaptureGuide(
      photoFields: <String>[],
      captionFields: <String>[],
    );
    List<FieldDef> fields = const <FieldDef>[];
    for (final TemplateDef template in templates) {
      if (template.id == templateId) {
        final TemplateDef? shape =
            session.templateId == template.id && session.templateVersion != null
            ? TemplateVersioning.shapeFor(template, session.templateVersion!)
            : template;
        if (shape == null) continue;
        guide = CaptureGuide.of(shape);
        fields = shape.fields.where((FieldDef field) => !field.hidden).toList();
      }
    }
    final CaptureGuideView guideView = ref.watch(captureGuideStateProvider);
    final List<String> captionTargets = _captionTargets(session);
    final String title = _editing
        ? localCopy.recordEditTitle
        : localCopy.navCapture;
    // With no project there is nothing to file under: the target fields say
    // so and offer the next step, and nothing else is drawn.
    final bool noProject = !_editing && projectId.isEmpty;
    return AppPage(
      key: const ValueKey<String>('route-capture'),
      title: title,
      showAppBar: false,
      overflow: _editing || projectId.isEmpty
          ? const <AppOverflowAction>[]
          : <AppOverflowAction>[
              if (ready && fields.isNotEmpty)
                AppOverflowAction(
                  key: const ValueKey<String>('capture-manual-form'),
                  label: localCopy.captureManualForm,
                  icon: AppIcons.edit,
                  onTap: () => unawaited(_manualForm(key, projectId)),
                ),
              if (ready && project != null)
                AppOverflowAction(
                  key: const ValueKey<String>('capture-import-document'),
                  label: localCopy.captureImportDocument,
                  icon: AppIcons.import,
                  onTap: () => unawaited(_importDocument(project, key)),
                ),
              // The session pin is the template field; this one outlives
              // the session, for this place only.
              if (project != null &&
                  templateId != null &&
                  placePin != templateId &&
                  ProjectSettings.templatePinKey(place) != null)
                AppOverflowAction(
                  key: const ValueKey<String>('capture-pin-template'),
                  label: localCopy.templateChoicePin,
                  icon: AppIcons.pin,
                  onTap: () =>
                      unawaited(_pinTemplateHere(project, templateId, place)),
                ),
            ],
      footer: noProject
          ? null
          : _editing
          ? AppPrimaryAction(
              key: const ValueKey<String>('record-edit-save'),
              label: localCopy.recordEditSave,
              busy: uiState.saving,
              onPressed: ready ? () => unawaited(_saveEdits()) : null,
            )
          // One level row at every width, the two the same width; the
          // primary is marked by its fill and its place at the end
          // (FBK0000004, FBK0000158, FE-SIMP-01).
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ResponsivePair(
                  key: const ValueKey<String>('capture-saves'),
                  stacksOnCompact: false,
                  matchesHeights: true,
                  gap: Space.x2,
                  start: AppButton(
                    label: localCopy.captureSaveRaw,
                    variant: AppButtonVariant.secondary,
                    expand: true,
                    busy: uiState.saving,
                    onPressed: ready ? () => unawaited(_save(false)) : null,
                  ),
                  end: AppPrimaryAction(
                    label: localCopy.captureSaveAndAnalyse,
                    busy: uiState.saving,
                    onPressed: ready && !offline
                        ? () => unawaited(_save(true))
                        : null,
                  ),
                ),
                // Processing waits for a network; Save raw keeps capture
                // unblocked meanwhile (D3). Under the row, so both buttons
                // stay one height.
                if (offline) ...<Widget>[
                  const SizedBox(height: Space.x1),
                  Text(
                    localCopy.captureProcessNeedsNetwork,
                    key: const ValueKey<String>('capture-saves-offline'),
                    style: AppText.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Free space: nothing while ample; a warning, or the stop with
          // Export, below the thresholds (task 012 step 21).
          CaptureStorageGuard(projectId: projectId),
          // An edit keeps the record's project and template.
          if (!_editing) ...<Widget>[
            CaptureTargetFields(
              selectedProjectId: projectId,
              templates: templates,
              templatesLoaded: templateState.hasValue,
              templateId: templateId,
              onProjectSelected: _chooseProject,
            ),
            if (!noProject) _blockGap,
          ],
          if (!noProject)
            ..._evidence(
              session: session,
              controller: controller,
              uiState: uiState,
              project: project,
              ready: ready,
              templateId: templateId,
              guide: guide,
              guideView: guideView,
              captionTargets: captionTargets,
            ),
        ],
      ),
    );
  }

  /// The tray, caption and audio: everything evidence is added through once
  /// there is a project to file it under.
  List<Widget> _evidence({
    required CaptureSession session,
    required CaptureController controller,
    required _CaptureUiState uiState,
    required Project? project,
    required bool ready,
    required String? templateId,
    required CaptureGuide guide,
    required CaptureGuideView guideView,
    required List<String> captionTargets,
  }) {
    final LocalizedCopy localCopy = Copy.of(context);
    // With a speech model ready the caption recorder also transcribes, on
    // this device (task 125); a take already running keeps its controls
    // whatever the readiness. Without one it is the plain recorder.
    final String key = _sessionKey();
    final LiveTranscriptStatus liveStatus = ref.watch(
      liveTranscriptControllerProvider(LiveTranscriptKey.capture(key)),
    );
    final TranscriptSessionTarget? liveTarget = project == null
        ? null
        : ref.watch(captureTranscriptTargetProvider(key))(
            _pendingTake(project, uiState.audioId),
          );
    final bool live =
        liveTarget != null &&
        (ref.watch(speechReadinessProvider).ready ||
            _holdsLiveTake(liveStatus, session));

    return <Widget>[
      if (!guide.isEmpty) ...<Widget>[
        CaptureGuideCard(guide: guide),
        _blockGap,
      ],
      PhotoTray(
        photos: _activePhotos(session),
        captions: session.captions,
        selectedIds: _selected,
        thumbPaths: _thumbs,
        thumbBytes: kIsWeb ? _thumbnailBytes : const <String, Uint8List>{},
        missingIds: _missing,
        onAdd: ready ? _add : null,
        onLongPress: (PhotoDraft photo) {
          refresh(() {
            if (!_selected.add(photo.id)) {
              _selected.remove(photo.id);
            }
          });
        },
        onTap: (PhotoDraft photo) => _openViewer(session, photo),
        onRemove: (PhotoDraft photo) {
          unawaited(
            PhotoDeleteAction.run(
              context: context,
              photo: photo,
              delete: (String id) async {
                final Result<PhotoDraft?> removed = await controller
                    .removePhoto(id);
                return removed.fold((Failure failure) {
                  if (mounted) {
                    showAppSnack(
                      context,
                      failure.message,
                      tone: SnackTone.error,
                      localizedMessage: failure.explanation,
                    );
                  }
                  return null;
                }, (PhotoDraft? value) => value);
              },
              undo: (PhotoDraft removed) async {
                final Result<void> restored = await controller.undoRemove(
                  removed,
                );
                if (restored is FailureResult<void> && mounted) {
                  showAppSnack(
                    context,
                    restored.failure.message,
                    tone: SnackTone.error,
                    localizedMessage: restored.failure.explanation,
                  );
                }
              },
            ),
          );
        },
      ),
      _blockGap,
      if (project != null && ready) ...<Widget>[
        if (_editing)
          DocumentPicker(
            onImported: (Uint8List bytes, String name) =>
                _documentImported(project, bytes, name),
          ),
        for (final DocumentDraft document in session.documents)
          AppButton(
            label: document.originalFilename,
            variant: AppButtonVariant.secondary,
            onPressed: document.canRenderPages
                ? () => _openDocument(project, document)
                : null,
          ),
        if (_editing || session.documents.isNotEmpty) _blockGap,
      ],
      RecordCaptionField(
        enabled: ready,
        // Typing and dictation write the record's own caption only; a
        // photo gets the text from the add button below (FBK0000155).
        value: session.recordCaption,
        resetKey: uiState.captionAdds,
        guide: templateId == null || guideView.closedFor == templateId
            ? const <String>[]
            : guide.captionFields,
        onCloseGuide: templateId == null
            ? null
            : () => ref
                  .read(captureGuideStateProvider.notifier)
                  .closePanelFor(templateId),
        recorder: ref.watch(audioRecorderServiceProvider),
        liveRecording:
            live &&
            (liveStatus.phase == TranscriptSessionPhase.recording ||
                liveStatus.phase == TranscriptSessionPhase.paused),
        onChanged: (String text) async {
          final Result<void> result = await controller.setCaption(null, text);
          return result is Success<void>;
        },
        onWriteFailed: (String _) {
          final LocalizedCopy localCopy = Copy.of(context);

          showAppSnack(
            context,
            localCopy.captureSaveFailed,
            tone: SnackTone.error,
          );
        },
        afterDictation: live
            ? CaptureTranscribeButton(target: liveTarget, enabled: ready)
            : _RecordAudioButton(
                enabled: ready,
                recorder: ref.watch(audioRecorderServiceProvider),
                relativePath: project == null
                    ? null
                    : 'projects/${project.folderName}/audio/${uiState.audioId}.wav',
                beforeStart: project == null
                    ? null
                    : () => _stageAudio(project),
                onCompleted: (AudioRecording recording) =>
                    unawaited(_audioStopped(recording)),
              ),
      ),
      if (captionTargets.isNotEmpty) ...<Widget>[
        const SizedBox(height: Space.x2),
        AppButton(
          key: const ValueKey<String>('capture-caption-add'),
          label: _anyTicked(session)
              ? localCopy.captionAddToTicked(captionTargets.length)
              : localCopy.captionAddToAll(captionTargets.length),
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: ready && session.recordCaption.trim().isNotEmpty
              ? () => unawaited(_addCaption())
              : null,
        ),
      ],
      // The recorder block carries its own gap and is empty while idle.
      if (project != null) ...<Widget>[
        AudioRecorder(
          recorder: ref.watch(audioRecorderServiceProvider),
          relativePath:
              'projects/${project.folderName}/audio/${uiState.audioId}.wav',
          onCompleted: (AudioRecording recording) =>
              unawaited(_audioStopped(recording)),
        ),
        if (live && _showsLiveTake(liveStatus, session)) ...<Widget>[
          const SizedBox(height: Space.x2),
          LiveTranscriptPanel(target: liveTarget, showIdleControls: false),
        ],
        if (session.audio.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.x2),
          Text(
            localCopy.captureAudioCount(session.audio.length),
            style: AppText.caption,
          ),
        ],
      ],
    ];
  }

  Future<void> _add() async {
    if (!await _admitted()) {
      return;
    }
    final PhotoPicker picker = ref.read(photoPickerProvider);
    final CameraService camera = ref.read(cameraServiceProvider);
    if (!mounted) {
      return;
    }
    final Result<List<Uint8List>>? picked = await showPhotoSourceSheet(
      context,
      picker: picker,
      takePhoto: camera is CameraPreviewSurface
          ? () async {
              // Full screen, over the shell's chrome.
              await Navigator.of(context, rootNavigator: true).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => LiveCameraScreen(
                    camera: camera,
                    onCaptured: (Uint8List bytes) =>
                        _storePhoto(bytes, derivedFrom: null, notify: false),
                    // Tombstoned, so the file stays recoverable.
                    onRetake: (PhotoDraft photo) async =>
                        (await ref
                                .read(
                                  captureControllerProvider(
                                    _sessionKey(),
                                  ).notifier,
                                )
                                .removePhoto(photo.id))
                            .map<void>((PhotoDraft? _) {}),
                    onCorrected: _commitDerived,
                  ),
                ),
              );
              return const Success<List<Uint8List>>(<Uint8List>[]);
            }
          : null,
      limit: GalleryPicker.defaultLimit,
      longEdge: GalleryPicker.defaultLongEdge,
    );
    if (picked != null) {
      await _imported(picked);
    }
  }

  Future<void> _scan(FieldDef field, {String? sessionKey}) async {
    final String key = sessionKey ?? _sessionKey();
    final String? code = await Navigator.of(context, rootNavigator: true)
        .push<String>(
          MaterialPageRoute<String>(
            builder: (BuildContext context) => BarcodeScannerScreen(
              scanner: ref.read(barcodeScannerServiceProvider),
              onConfirmed: (String code) => Navigator.of(context).pop(code),
            ),
          ),
        );
    if (!mounted || code == null) return;
    await ref
        .read(captureControllerProvider(key).notifier)
        .setValue(field.fieldKey, code, source: 'BARCODE');
    if (mounted && field.lookup.isNotEmpty) {
      await _lookup(field, sessionKey: key);
    }
  }

  Future<void> _lookup(FieldDef field, {String? sessionKey}) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final LookupBinding? binding = LookupBinding.fromMap(field.lookup);
    if (binding == null) return;
    final CaptureController controller = ref.read(
      captureControllerProvider(sessionKey ?? _sessionKey()).notifier,
    );
    final CaptureSession session = ref.read(
      captureControllerProvider(sessionKey ?? _sessionKey()),
    );
    final String query =
        '${session.values[field.fieldKey] ?? session.contextSnapshot[field.fieldKey] ?? ''}';
    final ReferenceRepository referenceStore = ref.read(
      referenceRepositoryProvider,
    );
    final Result<ReferenceDataset?> loaded = await referenceStore.byId(
      binding.datasetId,
    );
    if (!mounted) return;
    final ReferenceDataset? dataset = loaded is Success<ReferenceDataset?>
        ? loaded.value
        : null;
    if (dataset == null) {
      showAppSnack(
        context,
        localCopy.datasetsBrowserEmptyMessage,
        tone: SnackTone.warning,
      );
      return;
    }
    final Result<LookupSearchResult> found = await LookupSearch.find(
      repository: referenceStore,
      binding: binding,
      dataset: dataset,
      query: query,
    );
    if (!mounted) return;
    if (found is FailureResult<LookupSearchResult>) {
      showAppSnack(
        context,
        found.failure.message,
        tone: SnackTone.error,
        localizedMessage: found.failure.explanation,
      );
      return;
    }
    final LookupSearchResult result =
        (found as Success<LookupSearchResult>).value;
    ReferenceRow? selected;
    if (result.matches.isEmpty) {
      if (binding.onNoMatch == NoMatchBehaviour.promptAddRow) {
        selected = await showDatasetAddRowSheet(
          context: context,
          datasetId: dataset.id,
          keyColumn: dataset.keyColumn,
          binding: binding,
        );
      } else if (binding.onNoMatch == NoMatchBehaviour.warn) {
        showAppSnack(
          context,
          localCopy.datasetsBrowserEmptyMessage,
          tone: SnackTone.warning,
        );
      }
    } else if (result.matches.length == 1 && !result.suggested) {
      selected = result.matches.single;
    } else {
      selected = await showLookupPickerSheet(
        context: context,
        matches: result.matches,
        distinguishColumns: dataset.columns,
      );
    }
    if (!mounted || selected == null) return;
    final Result<void> saved = await controller.applyLookup(<String, String>{
      for (final MapEntry<String, String> entry in binding.fillMapping.entries)
        entry.value: selected.values[entry.key] ?? '',
    }, selected.id);
    if (mounted && saved is FailureResult<void>) {
      showAppSnack(
        context,
        saved.failure.message,
        tone: SnackTone.error,
        localizedMessage: saved.failure.explanation,
      );
    }
  }

  Future<void> _imported(Result<List<Uint8List>> result) async {
    switch (result) {
      case FailureResult<List<Uint8List>>(:final Failure failure):
        if (mounted) {
          showAppSnack(
            context,
            failure.message,
            tone: SnackTone.error,
            localizedMessage: failure.explanation,
          );
        }
      case Success<List<Uint8List>>(:final List<Uint8List> value):
        for (final Uint8List bytes in value) {
          await _storePhoto(bytes, derivedFrom: null);
        }
    }
  }

  /// Stores [bytes] as the next photo and hands back what was stored. A
  /// failure is shown here unless [notify] is off because the caller, the
  /// live camera, says it itself.
  Future<Result<PhotoDraft>> _storePhoto(
    Uint8List bytes, {
    required String? derivedFrom,
    bool notify = true,
  }) async {
    final Result<PhotoDraft> saved = await CapturePhotoIntake.store(
      ref,
      sessionKey: _sessionKey(),
      projectId: _projectId(),
      bytes: bytes,
      derivedFrom: derivedFrom,
    );
    switch (saved) {
      case FailureResult<PhotoDraft>(:final Failure failure):
        if (notify && mounted) {
          showAppSnack(
            context,
            failure.message,
            tone: SnackTone.error,
            localizedMessage: failure.explanation,
          );
        }
      case Success<PhotoDraft>(:final PhotoDraft value):
        if (mounted) {
          refresh(() => _bytes[value.id] = bytes);
          unawaited(_refreshThumbs(<PhotoDraft>[value]));
        }
    }
    return saved;
  }

  /// Whether a new capture may start: refused only when the device is known
  /// to be full, with the reason and the way out (task 012 step 21).
  Future<bool> _admitted() async {
    final Result<HeadroomState>? admitted = await CapturePhotoIntake.admit(ref);
    if (admitted case FailureResult<HeadroomState>(:final Failure failure)) {
      if (mounted) {
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
      }
      return false;
    }
    return mounted;
  }

  /// Stamps a fix on [sessionId] when the project uses GPS. A slow or
  /// missing fix never holds up a save: nothing awaits this.
  Future<void> _captureLocation(String sessionId, String sessionKey) async {
    final Project? project = ref.read(currentProjectDetailsProvider);
    final Result<GeoFix?> result = await GpsCapture.maybeFix(
      // A project with no GPS preference of its own leaves the choice to
      // the location service, which reads the device setting.
      gpsEnabled: project?.settings.gpsEnabled ?? true,
      location: ref.read(locationServiceProvider),
    );
    if (!mounted || result is! Success<GeoFix?> || result.value == null) return;
    await ref
        .read(captureControllerProvider(sessionKey).notifier)
        .setLocation(result.value!, sessionId: sessionId);
  }

  /// Adds the typed caption after each target photo's own caption (D6),
  /// then clears the field and says how many photos got it (D7). A failed
  /// add keeps the typed text (FE-SIMP-09).
  Future<void> _addCaption() async {
    final LocalizedCopy localCopy = Copy.of(context);

    final CaptureController controller = ref.read(
      captureControllerProvider(_sessionKey()).notifier,
    );
    final CaptureSession session = ref.read(
      captureControllerProvider(_sessionKey()),
    );
    final String text = session.recordCaption.trim();
    final List<String> targets = _captionTargets(session);
    if (text.isEmpty || targets.isEmpty) {
      return;
    }
    final Result<void> added = await controller.applyCaptions(
      CaptionApply.apply(
        photoIds: targets,
        text: text,
        mode: CaptionApplyMode.append,
        existing: session.captions,
      ),
    );
    if (!mounted) {
      return;
    }
    if (added is FailureResult<void>) {
      showAppSnack(context, localCopy.captureSaveFailed, tone: SnackTone.error);
      return;
    }
    final Result<void> cleared = await controller.setCaption(null, '');
    if (!mounted) {
      return;
    }
    if (cleared is Success<void>) {
      ref.read(_captureUiProvider(_sessionKey()).notifier).captionAdded();
    }
    showAppSnack(
      context,
      localCopy.captionAdded(targets.length),
      tone: SnackTone.success,
    );
  }

  /// Whether any photo in the tray is ticked.
  bool _anyTicked(CaptureSession session) {
    return _activePhotos(
      session,
    ).any((PhotoDraft photo) => _selected.contains(photo.id));
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
        if (_derivationNotice != Copy.of(context).failureMessage(failure)) {
          _derivationNotice = Copy.of(context).failureMessage(failure);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              showAppSnack(
                context,
                failure.message,
                tone: SnackTone.error,
                localizedMessage: failure.explanation,
              );
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
      captureControllerProvider(_sessionKey()).notifier,
    );
    _viewerPhotos.value = photos;
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext routeContext) {
            return PhotoViewerScreen(
              photos: _viewerPhotos,
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
                            .read(captureControllerProvider(_sessionKey()))
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
                    localizedMessage: saved.failure.explanation,
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
              onRedact: ref.read(photoPrivacyServiceProvider) == null
                  ? null
                  : (PhotoDraft current) =>
                        unawaited(_redact(routeContext, current)),
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

  Future<Result<void>> _stageAudio(Project project) async {
    final _CaptureUiState uiState = ref.read(_captureUiProvider(_sessionKey()));
    return ref
        .read(captureControllerProvider(_sessionKey()).notifier)
        .stageAudio(_pendingTake(project, uiState.audioId));
  }

  /// The take [audioId] as it is staged before the microphone opens: its
  /// place in [project] and the photos it goes with, the ticked ones or
  /// else every photo shown.
  PendingAudioDraft _pendingTake(Project project, String audioId) {
    final CaptureSession session = ref.read(
      captureControllerProvider(_sessionKey()),
    );
    final List<PhotoDraft> visible = _activePhotos(session);
    final List<String> photoIds = _selected.isEmpty
        ? <String>[for (final PhotoDraft photo in visible) photo.id]
        : _selected.toList(growable: false);
    return PendingAudioDraft(
      id: audioId,
      projectId: _projectId(),
      relativePath: 'audio/$audioId.wav',
      storageRelativePath: 'projects/${project.folderName}/audio/$audioId.wav',
      photoIds: photoIds,
    );
  }

  Future<void> _audioStopped(AudioRecording recording) async {
    final Result<void> saved = await ref
        .read(captureControllerProvider(_sessionKey()).notifier)
        .publishAudio(recording);
    if (!mounted) return;
    switch (saved) {
      case FailureResult<void>(:final Failure failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
      case Success<void>():
        ref.read(_captureUiProvider(_sessionKey()).notifier).renewAudioId();
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
    final LocalizedCopy localCopy = Copy.of(routeContext);

    final Uint8List? bytes = await _readPhoto(photo);
    if (bytes == null) {
      if (mounted) {
        showAppSnack(context, localCopy.missingPhoto, tone: SnackTone.error);
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
            ink: _markupInk,
            size: _markupSize,
            onStyle: _keepMarkupStyle,
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

  Future<void> _redact(BuildContext routeContext, PhotoDraft photo) async {
    final LocalizedCopy localCopy = Copy.of(routeContext);

    final PhotoPrivacyService? privacy = ref.read(photoPrivacyServiceProvider);
    if (privacy == null) return;
    final Uint8List? bytes = await _readPhoto(photo);
    if (bytes == null || !routeContext.mounted) return;
    final Result<({Uint8List bytes, int width, int height})> preview =
        await ImageResize.preview(bytes);
    final Result<List<ImageRect>> marks = await privacy.marks(photo.id);
    if (!routeContext.mounted) return;
    if (preview is FailureResult<({Uint8List bytes, int width, int height})>) {
      showAppSnack(
        routeContext,
        preview.failure.message,
        tone: SnackTone.error,
        localizedMessage: preview.failure.explanation,
      );
      return;
    }
    if (marks is FailureResult<List<ImageRect>>) {
      showAppSnack(
        routeContext,
        marks.failure.message,
        tone: SnackTone.error,
        localizedMessage: marks.failure.explanation,
      );
      return;
    }
    final bool? saved = await Navigator.of(routeContext).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext _) => PhotoRedactionScreen(
          photoId: photo.id,
          preview:
              (preview as Success<({Uint8List bytes, int width, int height})>)
                  .value,
          marks: (marks as Success<List<ImageRect>>).value,
          privacy: privacy,
        ),
      ),
    );
    if (saved == true && routeContext.mounted) {
      showAppSnack(routeContext, localCopy.redactionSaved);
    }
  }

  Future<void> _revert(String photoId) async {
    final Result<void> reverted = await ref
        .read(captureControllerProvider(_sessionKey()).notifier)
        .revertPhoto(photoId);
    if (!mounted) {
      return;
    }
    switch (reverted) {
      case FailureResult<void>(:final Failure failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
      case Success<void>():
        refresh(() {
          _bytes.remove(photoId);
          _thumbs.remove(photoId);
          _thumbnailBytes.remove(photoId);
          _missing.remove(photoId);
        });
        _showNewestInViewer();
    }
  }

  Future<bool> _commitDerived(
    PhotoDraft source,
    PhotoDraft derived,
    Uint8List png,
  ) async {
    final Result<PhotoDraft> saved = await CapturePhotoIntake.storeDerived(
      ref,
      sessionKey: _sessionKey(),
      projectId: _projectId(),
      source: source,
      derived: derived,
      bytes: png,
    );
    if (!mounted) {
      return saved is Success<PhotoDraft>;
    }
    switch (saved) {
      case FailureResult<PhotoDraft>(:final Failure failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
        return false;
      case Success<PhotoDraft>(:final PhotoDraft value):
        refresh(() => _bytes[value.id] = png);
        _showNewestInViewer();
        unawaited(_refreshThumbs(<PhotoDraft>[value]));
        return true;
    }
  }

  Future<Uint8List?> _readPhoto(PhotoDraft photo) async {
    final Uint8List? cached = _bytes[photo.id];
    if (cached != null) {
      return cached;
    }
    final PhotoRepository photoStore = ref
        .read(capturePersistenceProvider)
        .photos;
    if (photoStore is! CapturePhotoRepository) {
      return null;
    }
    final Result<Uint8List> bytes = await photoStore.readBytes(photo);
    switch (bytes) {
      case FailureResult<Uint8List>():
        if (mounted) {
          refresh(() => _missing.add(photo.id));
        }
        return null;
      case Success<Uint8List>(:final Uint8List value):
        return value;
    }
  }

  Future<void> _refreshThumbs(List<PhotoDraft> photos) async {
    final PhotoRepository photoStore = ref
        .read(capturePersistenceProvider)
        .photos;
    if (photoStore is! CapturePhotoRepository) {
      return;
    }
    final Map<String, String> next = Map<String, String>.of(_thumbs);
    final Set<String> missing = Set<String>.of(_missing);
    for (final PhotoDraft photo in photos) {
      if (kIsWeb) {
        final Project? owner = await ref.read(
          projectByIdProvider(photo.projectId).future,
        );
        if (owner == null) {
          missing.add(photo.id);
          continue;
        }
        final Result<Uint8List> thumbnail = await ref
            .read(photoThumbnailsProvider)
            .bytesFor(
              sha256: photo.sha256,
              storagePath: 'projects/${owner.folderName}/${photo.relativePath}',
              edge: AppConstants.images.thumbnailEdge,
            );
        if (thumbnail is Success<Uint8List>) {
          _thumbnailBytes[photo.id] = thumbnail.value;
          missing.remove(photo.id);
        } else {
          missing.add(photo.id);
        }
        continue;
      }
      Result<String> thumb = await photoStore.cachedThumbnailPath(
        photo,
        edge: AppConstants.images.thumbnailEdge,
      );
      final Uint8List? held = _bytes[photo.id];
      if (thumb is FailureResult<String> && held != null) {
        thumb = await photoStore.cachedThumbnailForBytes(
          photo,
          held,
          edge: AppConstants.images.thumbnailEdge,
        );
      }
      if (thumb is FailureResult<String> && held == null) {
        final Result<Uint8List> read = await photoStore.readBytes(photo);
        if (read is Success<Uint8List>) {
          thumb = await photoStore.cachedThumbnailForBytes(
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
      refresh(() {
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
    final LocalizedCopy localCopy = Copy.of(routeContext);

    final Uint8List? bytes = await _readPhoto(photo);
    if (bytes == null) {
      if (mounted) {
        showAppSnack(context, localCopy.missingPhoto, tone: SnackTone.error);
      }
      return;
    }
    if (!routeContext.mounted) {
      return;
    }
    await Navigator.of(routeContext).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return PhotoTypeScreen(
            photo: photo,
            bytes: bytes,
            ink: _markupInk,
            size: _markupSize,
            onStyle: _keepMarkupStyle,
            onTyped: (PhotoDraft derived, Uint8List png) {
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
    this.beforeStart,
    this.onCompleted,
    this.enabled = true,
  });

  final AudioRecorderService recorder;
  final String? relativePath;
  final Future<Result<void>> Function()? beforeStart;
  final ValueChanged<AudioRecording>? onCompleted;

  /// When false, record and stop do not accept a press.
  final bool enabled;

  @override
  State<_RecordAudioButton> createState() => _RecordAudioButtonState();
}

class _RecordAudioButtonState extends State<_RecordAudioButton>
    with StateRefresh {
  AudioRecorderPhase _phase = AudioRecorderPhase.idle;
  StreamSubscription<AudioRecorderState>? _sub;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _sub = widget.recorder.state.listen((AudioRecorderState next) {
      if (mounted) {
        refresh(() => _phase = next.phase);
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
    final LocalizedCopy localCopy = Copy.of(context);

    final bool live = _live;
    return AppIconButton(
      key: const ValueKey<String>('capture-record-audio'),
      icon: live ? AppIcons.stop : AppIcons.recordAudio,
      semanticLabel: live
          ? localCopy.captureStopAudio
          : localCopy.captureRecordAudio,
      tooltip: live ? localCopy.captureStopAudio : localCopy.captureRecordAudio,
      outlined: false,
      onPressed:
          widget.enabled &&
              !_starting &&
              _phase != AudioRecorderPhase.permission &&
              _phase != AudioRecorderPhase.finalizing
          ? (live ? _stop : _start)
          : null,
    );
  }

  Future<void> _start() async {
    final LocalizedCopy localCopy = Copy.of(context);

    final String? path = widget.relativePath;
    if (path == null || path.isEmpty) {
      showAppSnack(context, localCopy.homeEmptyHeadline, tone: SnackTone.error);
      return;
    }
    if (_starting) return;
    refresh(() => _starting = true);
    try {
      final Result<void>? prepared = await widget.beforeStart?.call();
      if (!mounted) return;
      if (prepared case FailureResult<void>(:final Failure failure)) {
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
        return;
      }
      final Result<void> result = await widget.recorder.start(path);
      if (!mounted) return;
      result.fold((Failure failure) {
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
      }, (_) {});
    } finally {
      if (mounted) refresh(() => _starting = false);
    }
  }

  Future<void> _stop() async {
    final Result<Duration> stopped = await widget.recorder.stop();
    if (!mounted) {
      return;
    }
    stopped.fold(
      (Failure failure) {
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
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

/// Whether a live transcript take ended between [previous] and [next]:
/// filed, discarded, or failed with nothing left to save.
bool _liveTakeEnded(LiveTranscriptStatus? previous, LiveTranscriptStatus next) {
  final TranscriptSessionPhase? before = previous?.phase;
  if (before == null || before == next.phase) {
    return false;
  }
  return switch (next.phase) {
    TranscriptSessionPhase.idle || TranscriptSessionPhase.saved => true,
    TranscriptSessionPhase.failed => !next.retryable,
    _ => false,
  };
}

/// Whether the live take's panel shows: from its start until the record
/// its audio was filed in is saved, which leaves the clip out of
/// [session].
bool _showsLiveTake(LiveTranscriptStatus status, CaptureSession session) {
  final String? filed = status.attachmentId;
  return switch (status.phase) {
    TranscriptSessionPhase.idle => false,
    TranscriptSessionPhase.saved =>
      filed != null && session.audio.any((AudioDraft clip) => clip.id == filed),
    _ => true,
  };
}

/// Whether the live take still needs its controls once no model is ready:
/// while it is shown and has something left to save. A take filed into a
/// saved record, or one that failed with nothing to save, gives the caption
/// recorder back to the plain recorder (task 065).
bool _holdsLiveTake(LiveTranscriptStatus status, CaptureSession session) {
  if (status.phase == TranscriptSessionPhase.failed && !status.retryable) {
    return false;
  }
  return _showsLiveTake(status, session);
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

/// What a saved edit of a record did, handed back as the edit page's pop
/// result: how many photos it filed on the record, so the page that opened
/// the edit can offer to process the record again (task 014 step 5).
/// Leaving without saving pops with no result.
typedef CaptureEditOutcome = ({int photosAdded});

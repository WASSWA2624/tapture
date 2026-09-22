import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_picker.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/photo_markup.dart';
import 'package:tapture/features/capture/domain/caption_apply.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/capture/presentation/capture_recovery_prompt.dart';
import 'package:tapture/features/capture/presentation/gallery_picker.dart';
import 'package:tapture/features/capture/presentation/inline_fields_section.dart';
import 'package:tapture/features/capture/presentation/photo_caption_sheet.dart';
import 'package:tapture/features/capture/presentation/photo_crop_screen.dart';
import 'package:tapture/features/capture/presentation/photo_tray.dart';
import 'package:tapture/features/capture/presentation/photo_viewer_screen.dart';
import 'package:tapture/features/capture/presentation/record_caption_field.dart';
import 'package:tapture/features/capture/presentation/template_picker_sheet.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/templates/templates.dart';

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
  bool _restored = false;
  bool _askingTemplate = true;
  bool _onStage = true;
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

  @override
  Widget build(BuildContext context) {
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
      captureControllerProvider(widget.projectId),
    );
    final CaptureController controller = ref.read(
      captureControllerProvider(widget.projectId).notifier,
    );
    final List<TemplateDef> templates =
        ref.watch(captureTemplatesProvider).asData?.value ??
        const <TemplateDef>[];
    final String? choice = ref
        .watch(currentProjectDetailsProvider)
        ?.settings
        .templateChoice;
    final bool needsChoice = _needsChoice(templates, choice);
    if (!needsChoice &&
        (choice == null || choice == 'auto') &&
        templates.length == 1 &&
        session.templateId != templates.first.id) {
      final String id = templates.first.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(controller.setTemplate(id));
        }
      });
    }
    final Project? project = ref.watch(currentProjectDetailsProvider);
    final String title = widget.projectId.isEmpty
        ? Copy.navCapture
        : (project?.name ?? Copy.navProjects);
    final Widget? banner = widget.headroom;
    return AppPage(
      title: title,
      showAppBar: false,
      scrollable: true,
      footer: Row(
        children: <Widget>[
          Expanded(
            child: AppButton(
              label: Copy.captureSaveRaw,
              variant: AppButtonVariant.secondary,
              onPressed: widget.onSaveRaw,
            ),
          ),
          const SizedBox(width: Space.x2),
          Expanded(
            child: AppButton(
              label: Copy.captureSaveAndAnalyse,
              onPressed: widget.onSaveAndAnalyse,
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ?banner,
          if (needsChoice)
            TemplatePickerSheet(
              templates: <({String id, String name, int lastUsedMs})>[
                for (final TemplateDef template in templates)
                  (id: template.id, name: template.name, lastUsedMs: 0),
              ],
              pinnedId: _preselect(templates, session),
              onSelected: (String id) {
                setState(() => _askingTemplate = false);
                unawaited(controller.setTemplate(id));
              },
            ),
          PhotoTray(
            photos: session.photos,
            captions: session.captions,
            selectedIds: _selected,
            onAdd: needsChoice ? _ignore : (widget.onAddPhoto ?? _add),
            onLongPress: (PhotoDraft photo) {
              setState(() {
                if (!_selected.add(photo.id)) {
                  _selected.remove(photo.id);
                }
              });
            },
            onTap: (PhotoDraft photo) => _openViewer(session, photo),
          ),
          const SizedBox(height: Space.x3),
          RecordCaptionField(
            value: session.recordCaption,
            onChanged: (String text) async {
              final Result<void> result = await controller.setCaption(
                null,
                text,
              );
              return result.fold((Failure _) => false, (_) => true);
            },
            onWriteFailed: (String _) {
              showAppSnack(
                context,
                Copy.captureSaveFailed,
                tone: SnackTone.error,
              );
            },
          ),
          const SizedBox(height: Space.x2),
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

  bool _needsChoice(List<TemplateDef> templates, String? choice) {
    if (!_askingTemplate || templates.isEmpty) {
      return false;
    }
    if (choice == 'manual' || choice == 'suggest') {
      return true;
    }
    return templates.length > 1;
  }

  String? _preselect(List<TemplateDef> templates, CaptureSession session) {
    if (templates.isEmpty) {
      return null;
    }
    if (session.templateId.isNotEmpty &&
        templates.any((TemplateDef t) => t.id == session.templateId)) {
      return session.templateId;
    }
    return templates.first.id;
  }

  void _ignore() {}

  Future<void> _add() async {
    final PhotoPicker picker = ref.read(capturePhotoPickerProvider);
    if (!mounted) {
      return;
    }
    await showAppSheet<void>(
      context,
      title: Copy.captureAddSheetTitle,
      builder: (BuildContext sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (picker.canTakePhoto)
              AppListTile(
                title: Copy.captureTakePhoto,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(_take(picker));
                },
              ),
            AppListTile(
              title: Copy.captureChoosePhoto,
              onTap: () {
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
      projectId: widget.projectId,
      relativePath: 'photos/$id.jpg',
      sha256: sha256.convert(bytes).toString(),
      fileSize: bytes.length,
      mimeType: 'image/jpeg',
      derivedFrom: derivedFrom,
    );
    final Result<void> saved = await ref
        .read(captureControllerProvider(widget.projectId).notifier)
        .addPhoto(draft);
    if (!mounted) {
      return;
    }
    switch (saved) {
      case FailureResult<void>(:final Failure failure):
        showAppSnack(context, failure.message, tone: SnackTone.error);
      case Success<void>():
        setState(() => _bytes[id] = bytes);
    }
  }

  void _openViewer(CaptureSession session, PhotoDraft photo) {
    final int index = session.photos.indexWhere(
      (PhotoDraft row) => row.id == photo.id,
    );
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext routeContext) {
            return PhotoViewerScreen(
              photos: session.photos,
              initialIndex: index < 0 ? 0 : index,
              images: _bytes,
              onCaption: (PhotoDraft current) {
                Navigator.of(routeContext).pop();
                unawaited(_caption(session, current));
              },
              onCrop: (PhotoDraft current) {
                unawaited(_crop(routeContext, current));
              },
              onType: (PhotoDraft current) {
                unawaited(_type(routeContext, current));
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _caption(CaptureSession session, PhotoDraft photo) async {
    await showAppSheet<void>(
      context,
      title: Copy.capturePhotoCaption,
      builder: (BuildContext sheetContext) {
        return PhotoCaptionSheet(
          initial: session.captions[photo.id] ?? '',
          selectedCount: _selected.length,
          allCount: session.photos.length,
          onSave: (String text, CaptionScope scope) async {
            final List<String> ids = switch (scope) {
              CaptionScope.thisPhoto => <String>[photo.id],
              CaptionScope.selected => _selected.toList(),
              CaptionScope.all => <String>[
                for (final PhotoDraft row in session.photos) row.id,
              ],
            };
            final Result<void> result = await ref
                .read(captureControllerProvider(widget.projectId).notifier)
                .applyCaptions(<CaptionWrite>[
                  for (final String id in ids)
                    CaptionWrite(
                      photoId: id,
                      text: text,
                      previousText: session.captions[id],
                    ),
                ]);
            return result.fold((Failure _) => false, (_) => true);
          },
        );
      },
    );
  }

  Future<void> _crop(BuildContext routeContext, PhotoDraft photo) async {
    await Navigator.of(routeContext).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return PhotoCropScreen(
            photo: photo,
            bytes: _bytes[photo.id],
            onCropped: (PhotoDraft derived, Uint8List? png) {
              Navigator.of(context).pop();
              if (png != null) {
                unawaited(_storePhoto(png, derivedFrom: photo.id));
              }
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

  Future<void> _revert(String sourceId) async {
    final CaptureSession session = ref.read(
      captureControllerProvider(widget.projectId),
    );
    final CaptureController controller = ref.read(
      captureControllerProvider(widget.projectId).notifier,
    );
    for (final PhotoDraft photo in session.photos) {
      if (photo.derivedFrom == sourceId) {
        await controller.removePhoto(photo.id);
        _bytes.remove(photo.id);
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _type(BuildContext routeContext, PhotoDraft photo) async {
    final Uint8List? bytes = _bytes[photo.id];
    if (bytes == null) {
      showAppSnack(context, Copy.missingPhoto, tone: SnackTone.error);
      return;
    }
    final TextEditingController text = TextEditingController();
    await showAppSheet<void>(
      routeContext,
      title: Copy.photoTypeOn,
      builder: (BuildContext sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppTextField(label: Copy.photoTypeOn, controller: text),
            AppButton(
              label: Copy.save,
              onPressed: () async {
                final Uint8List png = await PhotoMarkup.typeOn(
                  bytes,
                  text.text,
                );
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                await _storePhoto(png, derivedFrom: photo.id);
              },
            ),
          ],
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
        .loadSession();
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
        widget.projectId.isNotEmpty &&
        session.projectId != widget.projectId) {
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
            unawaited(
              ref
                  .read(captureControllerProvider(widget.projectId).notifier)
                  .replaceSession(session),
            );
          },
          onDiscard: () async {
            await ref
                .read(captureControllerProvider(widget.projectId).notifier)
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
      captureControllerProvider(widget.projectId),
    );
    if (!_hasContent(session)) {
      return;
    }
    await ref.read(capturePersistenceProvider).saveSession(session);
  }

  bool _hasContent(CaptureSession session) {
    if (session.photos.isNotEmpty) {
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

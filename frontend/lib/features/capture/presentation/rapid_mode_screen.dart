import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/camera/camera_preview_surface.dart';
import 'package:tapture/core/camera/camera_service.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_picker.dart';
import 'package:tapture/core/files/storage_guard.dart';
import 'package:tapture/core/network/offline_now.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/photo_source_sheet.dart';
import 'package:tapture/core/widgets/responsive/content_constraint.dart';
import 'package:tapture/core/widgets/responsive/responsive_pair.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/capture/presentation/capture_photo_intake.dart';
import 'package:tapture/features/capture/presentation/capture_storage_guard.dart';
import 'package:tapture/features/capture/presentation/gallery_picker.dart';
import 'package:tapture/features/capture/presentation/live_camera_screen.dart';
import 'package:tapture/features/capture/presentation/rapid_run.dart';

/// Rapid mode (task 012 step 20, spec section 27): photograph an item, save
/// it raw and start the next in one tap, with the run listed as it grows.
///
/// Items share the capture session of [projectId], so context and pinned
/// template carry across them, and each saved item reopens for correction
/// on its record's edit page. Nothing is analysed until Process all.
final class RapidModeScreen extends ConsumerStatefulWidget {
  /// Creates rapid mode for [projectId].
  const RapidModeScreen({required this.projectId, super.key});

  /// The project the run captures into.
  final String projectId;

  @override
  ConsumerState<RapidModeScreen> createState() => _RapidModeScreenState();
}

class _RapidModeScreenState extends ConsumerState<RapidModeScreen> {
  /// Rows above the run: the storage notice and the item being captured.
  static const int _leading = 2;

  String get _projectId => widget.projectId;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final CaptureSession item = ref.watch(
      captureControllerProvider(_projectId),
    );
    final List<RapidCapture> items = ref.watch(rapidRunProvider(_projectId));
    final bool offline = ref.watch(offlineNowProvider);
    final int photos = item.photos
        .where((PhotoDraft photo) => photo.derivedFrom == null)
        .length;
    return AppPage(
      key: const ValueKey<String>('route-capture-rapid'),
      title: localCopy.captureRapidMode,
      scrollable: false,
      footer: ResponsivePair(
        key: const ValueKey<String>('rapid-actions'),
        stacksOnCompact: false,
        matchesHeights: true,
        gap: Space.x2,
        start: AppButton(
          label: localCopy.captureRapidProcessAll(items.length),
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: items.isEmpty || offline
              ? null
              : () => unawaited(_processAll()),
        ),
        end: AppPrimaryAction(
          key: const ValueKey<String>('rapid-next'),
          label: localCopy.captureRapidNext,
          onPressed: item.hasEvidence ? () => unawaited(_next()) : null,
        ),
      ),
      // One scrolling list: the storage notice, the item being captured,
      // then the run, built as it scrolls so a long run costs no more per
      // frame than a short one (FE-PERF-03).
      body: ContentConstraint(
        child: ListView.builder(
          key: const ValueKey<String>('rapid-items'),
          itemCount: _leading + (items.isEmpty ? 1 : items.length),
          itemBuilder: (BuildContext context, int index) {
            final LocalizedCopy localCopy = Copy.of(context);

            if (index == 0) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppPage.gutter(context),
                  vertical: Space.x2,
                ),
                child: CaptureStorageGuard(projectId: _projectId),
              );
            }
            if (index == 1) {
              return AppListTile(
                key: const ValueKey<String>('rapid-current'),
                wrapText: true,
                leading: const Icon(AppIcons.camera),
                title: localCopy.captureRapidCurrent(photos),
                trailing: const Icon(AppIcons.add),
                onTap: () => unawaited(_takePhotos()),
              );
            }
            if (items.isEmpty) {
              return AppEmptyState(
                icon: AppIcons.camera,
                headline: localCopy.captureRapidEmptyHeadline,
                message: localCopy.captureRapidEmptyMessage,
                actionLabel: localCopy.captureTakePhoto,
                onAction: () => unawaited(_takePhotos()),
              );
            }
            final int position = index - _leading;
            final RapidCapture saved = items[position];
            return AppListTile(
              key: ValueKey<String>('rapid-item-$position'),
              wrapText: true,
              title: localCopy.captureRapidItem(position + 1),
              subtitle: localCopy.captureRapidSummary(
                saved.photos,
                saved.caption,
              ),
              trailing: const Icon(AppIcons.open),
              onTap: () => unawaited(
                context.push(
                  RoutePaths.projectRecordEdit(_projectId, saved.recordId),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Saves this item raw and starts the next, then goes straight back to
  /// the camera for it. The new row in the run is the confirmation: a snack
  /// would sit over the button the next item is saved with.
  Future<void> _next() async {
    final Result<String> saved = await ref
        .read(rapidRunProvider(_projectId).notifier)
        .next();
    if (!mounted) {
      return;
    }
    switch (saved) {
      case FailureResult<String>(:final Failure failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
      case Success<String>():
        if (ref.read(cameraServiceProvider) is CameraPreviewSurface) {
          await _takePhotos();
        }
    }
  }

  Future<void> _processAll() async {
    final LocalizedCopy localCopy = Copy.of(context);

    final Result<int> queued = await ref
        .read(rapidRunProvider(_projectId).notifier)
        .processAll();
    if (!mounted) {
      return;
    }
    switch (queued) {
      case FailureResult<int>(:final Failure failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
      case Success<int>(:final int value):
        showAppSnack(
          context,
          localCopy.captureRapidQueued(value),
          tone: SnackTone.success,
        );
    }
  }

  /// Opens the live camera where there is one, and the add-photo sheet
  /// elsewhere. Each shot is written before the next is taken.
  Future<void> _takePhotos() async {
    final Result<HeadroomState>? admitted = await CapturePhotoIntake.admit(ref);
    if (!mounted) {
      return;
    }
    if (admitted case FailureResult<HeadroomState>(:final Failure failure)) {
      showAppSnack(
        context,
        failure.message,
        tone: SnackTone.error,
        localizedMessage: failure.explanation,
      );
      return;
    }
    final CameraService camera = ref.read(cameraServiceProvider);
    if (camera is CameraPreviewSurface) {
      await Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => LiveCameraScreen(
            camera: camera,
            onCaptured: _store,
            onRetake: (PhotoDraft photo) async =>
                (await ref
                        .read(captureControllerProvider(_projectId).notifier)
                        .removePhoto(photo.id))
                    .map((_) {}),
            onCorrected:
                (PhotoDraft original, PhotoDraft corrected, Uint8List bytes) =>
                    _storeCorrected(original, corrected, bytes),
          ),
        ),
      );
      return;
    }
    final Result<List<Uint8List>>? picked = await showPhotoSourceSheet(
      context,
      picker: ref.read(photoPickerProvider),
      limit: GalleryPicker.defaultLimit,
      longEdge: GalleryPicker.defaultLongEdge,
    );
    switch (picked) {
      case null:
        return;
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
          final Result<PhotoDraft> stored = await _store(bytes);
          if (stored case FailureResult<PhotoDraft>(:final Failure failure)) {
            if (mounted) {
              showAppSnack(
                context,
                failure.message,
                tone: SnackTone.error,
                localizedMessage: failure.explanation,
              );
            }
            return;
          }
        }
    }
  }

  Future<Result<PhotoDraft>> _store(Uint8List bytes) {
    return CapturePhotoIntake.store(
      ref,
      sessionKey: _projectId,
      projectId: _projectId,
      bytes: bytes,
    );
  }

  Future<bool> _storeCorrected(
    PhotoDraft original,
    PhotoDraft corrected,
    Uint8List bytes,
  ) async {
    final Result<PhotoDraft> stored = await CapturePhotoIntake.storeDerived(
      ref,
      sessionKey: _projectId,
      projectId: _projectId,
      source: original,
      derived: corrected,
      bytes: bytes,
    );
    return stored is Success<PhotoDraft>;
  }
}

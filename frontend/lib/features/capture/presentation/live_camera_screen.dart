import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/camera/camera.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/responsive/responsive_pair.dart';
import 'package:tapture/features/capture/domain/image_quality.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';

import 'camera_controls.dart';
import 'camera_permission_controller.dart';
import 'camera_permission_gate.dart';
import 'camera_view.dart';
import 'document_mode.dart';
import 'live_camera_controller.dart';
import 'live_camera_state.dart';

/// The full-screen live camera. It stays open for the next shot, and each
/// shot is stored through [onCaptured] before the shutter is enabled again
/// (§22.1). Quality and document advice arrive after the write and never
/// block it.
class LiveCameraScreen extends ConsumerWidget {
  /// Shoots with [camera].
  const LiveCameraScreen({
    required this.camera,
    required this.onCaptured,
    required this.onRetake,
    required this.onCorrected,
    super.key,
  });

  /// Live camera adapter.
  final CameraService camera;

  /// Writes one shot durably and returns the stored photo.
  final Future<Result<PhotoDraft>> Function(Uint8List bytes) onCaptured;

  /// Sets a flagged photo aside so the next shot takes its place.
  final Future<Result<void>> Function(PhotoDraft photo) onRetake;

  /// Stores a straightened copy beside its unchanged original; true once it
  /// is stored.
  final Future<bool> Function(
    PhotoDraft original,
    PhotoDraft corrected,
    Uint8List bytes,
  )
  onCorrected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final LiveCameraState view = ref.watch(
      liveCameraControllerProvider(camera),
    );
    final LiveCameraController controller = ref.read(
      liveCameraControllerProvider(camera).notifier,
    );
    final bool open =
        ref.watch(cameraPermissionProvider).value == CameraAccess.open;
    return AppPage(
      title: localCopy.captureCameraTitle,
      compactBar: true,
      scrollable: false,
      inset: false,
      footer: open
          ? AppPrimaryAction(
              label: localCopy.captureTakePhoto,
              busy: view.saving,
              onPressed: view.preview == CameraPreviewState.running
                  ? () => unawaited(_shoot(context, controller))
                  : null,
            )
          : null,
      body: CameraPermissionGate(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  CameraView(camera: camera),
                  _Advice(view: view, controller: controller, screen: this),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: Space.x2),
              child: CameraControls(camera: camera),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shoot(
    BuildContext context,
    LiveCameraController controller,
  ) async {
    final Result<void> shot = await controller.shoot(onCaptured);
    if (!context.mounted) {
      return;
    }
    if (shot case FailureResult<void>(:final Failure failure)) {
      showAppSnack(
        context,
        failure.message,
        tone: SnackTone.error,
        localizedMessage: failure.explanation,
      );
    }
  }
}

/// The advice on the last shot, laid over the top of the preview so the
/// shutter stays in reach: a quality finding offers keep or retake, with
/// keep the default, and document mode offers the straightened copy.
final class _Advice extends StatelessWidget {
  const _Advice({
    required this.view,
    required this.controller,
    required this.screen,
  });

  final LiveCameraState view;
  final LiveCameraController controller;
  final LiveCameraScreen screen;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final ShotQuality? quality = view.quality;
    final ShotDocument? document = view.document;
    final String? advice = quality == null
        ? null
        : ImageQuality.message(quality.finding);
    if (advice == null && document == null) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        child: ColoredBox(
          color: context.colors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (advice != null) ...<Widget>[
                AppBanner(
                  message: advice,
                  icon: AppIcons.warning,
                  tone: SnackTone.warning,
                ),
                Padding(
                  padding: const EdgeInsets.all(Space.x2),
                  child: ResponsivePair(
                    stacksOnCompact: false,
                    start: AppButton(
                      label: localCopy.captureKeepPhoto,
                      variant: AppButtonVariant.secondary,
                      expand: true,
                      onPressed: controller.keepPhoto,
                    ),
                    end: AppButton(
                      label: localCopy.captureRetakePhoto,
                      variant: AppButtonVariant.text,
                      expand: true,
                      onPressed: () => unawaited(_retake(context)),
                    ),
                  ),
                ),
              ],
              if (document != null)
                DocumentMode(
                  boundary: document.boundary,
                  onUseCorrected: () =>
                      unawaited(controller.useCorrected(screen.onCorrected)),
                  onKeepOriginal: controller.keepOriginal,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _retake(BuildContext context) async {
    final Result<void> retaken = await controller.retake(screen.onRetake);
    if (!context.mounted) {
      return;
    }
    if (retaken case FailureResult<void>(:final Failure failure)) {
      showAppSnack(
        context,
        failure.message,
        tone: SnackTone.error,
        localizedMessage: failure.explanation,
      );
    }
  }
}

import 'dart:async';
import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_photo_thumb.dart';
import 'package:tapture/core/widgets/feedback/app_panel_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';

import 'feedback_draft.dart';
import 'feedback_draft_controller.dart';
import 'feedback_providers.dart';
import 'feedback_shot.dart';
import 'feedback_window_share_controller.dart';
import 'give_feedback_controller.dart';

/// The draft's images: attach and include-UI checkboxes, a row of capture
/// controls, then the gallery. One image is a start-aligned square
/// thumbnail; several share balanced square tiles. A tap opens a larger
/// preview.
class FeedbackShots extends ConsumerWidget {
  /// Creates the section. [onAddScreen] captures the screen under the
  /// form; null hides that control.
  const FeedbackShots({super.key, this.onAddScreen});

  /// Adds a screenshot of the screen the operator is working on.
  final VoidCallback? onAddScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    // Selected, not watched whole: typing in the form must not rebuild this.
    final List<FeedbackShot> shots = ref.watch(
      feedbackDraftProvider.select(
        (FeedbackDraft? d) => d?.shots ?? const <FeedbackShot>[],
      ),
    );
    final bool attach = ref.watch(
      feedbackDraftProvider.select(
        (FeedbackDraft? d) => d?.attachShots ?? false,
      ),
    );
    final bool includeUi = ref.watch(
      feedbackDraftProvider.select((FeedbackDraft? d) => d?.includeUi ?? false),
    );
    final bool canTakePhoto = ref.watch(feedbackPhotosProvider).canTakePhoto;
    final bool canCapture = ref.watch(feedbackScreenCaptureProvider).canCapture;
    final bool sharing = ref.watch(feedbackWindowShareProvider);
    final GiveFeedbackController form = ref.read(
      giveFeedbackControllerProvider.notifier,
    );
    final VoidCallback? onAddScreen = this.onAddScreen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        shots.isEmpty
            ? Text(
                localCopy.feedbackNoScreenshot,
                style: AppText.caption.copyWith(
                  color: context.colors.onSurface,
                ),
              )
            : AppSwitchTile.checkbox(
                title: localCopy.feedbackAttachImages(shots.length),
                value: attach,
                dense: true,
                controlFirst: true,
                divided: false,
                onChanged: form.setAttachShots,
              ),
        if (onAddScreen != null)
          AppSwitchTile.checkbox(
            title: localCopy.feedbackIncludeUi,
            value: includeUi,
            dense: true,
            controlFirst: true,
            divided: false,
            onChanged: ref.read(feedbackDraftProvider.notifier).setIncludeUi,
          ),
        Row(
          children: <Widget>[
            if (onAddScreen != null)
              AppIconButton(
                icon: AppIcons.screenshot,
                semanticLabel: localCopy.feedbackAddScreen,
                tooltip: localCopy.feedbackAddScreen,
                outlined: false,
                onPressed: onAddScreen,
              ),
            if (canCapture)
              AppIconButton(
                icon: AppIcons.window,
                semanticLabel: localCopy.feedbackAddWindow,
                tooltip: localCopy.feedbackAddWindow,
                selected: sharing ? true : null,
                outlined: false,
                onPressed: () =>
                    unawaited(addFeedbackWindowStill(context, ref)),
              ),
            if (sharing)
              AppIconButton(
                icon: AppIcons.stopSharing,
                semanticLabel: localCopy.feedbackStopSharing,
                tooltip: localCopy.feedbackStopSharing,
                outlined: false,
                onPressed: () {
                  ref.read(feedbackWindowShareProvider.notifier).stop();
                },
              ),
            if (canTakePhoto)
              AppIconButton(
                icon: AppIcons.camera,
                semanticLabel: localCopy.feedbackTakePhoto,
                tooltip: localCopy.feedbackTakePhoto,
                outlined: false,
                onPressed: () => unawaited(_add(context, form, camera: true)),
              ),
            AppIconButton(
              icon: AppIcons.photoLibrary,
              semanticLabel: localCopy.feedbackChoosePhoto,
              tooltip: localCopy.feedbackChoosePhoto,
              outlined: false,
              onPressed: () => unawaited(_add(context, form, camera: false)),
            ),
          ],
        ),
        if (sharing) ...<Widget>[
          const SizedBox(height: Space.x1),
          Text(
            localCopy.feedbackSharingWindow,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(color: context.colors.onSurface),
          ),
        ],
        if (!canCapture) ...<Widget>[
          const SizedBox(height: Space.x1),
          Text(
            localCopy.feedbackShotTipScreens,
            style: AppText.caption.copyWith(color: context.colors.onSurface),
          ),
          Text(
            localCopy.feedbackShotTipApps,
            style: AppText.caption.copyWith(color: context.colors.onSurface),
          ),
        ],
        if (attach && shots.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.x1),
          _ShotGallery(
            shots: shots,
            onRemove: ref.read(feedbackDraftProvider.notifier).removeShot,
          ),
        ],
      ],
    );
  }

  Future<void> _add(
    BuildContext context,
    GiveFeedbackController form, {
    required bool camera,
  }) async {
    final LocalizedMessage? problem = await form.addPhotos(camera: camera);
    if (problem != null && context.mounted) {
      showAppSnack(
        context,
        problem.fallback,
        localizedMessage: problem,
        tone: SnackTone.warning,
      );
    }
  }
}

/// Adds one still of the shared window to the draft and says how it went.
/// The form's shot row and the folded bar both call this, so the two
/// cannot drift (FE-CONS-01).
Future<void> addFeedbackWindowStill(BuildContext context, WidgetRef ref) async {
  final int before = ref.read(feedbackDraftProvider)?.shots.length ?? 0;
  final LocalizedMessage? problem = await ref
      .read(feedbackWindowShareProvider.notifier)
      .addStill();
  if (!context.mounted) {
    return;
  }
  final LocalizedCopy localCopy = Copy.of(context);
  if (problem != null) {
    showAppSnack(
      context,
      problem.fallback,
      localizedMessage: problem,
      tone: SnackTone.warning,
    );
    return;
  }
  if ((ref.read(feedbackDraftProvider)?.shots.length ?? 0) > before) {
    showAppSnack(
      context,
      localCopy.feedbackShotAdded(localCopy.feedbackOtherWindow),
    );
  }
}

/// The attached images as [AppPhotoThumb]s: one at the gallery size, several
/// in balanced rows of equal squares. Tap previews, the corner control
/// removes (FE-CONS-06).
class _ShotGallery extends StatelessWidget {
  const _ShotGallery({required this.shots, required this.onRemove});

  final List<FeedbackShot> shots;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        if (shots.length == 1) {
          final double side = min(AppConstants.userFeedback.galleryTile, width);
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: _thumb(context, shots.single, side),
          );
        }
        // Balanced rows: five images at up to four across are 3 and 2.
        const double gap = Space.x2;
        final double tile = AppConstants.userFeedback.galleryTile;
        final int fit = ((width + gap) / (tile + gap)).floor().clamp(2, 4);
        final int rows = (shots.length / fit).ceil();
        final int columns = (shots.length / rows).ceil();
        final double cell = ((width - gap * (columns - 1)) / columns)
            .floorToDouble();
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final FeedbackShot shot in shots) _thumb(context, shot, cell),
          ],
        );
      },
    );
  }

  Widget _thumb(BuildContext context, FeedbackShot shot, double size) {
    final LocalizedCopy localCopy = Copy.of(context);

    return AppPhotoThumb(
      key: ValueKey<String>('feedback-shot-${shot.id}'),
      photo: PhotoAsset(sha256: shot.id, thumbBytes: shot.bytes),
      size: size,
      semanticLabel: localCopy.feedbackScreenshotPreview,
      onTap: () => unawaited(_preview(context, shot)),
      onRemove: () => onRemove(shot.id),
    );
  }

  Future<void> _preview(BuildContext context, FeedbackShot shot) {
    return showAppPanelDialog<void>(
      context,
      title: shot.label,
      maxWidth: AppConstants.userFeedback.previewWidth,
      builder: (BuildContext _) {
        final LocalizedCopy localCopy = Copy.of(context);

        return SingleChildScrollView(
          child: Semantics(
            label: localCopy.feedbackShotPreview,
            image: true,
            child: Image.memory(
              shot.bytes,
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
        );
      },
    );
  }
}

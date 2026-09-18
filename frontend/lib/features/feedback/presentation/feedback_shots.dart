import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
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
/// controls, then the gallery. A single image fills the width at its own
/// aspect ratio; several share balanced square tiles. A tap opens a larger
/// preview.
class FeedbackShots extends ConsumerWidget {
  /// Creates the section. [onAddScreen] captures the screen under the
  /// form; null hides that control.
  const FeedbackShots({super.key, this.onAddScreen});

  /// Adds a screenshot of the screen the operator is working on.
  final VoidCallback? onAddScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                Copy.feedbackNoScreenshot,
                style: AppText.caption.copyWith(
                  color: context.colors.onSurface,
                ),
              )
            : AppSwitchTile.checkbox(
                title: Copy.feedbackAttachImages(shots.length),
                value: attach,
                dense: true,
                controlFirst: true,
                divided: false,
                onChanged: form.setAttachShots,
              ),
        if (onAddScreen != null)
          AppSwitchTile.checkbox(
            title: Copy.feedbackIncludeUi,
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
                icon: Icons.screenshot_monitor_outlined,
                semanticLabel: Copy.feedbackAddScreen,
                tooltip: Copy.feedbackAddScreen,
                outlined: false,
                onPressed: onAddScreen,
              ),
            if (canCapture)
              AppIconButton(
                icon: Icons.desktop_windows_outlined,
                semanticLabel: Copy.feedbackAddWindow,
                tooltip: Copy.feedbackAddWindow,
                selected: sharing ? true : null,
                outlined: false,
                onPressed: () => unawaited(_addWindow(context, ref)),
              ),
            if (sharing)
              AppIconButton(
                icon: Icons.stop_screen_share_outlined,
                semanticLabel: Copy.feedbackStopSharing,
                tooltip: Copy.feedbackStopSharing,
                outlined: false,
                onPressed: () {
                  ref.read(feedbackWindowShareProvider.notifier).stop();
                },
              ),
            if (canTakePhoto)
              AppIconButton(
                icon: Icons.photo_camera_outlined,
                semanticLabel: Copy.feedbackTakePhoto,
                tooltip: Copy.feedbackTakePhoto,
                outlined: false,
                onPressed: () => unawaited(_add(context, form, camera: true)),
              ),
            AppIconButton(
              icon: Icons.add_photo_alternate_outlined,
              semanticLabel: Copy.feedbackChoosePhoto,
              tooltip: Copy.feedbackChoosePhoto,
              outlined: false,
              onPressed: () => unawaited(_add(context, form, camera: false)),
            ),
          ],
        ),
        if (sharing) ...<Widget>[
          const SizedBox(height: Space.x1),
          Text(
            Copy.feedbackSharingWindow,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    final String? problem = await form.addPhotos(camera: camera);
    if (problem != null && context.mounted) {
      showAppSnack(context, problem, tone: SnackTone.warning);
    }
  }

  Future<void> _addWindow(BuildContext context, WidgetRef ref) async {
    final int before = ref.read(feedbackDraftProvider)?.shots.length ?? 0;
    final String? problem = await ref
        .read(feedbackWindowShareProvider.notifier)
        .addStill();
    if (!context.mounted) {
      return;
    }
    if (problem != null) {
      showAppSnack(context, problem, tone: SnackTone.warning);
      return;
    }
    if ((ref.read(feedbackDraftProvider)?.shots.length ?? 0) > before) {
      showAppSnack(context, Copy.feedbackShotAdded(Copy.feedbackOtherWindow));
    }
  }
}

class _ShotGallery extends StatelessWidget {
  const _ShotGallery({required this.shots, required this.onRemove});

  final List<FeedbackShot> shots;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double ratio = MediaQuery.devicePixelRatioOf(context);
        if (shots.length == 1) {
          return _ShotTile(
            shot: shots.single,
            decodeWidth: (width * ratio).round(),
            onRemove: onRemove,
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
            for (final FeedbackShot shot in shots)
              SizedBox(
                width: cell,
                height: cell,
                child: _ShotTile(
                  shot: shot,
                  decodeWidth: (cell * ratio).round(),
                  onRemove: onRemove,
                  square: true,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ShotTile extends StatelessWidget {
  const _ShotTile({
    required this.shot,
    required this.decodeWidth,
    required this.onRemove,
    this.square = false,
  });

  final FeedbackShot shot;
  final int decodeWidth;
  final ValueChanged<String> onRemove;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final BorderSide side = BorderSide(
      color: colors.outline,
      width: Theme.of(context).dividerTheme.thickness ?? Space.x0 / 2,
    );
    const BorderRadius radius = BorderRadius.all(Radius.circular(Radii.sm));
    final String remove = Copy.feedbackRemoveShot(shot.label);
    return Stack(
      fit: square ? StackFit.expand : StackFit.loose,
      children: <Widget>[
        Material(
          color: colors.surfaceVariant,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: radius, side: side),
          child: InkWell(
            onTap: () => unawaited(_preview(context)),
            child: Semantics(
              label: Copy.feedbackScreenshotPreview,
              image: true,
              button: true,
              child: Image.memory(
                shot.bytes,
                width: double.infinity,
                fit: square ? BoxFit.cover : BoxFit.fitWidth,
                // Decoded at the size it is drawn, not the capture's edge.
                cacheWidth: decodeWidth,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
        PositionedDirectional(
          top: Space.x1,
          end: Space.x1,
          // A solid backing keeps the control legible over any image.
          child: Material(
            color: colors.surface,
            shape: const RoundedRectangleBorder(borderRadius: radius),
            child: AppIconButton(
              icon: Icons.close,
              semanticLabel: remove,
              tooltip: remove,
              onPressed: () => onRemove(shot.id),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _preview(BuildContext context) {
    return showAppPanelDialog<void>(
      context,
      title: shot.label,
      maxWidth: AppConstants.userFeedback.previewWidth,
      builder: (BuildContext _) {
        return SingleChildScrollView(
          child: Semantics(
            label: Copy.feedbackShotPreview,
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

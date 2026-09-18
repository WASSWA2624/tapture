import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';

import '../domain/feedback_category.dart';
import '../domain/feedback_entry.dart';
import 'feedback_draft.dart';
import 'feedback_draft_controller.dart';
import 'feedback_labels.dart';
import 'feedback_photo_source.dart';
import 'feedback_providers.dart';
import 'feedback_shot.dart';
import 'feedback_shot_fit.dart';
import 'give_feedback_controller.dart';
import 'give_feedback_view.dart';

/// Writes a feedback entry as a compact form with Save pinned below it.
class GiveFeedbackScreen extends ConsumerStatefulWidget {
  /// Creates the form. [embedded] is the overlay workspace: back keeps the
  /// draft and returns to the app rather than popping a route.
  const GiveFeedbackScreen({super.key, this.embedded = false});

  /// When true, back collapses the overlay instead of popping a route.
  final bool embedded;

  @override
  ConsumerState<GiveFeedbackScreen> createState() => _GiveFeedbackState();
}

class _GiveFeedbackState extends ConsumerState<GiveFeedbackScreen> {
  late final TextEditingController _message;
  late final TextEditingController _other;

  @override
  void initState() {
    super.initState();
    final FeedbackDraft? draft = ref.read(feedbackDraftProvider);
    _message = TextEditingController(text: draft?.message ?? '');
    _other = TextEditingController(text: draft?.other ?? '');
    _message.addListener(_persistText);
    _other.addListener(_persistText);
  }

  @override
  void dispose() {
    _message.removeListener(_persistText);
    _other.removeListener(_persistText);
    _message.dispose();
    _other.dispose();
    super.dispose();
  }

  void _persistText() {
    ref
        .read(feedbackDraftProvider.notifier)
        .setText(message: _message.text, other: _other.text);
  }

  @override
  Widget build(BuildContext context) {
    final GiveFeedbackView view = ref.watch(giveFeedbackControllerProvider);
    final GiveFeedbackController controller = ref.read(
      giveFeedbackControllerProvider.notifier,
    );
    final FeedbackDraft? draft = ref.watch(feedbackDraftProvider);
    final List<FeedbackShot> shots = draft?.shots ?? const <FeedbackShot>[];
    return PopScope<Object?>(
      canPop: !widget.embedded,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop && widget.embedded) {
          ref.read(feedbackDraftProvider.notifier).collapse();
        }
      },
      child: AppPage(
        title: Copy.feedbackGive,
        compactBar: true,
        scrollable: false,
        leading: widget.embedded
            ? AppIconButton(
                icon: Icons.arrow_back,
                semanticLabel: Copy.feedbackContinueLater,
                tooltip: Copy.feedbackContinueLater,
                outlined: false,
                onPressed: () => unawaited(_leave()),
              )
            : null,
        overflow: <AppOverflowAction>[
          AppOverflowAction(
            key: const ValueKey<String>('feedback-discard-draft'),
            icon: Icons.delete_outline,
            label: Copy.feedbackDiscardDraft,
            onTap: () => unawaited(_discard()),
          ),
        ],
        body: AppForm(
          compact: true,
          fields: <Widget>[
            AppRadioGroup<FeedbackCategory>(
              label: Copy.feedbackType,
              showLabel: false,
              direction: Axis.horizontal,
              value: view.category,
              options: <Choice<FeedbackCategory>>[
                for (final FeedbackCategory category
                    in FeedbackCategory.offered)
                  Choice<FeedbackCategory>(
                    category,
                    FeedbackLabels.category(category),
                  ),
              ],
              onChanged: controller.chooseCategory,
            ),
            if (view.category == FeedbackCategory.other)
              AppTextField(
                label: Copy.feedbackOtherType,
                controller: _other,
                maxLength: AppConstants.userFeedback.maxOtherLength,
                errorText: view.otherError,
                textInputAction: TextInputAction.next,
              ),
            AppTextField(
              label: Copy.feedbackMessage,
              controller: _message,
              hint: Copy.feedbackMessageHint,
              minLines: 3,
              maxLines: 8,
              maxLength: AppConstants.userFeedback.maxMessageLength,
              errorText: view.messageError,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
            _ShotAttach(
              shots: shots,
              attach: view.attachScreenshot,
              onChanged: controller.setAttachScreenshot,
              onRemove: (String id) {
                ref.read(feedbackDraftProvider.notifier).removeShot(id);
              },
              onTakePhoto: () => unawaited(_addPhotos(camera: true)),
              onChoosePhoto: () => unawaited(_addPhotos(camera: false)),
            ),
          ],
          errors: <String>[?view.saveError],
          submitLabel: Copy.feedbackSave,
          onSubmit: () async {
            final NavigatorState root = Navigator.of(
              context,
              rootNavigator: true,
            );
            final Result<FeedbackEntry> result = await controller.save(
              message: _message.text,
              other: _other.text,
            );
            if (!mounted) {
              return;
            }
            if (result is Success<FeedbackEntry>) {
              if (widget.embedded) {
                showAppSnack(
                  root.context,
                  Copy.feedbackSaved,
                  tone: SnackTone.success,
                );
              }
              ref.read(feedbackDraftProvider.notifier).clear();
              await _closeSaved();
            }
          },
        ),
      ),
    );
  }

  Future<void> _leave() async {
    _persistText();
    if (widget.embedded) {
      ref.read(feedbackDraftProvider.notifier).collapse();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _closeSaved() async {
    if (widget.embedded) {
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _discard() async {
    final bool confirmed = await showAppConfirm(
      context,
      title: Copy.feedbackDiscardDraft,
      message: Copy.feedbackDiscardDraftMessage,
      confirmLabel: Copy.discard,
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    ref.read(feedbackDraftProvider.notifier).clear();
    if (widget.embedded) {
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _addPhotos({required bool camera}) async {
    final FeedbackPhotoSource source = ref.read(feedbackPhotoSourceProvider);
    final Result<List<Uint8List>> picked = await source.pick(camera: camera);
    if (!mounted) {
      return;
    }
    switch (picked) {
      case FailureResult<List<Uint8List>>(:final failure):
        showAppSnack(context, failure.message, tone: SnackTone.warning);
      case Success<List<Uint8List>>(:final List<Uint8List> value):
        if (value.isEmpty) {
          showAppSnack(context, Copy.feedbackNoPhoto, tone: SnackTone.warning);
          return;
        }
        final FeedbackDraftController draft = ref.read(
          feedbackDraftProvider.notifier,
        );
        for (final Uint8List raw in value) {
          final Uint8List bytes = await FeedbackShotFit.cap(raw);
          if (!mounted) {
            return;
          }
          final String? blocked = draft.addShot(
            FeedbackShot(
              id: draft.nextShotId(),
              bytes: bytes,
              label: camera ? Copy.feedbackTakePhoto : Copy.feedbackChoosePhoto,
            ),
          );
          if (blocked != null) {
            showAppSnack(context, blocked, tone: SnackTone.warning);
            return;
          }
        }
        ref
            .read(giveFeedbackControllerProvider.notifier)
            .setAttachScreenshot(true);
    }
  }
}

/// The attach checkbox, gallery, and photo actions.
class _ShotAttach extends StatelessWidget {
  const _ShotAttach({
    required this.shots,
    required this.attach,
    required this.onChanged,
    required this.onRemove,
    required this.onTakePhoto,
    required this.onChoosePhoto,
  });

  final List<FeedbackShot> shots;
  final bool attach;
  final ValueChanged<bool> onChanged;
  final ValueChanged<String> onRemove;
  final VoidCallback onTakePhoto;
  final VoidCallback onChoosePhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSwitchTile.checkbox(
          title: Copy.feedbackAttachScreenshot,
          value: attach,
          dense: true,
          controlFirst: true,
          divided: false,
          onChanged: onChanged,
        ),
        const SizedBox(height: Space.x1),
        Wrap(
          spacing: Space.x2,
          runSpacing: Space.x1,
          children: <Widget>[
            AppButton(
              label: Copy.feedbackTakePhoto,
              icon: Icons.photo_camera_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: onTakePhoto,
            ),
            AppButton(
              label: Copy.feedbackChoosePhoto,
              icon: Icons.photo_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: onChoosePhoto,
            ),
          ],
        ),
        if (attach && shots.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.x2),
          _ShotGallery(shots: shots, onRemove: onRemove),
        ],
        if (shots.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Space.x1),
            child: Text(
              Copy.feedbackNoScreenshot,
              style: AppText.caption.copyWith(color: context.colors.onSurface),
            ),
          ),
      ],
    );
  }
}

class _ShotGallery extends StatelessWidget {
  const _ShotGallery({required this.shots, required this.onRemove});

  final List<FeedbackShot> shots;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (shots.length == 1) {
      return _ShotTile(
        shot: shots.first,
        expanded: true,
        onRemove: () => onRemove(shots.first.id),
      );
    }
    final int columns = context.responsive(compact: 2, medium: 3, expanded: 4);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = Space.x2;
        final double width =
            ((constraints.maxWidth - gap * (columns - 1)) / columns)
                .clamp(Sizes.minTapTarget, double.infinity)
                .toDouble();
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final FeedbackShot shot in shots)
              SizedBox(
                width: width,
                child: _ShotTile(
                  shot: shot,
                  expanded: false,
                  onRemove: () => onRemove(shot.id),
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
    required this.expanded,
    required this.onRemove,
  });

  final FeedbackShot shot;
  final bool expanded;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    const BorderRadius radius = BorderRadius.all(Radius.circular(Radii.sm));
    final Widget image = Semantics(
      label: Copy.feedbackScreenshotPreview,
      image: true,
      button: true,
      child: Material(
        color: colors.surfaceVariant,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: colors.outline,
            width: Theme.of(context).dividerTheme.thickness ?? Space.x0 / 2,
          ),
        ),
        child: InkWell(
          onTap: () => unawaited(_preview(context)),
          child: expanded
              ? Image.memory(
                  shot.bytes,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  gaplessPlayback: true,
                )
              : AspectRatio(
                  aspectRatio: 1,
                  child: Image.memory(
                    shot.bytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
        ),
      ),
    );
    return Stack(
      children: <Widget>[
        image,
        Align(
          alignment: AlignmentDirectional.topEnd,
          child: AppIconButton(
            icon: Icons.close,
            semanticLabel: Copy.feedbackRemoveShot(
              shot.label.isEmpty ? Copy.feedbackScreenshotPreview : shot.label,
            ),
            tooltip: Copy.feedbackRemoveShot(
              shot.label.isEmpty ? Copy.feedbackScreenshotPreview : shot.label,
            ),
            outlined: false,
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }

  Future<void> _preview(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(Space.x4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AppIconButton(
                  icon: Icons.close,
                  semanticLabel: Copy.close,
                  tooltip: Copy.close,
                  outlined: false,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.7,
                  maxWidth: MediaQuery.sizeOf(dialogContext).width,
                ),
                child: InteractiveViewer(
                  child: Semantics(
                    label: Copy.feedbackShotPreview,
                    image: true,
                    child: Image.memory(shot.bytes, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: Space.x2),
            ],
          ),
        );
      },
    );
  }
}

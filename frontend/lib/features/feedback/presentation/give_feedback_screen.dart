import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';

import '../domain/feedback_category.dart';
import '../domain/feedback_entry.dart';
import 'feedback_draft.dart';
import 'feedback_draft_controller.dart';
import 'feedback_labels.dart';
import 'give_feedback_controller.dart';
import 'give_feedback_view.dart';

/// Writes a feedback entry as a full-screen form with Save pinned below it.
class GiveFeedbackScreen extends ConsumerStatefulWidget {
  /// Creates the form.
  const GiveFeedbackScreen({super.key});

  @override
  ConsumerState<GiveFeedbackScreen> createState() => _GiveFeedbackState();
}

class _GiveFeedbackState extends ConsumerState<GiveFeedbackScreen> {
  // The screen owns its text, so closing it releases the text with it and
  // reopening starts from nothing (FE-STATE-09).
  final TextEditingController _message = TextEditingController();
  final TextEditingController _other = TextEditingController();

  /// Read once: the shot does not change while the form is open, and
  /// holding it keeps the preview steady while the screen animates away.
  late final FeedbackDraft? _draft = ref.read(feedbackDraftProvider);

  @override
  void dispose() {
    _message.dispose();
    _other.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GiveFeedbackView view = ref.watch(giveFeedbackControllerProvider);
    final GiveFeedbackController controller = ref.read(
      giveFeedbackControllerProvider.notifier,
    );
    final Uint8List? screenshot = _draft?.screenshot;
    final String screen = _draft?.context.screen ?? '';
    return AppPage(
      title: Copy.feedbackGive,
      scrollable: false,
      body: AppForm(
        fields: <Widget>[
          AppRadioGroup<FeedbackCategory>(
            label: Copy.feedbackType,
            showLabel: false,
            direction: Axis.horizontal,
            value: view.category,
            options: <Choice<FeedbackCategory>>[
              for (final FeedbackCategory category in FeedbackCategory.offered)
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
            minLines: 4,
            maxLines: 8,
            maxLength: AppConstants.userFeedback.maxMessageLength,
            errorText: view.messageError,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
          ),
          _ScreenshotAttach(
            bytes: screenshot,
            screen: screen,
            attach: view.attachScreenshot,
            onChanged: controller.setAttachScreenshot,
          ),
        ],
        errors: <String>[?view.saveError],
        submitLabel: Copy.feedbackSave,
        guardUnsaved: true,
        onSubmit: () async {
          final Result<FeedbackEntry> result = await controller.save(
            message: _message.text,
            other: _other.text,
          );
          if (result is Success<FeedbackEntry> && context.mounted) {
            // pop, not maybePop: a saved form has nothing left to guard.
            Navigator.of(context).pop(true);
          }
        },
      ),
    );
  }
}

/// The attach switch, then the shot it attaches.
class _ScreenshotAttach extends StatelessWidget {
  const _ScreenshotAttach({
    required this.bytes,
    required this.screen,
    required this.attach,
    required this.onChanged,
  });

  final Uint8List? bytes;
  final String screen;
  final bool attach;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = this.bytes;
    final AppColors colors = context.colors;
    if (bytes == null) {
      return Text(
        Copy.feedbackNoScreenshot,
        style: AppText.caption.copyWith(color: colors.onSurface),
      );
    }
    final double edge = AppConstants.images.previewEdge.toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSwitchTile(
          title: Copy.feedbackAttachScreenshot,
          description: Copy.feedbackScreenshotOf(screen),
          value: attach,
          dense: true,
          onChanged: onChanged,
        ),
        if (attach) ...<Widget>[
          const SizedBox(height: Space.x1),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: edge),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(Radii.sm),
                  ),
                  border: Border.all(
                    color: colors.outline,
                    width:
                        Theme.of(context).dividerTheme.thickness ??
                        Space.x0 / 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(Radii.sm),
                  ),
                  child: Semantics(
                    label: Copy.feedbackScreenshotPreview,
                    image: true,
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      // Decoded at preview size, not the capture's full edge.
                      cacheHeight:
                          (edge * MediaQuery.devicePixelRatioOf(context))
                              .round(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

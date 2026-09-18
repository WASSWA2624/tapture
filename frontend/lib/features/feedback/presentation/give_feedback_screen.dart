import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';

import '../domain/feedback_category.dart';
import '../domain/feedback_entry.dart';
import 'feedback_draft_controller.dart';
import 'feedback_labels.dart';
import 'give_feedback_controller.dart';
import 'give_feedback_view.dart';

/// Writes a feedback entry. A desktop hosts this in a panel; a phone opens
/// it as a screen.
class GiveFeedbackScreen extends ConsumerWidget {
  /// Creates the full-screen form.
  const GiveFeedbackScreen({super.key, this.showAppBar = true});

  /// Creates the form for a panel, without a second title.
  const GiveFeedbackScreen.embedded({super.key}) : showAppBar = false;

  /// When false, the panel already shows the title.
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GiveFeedbackView view = ref.watch(giveFeedbackControllerProvider);
    final GiveFeedbackController controller = ref.read(
      giveFeedbackControllerProvider.notifier,
    );
    final Uint8List? screenshot = ref.watch(feedbackDraftProvider)?.screenshot;
    final String screen =
        ref.watch(feedbackDraftProvider)?.context.screen ?? '';
    final Widget form = AppForm(
      fields: <Widget>[
        Text(
          Copy.feedbackStaysOnDevice,
          style: AppText.body.copyWith(color: context.colors.onSurface),
        ),
        AppChoiceField<FeedbackCategory>(
          label: Copy.feedbackType,
          value: view.category,
          options: <Choice<FeedbackCategory>>[
            for (final FeedbackCategory category in FeedbackCategory.values)
              Choice<FeedbackCategory>(
                category,
                FeedbackLabels.category(category),
              ),
          ],
          onChanged: (FeedbackCategory? value) {
            if (value != null) {
              controller.chooseCategory(value);
            }
          },
        ),
        if (view.category == FeedbackCategory.other)
          AppTextField(
            label: Copy.feedbackOtherType,
            controller: controller.other,
            maxLength: AppConstants.userFeedback.maxOtherLength,
            errorText: view.otherError,
          ),
        AppTextField(
          label: Copy.feedbackMessage,
          controller: controller.message,
          hint: Copy.feedbackMessageHint,
          maxLines: 6,
          maxLength: AppConstants.userFeedback.maxMessageLength,
          errorText: view.messageError,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
        ),
        if (screenshot != null) ...<Widget>[
          AppSwitchTile(
            title: Copy.feedbackAttachScreenshot,
            description: Copy.feedbackScreenshotOf(screen),
            value: view.attachScreenshot,
            onChanged: controller.setAttachScreenshot,
          ),
          if (view.attachScreenshot)
            Semantics(
              label: Copy.feedbackScreenshotPreview,
              image: true,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: AppConstants.images.previewEdge.toDouble(),
                ),
                child: Image.memory(screenshot, fit: BoxFit.contain),
              ),
            ),
        ] else
          Text(
            Copy.feedbackNoScreenshot,
            style: AppText.body.copyWith(color: context.colors.onSurface),
          ),
      ],
      errors: <String>[if (view.saveError != null) view.saveError!],
      submitLabel: Copy.feedbackSave,
      guardUnsaved: true,
      onSubmit: () async {
        final Result<FeedbackEntry> result = await controller.save();
        if (result is Success<FeedbackEntry> && context.mounted) {
          Navigator.of(context).pop(true);
        }
      },
    );
    if (!showAppBar) {
      return form;
    }
    return AppPage(title: Copy.feedbackGive, body: form);
  }
}

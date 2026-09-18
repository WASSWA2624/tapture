import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_card.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
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

/// Writes a feedback entry as a full-screen form.
class GiveFeedbackScreen extends ConsumerWidget {
  /// Creates the form.
  const GiveFeedbackScreen({super.key});

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
        AppRadioGroup<FeedbackCategory>(
          label: Copy.feedbackType,
          value: view.category,
          options: <Choice<FeedbackCategory>>[
            for (final FeedbackCategory category in FeedbackCategory.values)
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
            controller: controller.other,
            maxLength: AppConstants.userFeedback.maxOtherLength,
            errorText: view.otherError,
          ),
        AppTextField(
          label: Copy.feedbackMessage,
          controller: controller.message,
          helper: Copy.feedbackMessageHint,
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
    return AppPage(title: Copy.feedbackGive, body: form);
  }
}

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
    if (bytes == null) {
      return Text(
        Copy.feedbackNoScreenshot,
        style: AppText.caption.copyWith(color: context.colors.onSurface),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (attach)
            ColoredBox(
              color: context.colors.surfaceVariant,
              child: Semantics(
                label: Copy.feedbackScreenshotPreview,
                image: true,
                child: Image.memory(
                  bytes,
                  width: double.infinity,
                  height: AppConstants.images.previewEdge.toDouble(),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          AppSwitchTile(
            title: Copy.feedbackAttachScreenshot,
            description: Copy.feedbackScreenshotOf(screen),
            value: attach,
            divided: false,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

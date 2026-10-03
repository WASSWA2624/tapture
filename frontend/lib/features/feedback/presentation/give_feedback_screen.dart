import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';

import '../domain/feedback_category.dart';
import '../domain/feedback_entry.dart';
import 'feedback_confirmations.dart';
import 'feedback_draft.dart';
import 'feedback_draft_controller.dart';
import 'feedback_labels.dart';
import 'feedback_shots.dart';
import 'give_feedback_controller.dart';
import 'give_feedback_view.dart';

/// Writes the feedback draft as a compact form with Save pinned below it.
///
/// It is the overlay's workspace, not a route: Close folds it into the
/// compact bar with everything kept, so the operator can move through the
/// app and come back.
class GiveFeedbackScreen extends ConsumerStatefulWidget {
  /// Creates the form. [onAddScreen] adds a screenshot of the screen under
  /// the form; null hides that control.
  const GiveFeedbackScreen({super.key, this.onAddScreen});

  /// Captures the screen the operator is working on into the draft.
  final VoidCallback? onAddScreen;

  @override
  ConsumerState<GiveFeedbackScreen> createState() => _GiveFeedbackState();
}

class _GiveFeedbackState extends ConsumerState<GiveFeedbackScreen> {
  late final FeedbackDraftController _draft = ref.read(
    feedbackDraftProvider.notifier,
  );
  late final TextEditingController _message;
  late final TextEditingController _other;

  @override
  void initState() {
    super.initState();
    final FeedbackDraft? draft = ref.read(feedbackDraftProvider);
    _message = TextEditingController(text: draft?.message ?? '')
      ..addListener(_keepText);
    _other = TextEditingController(text: draft?.other ?? '')
      ..addListener(_keepText);
  }

  @override
  void dispose() {
    _message.dispose();
    _other.dispose();
    super.dispose();
  }

  /// Writes the text to the draft as it changes, so the bar, a save and a
  /// later reopening all see it. Caret moves alone write nothing.
  void _keepText() {
    final FeedbackDraft? draft = ref.read(feedbackDraftProvider);
    if (draft != null &&
        (draft.message != _message.text || draft.other != _other.text)) {
      _draft.setText(message: _message.text, other: _other.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final GiveFeedbackView view = ref.watch(giveFeedbackControllerProvider);
    final GiveFeedbackController form = ref.read(
      giveFeedbackControllerProvider.notifier,
    );
    final FeedbackCategory category = ref.watch(
      feedbackDraftProvider.select(
        (FeedbackDraft? d) => d?.category ?? FeedbackCategory.general,
      ),
    );
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) {
          _draft.collapse();
        }
      },
      child: AppPage(
        title: localCopy.feedbackGive,
        compactBar: true,
        scrollable: false,
        leading: AppIconButton(
          icon: AppIcons.collapsePanel,
          semanticLabel: localCopy.feedbackContinueLater,
          tooltip: localCopy.feedbackContinueLater,
          outlined: false,
          onPressed: _draft.collapse,
        ),
        overflow: <AppOverflowAction>[
          AppOverflowAction(
            key: const ValueKey<String>('feedback-discard-draft'),
            icon: AppIcons.delete,
            label: localCopy.feedbackDiscardDraft,
            onTap: () => unawaited(_discard()),
          ),
        ],
        body: AppForm(
          compact: true,
          fields: <Widget>[
            AppRadioGroup<FeedbackCategory>(
              label: localCopy.feedbackType,
              showLabel: false,
              direction: Axis.horizontal,
              value: category,
              options: <Choice<FeedbackCategory>>[
                for (final FeedbackCategory option in FeedbackCategory.offered)
                  Choice<FeedbackCategory>(
                    option,
                    FeedbackLabels.category(
                      option,
                      localizedCopy: Copy.of(context),
                    ),
                  ),
              ],
              onChanged: form.chooseCategory,
            ),
            if (category == FeedbackCategory.other)
              AppTextField(
                label: localCopy.feedbackOtherType,
                controller: _other,
                maxLength: AppConstants.userFeedback.maxOtherLength,
                errorText: Copy.of(
                  context,
                ).stateText(view.localizedOtherError, view.otherError),
                textInputAction: TextInputAction.next,
              ),
            AppTextField(
              label: localCopy.feedbackMessage,
              controller: _message,
              hint: localCopy.feedbackMessageHint,
              minLines: 3,
              maxLines: 8,
              maxLength: AppConstants.userFeedback.maxMessageLength,
              errorText: Copy.of(
                context,
              ).stateText(view.localizedMessageError, view.messageError),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
            FeedbackShots(onAddScreen: widget.onAddScreen),
          ],
          errors: <String>[
            ?Copy.of(
              context,
            ).stateText(view.localizedSaveError, view.saveError),
          ],
          submitLabel: localCopy.feedbackSave,
          onSubmit: _save,
        ),
      ),
    );
  }

  Future<bool> _save() async {
    final LocalizedCopy localCopy = Copy.of(context);

    // The form leaves the tree once the draft clears; the Feedback
    // navigator's context outlives it for the confirmation.
    final BuildContext root = Navigator.of(context).context;
    final Result<FeedbackEntry> result = await ref
        .read(giveFeedbackControllerProvider.notifier)
        .save();
    final bool saved = result is Success<FeedbackEntry>;
    if (saved && root.mounted) {
      showAppSnack(root, localCopy.feedbackSaved, tone: SnackTone.success);
    }
    return saved;
  }

  Future<void> _discard() async {
    final bool confirmed = await confirmDiscardFeedbackDraft(
      context,
      images: ref.read(feedbackDraftProvider)?.shots.length ?? 0,
    );
    if (confirmed) {
      _draft.clear();
    }
  }
}

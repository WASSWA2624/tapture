import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/feedback_category.dart';
import '../domain/feedback_entry.dart';
import 'feedback_draft.dart';
import 'feedback_draft_controller.dart';
import 'feedback_providers.dart';
import 'give_feedback_view.dart';

/// Saves a new feedback entry from the form.
final class GiveFeedbackController extends Notifier<GiveFeedbackView> {
  /// Creates the controller.
  GiveFeedbackController();

  /// The feedback text.
  late final TextEditingController message;

  /// The operator's name for an "other" type.
  late final TextEditingController other;

  @override
  GiveFeedbackView build() {
    message = TextEditingController();
    other = TextEditingController();
    ref.onDispose(() {
      message.dispose();
      other.dispose();
    });
    final bool hasShot = ref.read(feedbackDraftProvider)?.screenshot != null;
    return (
      category: FeedbackCategory.general,
      attachScreenshot: hasShot,
      messageError: null,
      otherError: null,
      saveError: null,
    );
  }

  /// Picks the kind of feedback.
  void chooseCategory(FeedbackCategory category) {
    state = (
      category: category,
      attachScreenshot: state.attachScreenshot,
      messageError: state.messageError,
      otherError: null,
      saveError: null,
    );
  }

  /// Whether the captured screenshot is stored with the entry.
  void setAttachScreenshot(bool attach) {
    state = (
      category: state.category,
      attachScreenshot: attach,
      messageError: state.messageError,
      otherError: state.otherError,
      saveError: null,
    );
  }

  /// Persists the entry. Completes after the write is durable.
  Future<Result<FeedbackEntry>> save() async {
    final String text = message.text.trim();
    final String named = other.text.trim();
    String? messageError;
    String? otherError;
    if (text.isEmpty) {
      messageError = Copy.feedbackMessageRequired;
    }
    if (state.category == FeedbackCategory.other && named.isEmpty) {
      otherError = Copy.feedbackOtherRequired;
    }
    if (messageError != null || otherError != null) {
      state = (
        category: state.category,
        attachScreenshot: state.attachScreenshot,
        messageError: messageError,
        otherError: otherError,
        saveError: null,
      );
      return FailureResult<FeedbackEntry>(
        ValidationFailure(
          message: messageError ?? otherError ?? Copy.feedbackMessageRequired,
          recoveryAction: 'Correct the highlighted field and save again.',
        ),
      );
    }
    final FeedbackDraft? draft = ref.read(feedbackDraftProvider);
    if (draft == null) {
      return const FailureResult<FeedbackEntry>(
        ValidationFailure(
          message: Copy.somethingWentWrong,
          recoveryAction: 'Close this, tap Feedback, then try again.',
        ),
      );
    }
    final Result<FeedbackEntry> result = await ref
        .read(feedbackRepositoryProvider)
        .add(
          category: state.category,
          message: text,
          context: draft.context,
          otherCategory: state.category == FeedbackCategory.other
              ? named
              : null,
          screenshot: state.attachScreenshot ? draft.screenshot : null,
        );
    switch (result) {
      case Success<FeedbackEntry>():
        ref.read(feedbackDraftProvider.notifier).clear();
        return result;
      case FailureResult<FeedbackEntry>(:final Failure failure):
        state = (
          category: state.category,
          attachScreenshot: state.attachScreenshot,
          messageError: state.messageError,
          otherError: state.otherError,
          saveError: failure.message,
        );
        return result;
    }
  }
}

/// Form state for [GiveFeedbackScreen].
final NotifierProvider<GiveFeedbackController, GiveFeedbackView>
giveFeedbackControllerProvider =
    NotifierProvider<GiveFeedbackController, GiveFeedbackView>(
      GiveFeedbackController.new,
    );

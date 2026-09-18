import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/feedback_category.dart';
import '../domain/feedback_entry.dart';
import 'feedback_draft.dart';
import 'feedback_draft_controller.dart';
import 'feedback_providers.dart';
import 'feedback_shot.dart';
import 'give_feedback_view.dart';

/// Saves a new feedback entry from the form.
///
/// The screen owns the text it edits; this holds only the choices and the
/// verdicts. The draft keeps those choices while the operator moves around.
final class GiveFeedbackController extends Notifier<GiveFeedbackView> {
  /// Creates the controller.
  GiveFeedbackController();

  @override
  GiveFeedbackView build() {
    final FeedbackDraft? draft = ref.read(feedbackDraftProvider);
    final bool hasShot = draft?.shots.isNotEmpty ?? false;
    return (
      category: draft?.category ?? FeedbackCategory.general,
      attachScreenshot: draft?.attachShots ?? hasShot,
      messageError: null,
      otherError: null,
      saveError: null,
    );
  }

  /// Picks the kind of feedback.
  void chooseCategory(FeedbackCategory category) {
    ref.read(feedbackDraftProvider.notifier).setCategory(category);
    state = (
      category: category,
      attachScreenshot: state.attachScreenshot,
      messageError: state.messageError,
      otherError: null,
      saveError: null,
    );
  }

  /// Whether the attached images are stored with the entry.
  void setAttachScreenshot(bool attach) {
    ref.read(feedbackDraftProvider.notifier).setAttachShots(attach);
    state = (
      category: state.category,
      attachScreenshot: attach,
      messageError: state.messageError,
      otherError: state.otherError,
      saveError: null,
    );
  }

  /// Persists [message], and [other] as the type's name when the type is
  /// Other. Completes after the write is durable.
  Future<Result<FeedbackEntry>> save({
    required String message,
    String other = '',
  }) async {
    final String text = message.trim();
    final String named = other.trim();
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
      const ValidationFailure missing = ValidationFailure(
        message: Copy.somethingWentWrong,
        recoveryAction: 'Close this, tap Feedback, then try again.',
      );
      _failed(missing);
      return const FailureResult<FeedbackEntry>(missing);
    }
    final FeedbackCategory category = state.category;
    final List<Uint8List> shots = <Uint8List>[
      if (state.attachScreenshot)
        for (final FeedbackShot shot in draft.shots) shot.bytes,
    ];
    final Result<FeedbackEntry> result = await ref
        .read(feedbackRepositoryProvider)
        .add(
          category: category,
          message: text,
          context: draft.context,
          otherCategory: category == FeedbackCategory.other ? named : null,
          screenshot: shots.isEmpty ? null : shots.first,
          screenshots: shots.length > 1
              ? shots.sublist(1)
              : const <Uint8List>[],
        );
    if (ref.mounted && result is FailureResult<FeedbackEntry>) {
      _failed(result.failure);
    }
    return result;
  }

  void _failed(Failure failure) {
    state = (
      category: state.category,
      attachScreenshot: state.attachScreenshot,
      messageError: state.messageError,
      otherError: state.otherError,
      saveError: failure.message,
    );
  }
}

/// Form state for [GiveFeedbackScreen]. Disposed with the screen, so every
/// opening starts clean (FE-STATE-09).
final NotifierProvider<GiveFeedbackController, GiveFeedbackView>
giveFeedbackControllerProvider =
    NotifierProvider.autoDispose<GiveFeedbackController, GiveFeedbackView>(
      GiveFeedbackController.new,
    );

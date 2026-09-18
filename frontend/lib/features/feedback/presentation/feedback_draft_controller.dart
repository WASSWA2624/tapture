import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'feedback_draft.dart';

/// Holds [FeedbackDraft] until the form saves or the operator cancels.
final class FeedbackDraftController extends Notifier<FeedbackDraft?> {
  /// Creates the holder.
  FeedbackDraftController();

  @override
  FeedbackDraft? build() => null;

  /// Replaces the draft with a new capture.
  void capture(FeedbackDraft draft) => state = draft;

  /// Drops the draft.
  void clear() => state = null;
}

/// The screenshot and context from the last Feedback tap.
final NotifierProvider<FeedbackDraftController, FeedbackDraft?>
feedbackDraftProvider =
    NotifierProvider<FeedbackDraftController, FeedbackDraft?>(
      FeedbackDraftController.new,
    );

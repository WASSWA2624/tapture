import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_picker.dart';

import '../domain/feedback_category.dart';
import '../domain/feedback_entry.dart';
import 'feedback_draft.dart';
import 'feedback_draft_controller.dart';
import 'feedback_providers.dart';
import 'feedback_shot.dart';
import 'feedback_shot_fit.dart';
import 'give_feedback_view.dart';

/// Checks and saves the draft as a feedback entry. The draft holds what was
/// written and chosen; this holds only the verdicts.
final class GiveFeedbackController extends Notifier<GiveFeedbackView> {
  /// Creates the controller.
  GiveFeedbackController();

  static const GiveFeedbackView _clean = (
    messageError: null,
    localizedMessageError: null,
    otherError: null,
    localizedOtherError: null,
    saveError: null,
    localizedSaveError: null,
  );

  @override
  GiveFeedbackView build() => _clean;

  /// Picks the kind of feedback.
  void chooseCategory(FeedbackCategory category) {
    ref.read(feedbackDraftProvider.notifier).setCategory(category);
    state = (
      messageError: state.messageError,
      localizedMessageError: state.localizedMessageError,
      otherError: null,
      localizedOtherError: null,
      saveError: null,
      localizedSaveError: null,
    );
  }

  /// Whether the attached images are stored with the entry.
  void setAttachShots(bool attach) {
    ref.read(feedbackDraftProvider.notifier).setAttachShots(attach);
  }

  /// Adds photos from the camera, or up to the room left from the library,
  /// each capped to the feedback long edge. Returns why none were added, or
  /// null; a cancelled picker is not a failure.
  Future<LocalizedMessage?> addPhotos({required bool camera}) async {
    final FeedbackDraftController draft = ref.read(
      feedbackDraftProvider.notifier,
    );
    final int room =
        AppConstants.userFeedback.maxShots -
        (ref.read(feedbackDraftProvider)?.shots.length ?? 0);
    if (room <= 0) {
      return Copy.messages.feedbackShotsFull;
    }
    final PhotoPicker picker = ref.read(feedbackPhotosProvider);
    final int edge = AppConstants.userFeedback.screenshotLongEdge;
    final Result<List<Uint8List>> picked = camera
        ? await picker.take(longEdge: edge)
        : await picker.choose(limit: room, longEdge: edge);
    switch (picked) {
      case FailureResult<List<Uint8List>>(:final Failure failure):
        return failure.explanation;
      case Success<List<Uint8List>>(:final List<Uint8List> value):
        for (final Uint8List photo in value) {
          final LocalizedMessage? full = draft.addShot(
            await FeedbackShotFit.cap(photo),
            label: Copy.photo,
          );
          if (full != null) {
            return full;
          }
        }
        return null;
    }
  }

  /// Saves the draft, and clears it once the entry is durable.
  Future<Result<FeedbackEntry>> save() async {
    final FeedbackDraftController drafts = ref.read(
      feedbackDraftProvider.notifier,
    );
    final FeedbackDraft? draft = ref.read(feedbackDraftProvider);
    if (draft == null) {
      final ValidationFailure missing = ValidationFailure(
        localizedMessage: Copy.messages.somethingWentWrong,
        localizedRecovery:
            Copy.messages.failureCloseThisTapFeedbackThenTryAgain,
      );
      state = (
        messageError: null,
        localizedMessageError: null,
        otherError: null,
        localizedOtherError: null,
        saveError: missing.message,
        localizedSaveError: missing.explanation,
      );
      return FailureResult<FeedbackEntry>(missing);
    }
    final String text = draft.message.trim();
    final bool isOther = draft.category == FeedbackCategory.other;
    final String named = draft.other.trim();
    final String? messageError = text.isEmpty
        ? Copy.feedbackMessageRequired
        : null;
    final LocalizedMessage? localizedMessageError = text.isEmpty
        ? Copy.messages.feedbackMessageRequired
        : null;
    final String? otherError = isOther && named.isEmpty
        ? Copy.feedbackOtherRequired
        : null;
    final LocalizedMessage? localizedOtherError = isOther && named.isEmpty
        ? Copy.messages.feedbackOtherRequired
        : null;
    if (messageError != null || otherError != null) {
      state = (
        messageError: messageError,
        localizedMessageError: localizedMessageError,
        otherError: otherError,
        localizedOtherError: localizedOtherError,
        saveError: null,
        localizedSaveError: null,
      );
      return FailureResult<FeedbackEntry>(
        ValidationFailure(
          message: messageError ?? otherError!,
          localizedMessage: localizedMessageError ?? localizedOtherError,
          localizedRecovery:
              Copy.messages.failureCorrectTheHighlightedFieldAndSaveAgain,
        ),
      );
    }
    final Result<FeedbackEntry> result = await ref
        .read(feedbackRepositoryProvider)
        .add(
          category: draft.category,
          message: text,
          context: draft.context,
          otherCategory: isOther ? named : null,
          screenshots: <Uint8List>[
            if (draft.attachShots)
              for (final FeedbackShot shot in draft.shots) shot.bytes,
          ],
        );
    // A saved draft is done even if the form was folded away mid-save, so
    // it cannot be saved twice; a folded form has no verdicts to show.
    if (result is Success<FeedbackEntry>) {
      drafts.clear();
    }
    if (!ref.mounted) {
      return result;
    }
    switch (result) {
      case Success<FeedbackEntry>():
        state = _clean;
      case FailureResult<FeedbackEntry>(:final Failure failure):
        state = (
          messageError: null,
          localizedMessageError: null,
          otherError: null,
          localizedOtherError: null,
          saveError: failure.message,
          localizedSaveError: failure.explanation,
        );
    }
    return result;
  }
}

/// Verdicts for [GiveFeedbackScreen]. Disposed with the form, so every
/// opening starts without stale errors (FE-STATE-09).
final NotifierProvider<GiveFeedbackController, GiveFeedbackView>
giveFeedbackControllerProvider =
    NotifierProvider.autoDispose<GiveFeedbackController, GiveFeedbackView>(
      GiveFeedbackController.new,
    );

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';

import '../domain/feedback_category.dart';
import 'feedback_draft.dart';
import 'feedback_shot.dart';

/// Holds [FeedbackDraft] from a Feedback tap until the operator saves or
/// discards it, including while they move through the app.
final class FeedbackDraftController extends Notifier<FeedbackDraft?> {
  /// Creates the holder.
  FeedbackDraftController();

  int _nextShot = 1;

  @override
  FeedbackDraft? build() => null;

  /// Replaces the draft with a new capture when none is open. An open draft
  /// keeps its text and gains [draft]'s first shot.
  void capture(FeedbackDraft draft) {
    final FeedbackDraft? current = state;
    if (current != null && current.open) {
      if (draft.shots.isEmpty) {
        return;
      }
      final FeedbackShot incoming = draft.shots.first;
      addShot(
        FeedbackShot(
          id: nextShotId(),
          bytes: incoming.bytes,
          label: incoming.label,
        ),
      );
      return;
    }
    state = draft.copyWith(open: false, expanded: false);
  }

  /// Opens Give us feedback, keeping anything already written.
  void openGive() {
    final FeedbackDraft? current = state;
    if (current == null) {
      return;
    }
    state = current.copyWith(open: true, expanded: true);
  }

  /// Shows the compact bar so the rest of the app stays usable.
  void collapse() {
    final FeedbackDraft? current = state;
    if (current == null) {
      return;
    }
    state = current.copyWith(expanded: false, open: true);
  }

  /// Brings the full form back.
  void expand() {
    final FeedbackDraft? current = state;
    if (current == null) {
      return;
    }
    state = current.copyWith(open: true, expanded: true);
  }

  /// Writes the in-progress text.
  void setText({String? message, String? other}) {
    final FeedbackDraft? current = state;
    if (current == null) {
      return;
    }
    state = current.copyWith(message: message, other: other);
  }

  /// Writes the chosen type.
  void setCategory(FeedbackCategory category) {
    final FeedbackDraft? current = state;
    if (current == null) {
      return;
    }
    state = current.copyWith(category: category);
  }

  /// Whether attached images are stored with the entry.
  void setAttachShots(bool attach) {
    final FeedbackDraft? current = state;
    if (current == null) {
      return;
    }
    state = current.copyWith(attachShots: attach);
  }

  /// Adds [shot] when there is still room. Returns a reason when it cannot.
  String? addShot(FeedbackShot shot) {
    final FeedbackDraft? current = state;
    if (current == null) {
      return Copy.somethingWentWrong;
    }
    if (current.shots.length >= AppConstants.userFeedback.maxShots) {
      return Copy.feedbackShotsFull;
    }
    state = current.copyWith(
      shots: <FeedbackShot>[...current.shots, shot],
      attachShots: true,
    );
    return null;
  }

  /// Drops the attached image with [id].
  void removeShot(String id) {
    final FeedbackDraft? current = state;
    if (current == null) {
      return;
    }
    state = current.copyWith(
      shots: <FeedbackShot>[
        for (final FeedbackShot shot in current.shots)
          if (shot.id != id) shot,
      ],
    );
  }

  /// A new id for a shot added after the first capture.
  String nextShotId() {
    final String id = 'shot-$_nextShot';
    _nextShot += 1;
    return id;
  }

  /// Drops the draft.
  void clear() => state = null;
}

/// The screenshot, text and attachments for the in-progress feedback.
final NotifierProvider<FeedbackDraftController, FeedbackDraft?>
feedbackDraftProvider =
    NotifierProvider<FeedbackDraftController, FeedbackDraft?>(
      FeedbackDraftController.new,
    );

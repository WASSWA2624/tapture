import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';

import '../domain/feedback_category.dart';
import '../domain/feedback_context.dart';
import 'feedback_draft.dart';
import 'feedback_shot.dart';

/// Holds [FeedbackDraft] from a Feedback tap until the operator saves or
/// discards it, including while they move through the app.
final class FeedbackDraftController extends Notifier<FeedbackDraft?> {
  /// Creates the holder.
  FeedbackDraftController();

  int _shots = 0;

  @override
  FeedbackDraft? build() => null;

  /// A Feedback tap on [context]. Starts a fresh draft, unless one is open,
  /// which keeps its text and gains [screenshot]. Returns why the open
  /// draft could not take it, or null.
  String? capture({required FeedbackContext context, Uint8List? screenshot}) {
    final FeedbackDraft? current = state;
    final bool pictured = screenshot != null && screenshot.isNotEmpty;
    final String label = Copy.feedbackScreenshotOf(context.screen);
    if (current != null && current.open) {
      return pictured ? addShot(screenshot, label: label) : null;
    }
    state = FeedbackDraft(
      context: context,
      shots: <FeedbackShot>[if (pictured) _shot(screenshot, label)],
    );
    return null;
  }

  /// Opens the full form, keeping anything already written.
  void expand() => _update((FeedbackDraft d) {
    return d.copyWith(open: true, expanded: true);
  });

  /// Shows the compact bar so the rest of the app stays usable.
  void collapse() => _update((FeedbackDraft d) {
    return d.copyWith(open: true, expanded: false);
  });

  /// Writes the in-progress text.
  void setText({String? message, String? other}) {
    _update((FeedbackDraft d) => d.copyWith(message: message, other: other));
  }

  /// Writes the chosen type.
  void setCategory(FeedbackCategory category) {
    _update((FeedbackDraft d) => d.copyWith(category: category));
  }

  /// Whether attached images are stored with the entry.
  void setAttachShots(bool attach) {
    _update((FeedbackDraft d) => d.copyWith(attachShots: attach));
  }

  /// Adds an image while there is room, and turns attach on. Returns why
  /// it could not, or null.
  String? addShot(Uint8List bytes, {required String label}) {
    final FeedbackDraft? current = state;
    if (current == null) {
      return Copy.somethingWentWrong;
    }
    if (current.shots.length >= AppConstants.userFeedback.maxShots) {
      return Copy.feedbackShotsFull;
    }
    state = current.copyWith(
      shots: <FeedbackShot>[...current.shots, _shot(bytes, label)],
      attachShots: true,
    );
    return null;
  }

  /// Drops the image with [id].
  void removeShot(String id) {
    _update((FeedbackDraft d) {
      return d.copyWith(
        shots: <FeedbackShot>[
          for (final FeedbackShot shot in d.shots)
            if (shot.id != id) shot,
        ],
      );
    });
  }

  /// Drops the draft.
  void clear() => state = null;

  FeedbackShot _shot(Uint8List bytes, String label) {
    _shots += 1;
    return FeedbackShot(id: 'shot-$_shots', bytes: bytes, label: label);
  }

  void _update(FeedbackDraft Function(FeedbackDraft draft) change) {
    final FeedbackDraft? current = state;
    if (current != null) {
      state = change(current);
    }
  }
}

/// The in-progress feedback. Kept alive: it outlives every screen it is
/// written on (FE-STATE-09).
final NotifierProvider<FeedbackDraftController, FeedbackDraft?>
feedbackDraftProvider =
    NotifierProvider<FeedbackDraftController, FeedbackDraft?>(
      FeedbackDraftController.new,
    );

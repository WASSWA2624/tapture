import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'review_position.dart';

/// Walks the review queue one record at a time (task 016 step 5): skip,
/// back, and on to the next record once one is approved. Edits are saved
/// as they are made, so a record left and returned to shows them intact.
final class ReviewCursor extends Notifier<ReviewPosition> {
  /// Creates the walk of project [projectId]'s queue.
  ReviewCursor(this.projectId);

  /// The project whose queue is walked.
  final String projectId;

  @override
  ReviewPosition build() => const ReviewPosition();

  /// Moves past the record shown without approving it.
  void skip(List<String> ids) {
    final String? shown = state.currentIn(ids);
    if (shown == null) {
      return;
    }
    final int at = ids.indexOf(shown);
    state = at + 1 < ids.length
        ? ReviewPosition(current: ids[at + 1])
        : ReviewPosition(current: shown, done: true);
  }

  /// Returns to the record before the one shown, or to the last record
  /// once the walk has finished.
  void back(List<String> ids) {
    if (!state.canGoBack(ids)) {
      return;
    }
    if (state.done) {
      state = ReviewPosition(current: ids.last);
      return;
    }
    final int at = ids.indexOf(state.currentIn(ids)!);
    state = ReviewPosition(current: ids[at - 1]);
  }

  /// Moves on after an approval: to [next], or to the end when there is
  /// none.
  void approved(String? next) {
    state = next == null
        ? ReviewPosition(current: state.current, done: true)
        : ReviewPosition(current: next);
  }
}

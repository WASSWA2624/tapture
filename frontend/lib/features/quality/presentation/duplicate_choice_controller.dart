import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/duplicate_choice.dart';

/// The outcome picked in one open question about duplicates (task 015),
/// keyed by the question: a pair's prompt or a group's bulk choice. Null
/// until a person picks; nothing here chooses for them.
final duplicateChoiceControllerProvider = NotifierProvider.autoDispose
    .family<DuplicateChoiceController, DuplicateChoice?, String>(
      DuplicateChoiceController.new,
    );

/// Holds the outcome a person has picked but not yet confirmed.
final class DuplicateChoiceController extends Notifier<DuplicateChoice?> {
  /// Creates the pick for the question [question].
  DuplicateChoiceController(this.question);

  /// Which question this pick answers.
  final String question;

  @override
  DuplicateChoice? build() => null;

  /// Records [choice] as picked.
  void pick(DuplicateChoice choice) {
    state = choice;
  }
}

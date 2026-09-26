import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The context groups picked on the queue screen for Process selected.
///
/// A long press adds or removes a group. Leaving the screen forgets the
/// picks.
final class QueueSelection extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  /// Picks [label], or drops it when it is already picked.
  void toggle(String label) {
    state = state.contains(label)
        ? (<String>{...state}..remove(label))
        : <String>{...state, label};
  }

  /// Picks nothing.
  void clear() => state = const <String>{};
}

/// The groups picked for Process selected, while the queue is open.
final NotifierProvider<QueueSelection, Set<String>> queueSelectionProvider =
    NotifierProvider.autoDispose<QueueSelection, Set<String>>(
      QueueSelection.new,
    );

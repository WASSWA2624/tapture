import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The records ticked in one project's list, for bulk actions (task 014
/// step 8). Keyed by project id so two projects never share a selection.
/// Auto-dispose: leaving the list drops the selection (FE-STATE-09).
final recordSelectionProvider = NotifierProvider.autoDispose
    .family<RecordSelection, Set<String>, String>(RecordSelection.new);

/// Which of one project's records are ticked. Long-press ticks the first
/// one (FE-CONS-10); while any is ticked the list is in selection mode and a
/// tap toggles instead of opening.
///
/// The state is an unmodifiable set of record ids. A call that changes
/// nothing leaves the state as it was, so watchers do not rebuild.
final class RecordSelection extends Notifier<Set<String>> {
  /// Creates the selection for [projectId]'s list.
  RecordSelection(this.projectId);

  /// The project whose records are ticked.
  final String projectId;

  @override
  Set<String> build() => const <String>{};

  /// Whether any record is ticked, so the list is in selection mode.
  bool get isActive => state.isNotEmpty;

  /// How many records are ticked, the number the action bar names.
  int get count => state.length;

  /// Whether record [id] is ticked.
  bool isSelected(String id) => state.contains(id);

  /// Ticks record [id] when it is not ticked, and unticks it when it is.
  void toggle(String id) {
    final Set<String> next = Set<String>.of(state);
    if (!next.add(id)) {
      next.remove(id);
    }
    _set(next);
  }

  /// Ticks record [id]. Already ticked, nothing changes.
  void select(String id) {
    if (state.contains(id)) {
      return;
    }
    _set(<String>{...state, id});
  }

  /// Ticks every record in [ids], keeping those already ticked.
  void selectAll(Iterable<String> ids) {
    final Set<String> next = <String>{...state, ...ids};
    if (next.length == state.length) {
      return;
    }
    _set(next);
  }

  /// Unticks every record in [ids], such as those a bulk action has moved
  /// out of the list. The rest stay ticked.
  void deselectAll(Iterable<String> ids) {
    final Set<String> next = Set<String>.of(state)..removeAll(ids);
    if (next.length == state.length) {
      return;
    }
    _set(next);
  }

  /// Unticks everything and leaves selection mode.
  void clear() {
    if (state.isEmpty) {
      return;
    }
    _set(const <String>{});
  }

  void _set(Set<String> next) {
    state = Set<String>.unmodifiable(next);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/merge_history_entry.dart';
import '../merge.dart' show mergeRepositoryProvider;

/// Live durable history for one project.
final mergeHistoryProvider = StreamProvider.autoDispose
    .family<List<MergeHistoryEntry>, String>((Ref ref, String projectId) {
      return ref.watch(mergeRepositoryProvider)?.watchHistory(projectId) ??
          Stream<List<MergeHistoryEntry>>.value(const <MergeHistoryEntry>[]);
    });

/// Sessions currently restoring; suppresses repeated undo requests.
final mergeHistoryControllerProvider =
    NotifierProvider.autoDispose<MergeHistoryController, Set<String>>(
      MergeHistoryController.new,
    );

/// Keeps undo orchestration outside the history widget.
final class MergeHistoryController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  /// Runs one restore and tracks its busy state until completion.
  Future<Result<void>> undo(String id) async {
    final repository = ref.read(mergeRepositoryProvider);
    if (repository == null || state.contains(id)) {
      return const FailureResult<void>(CancelledFailure());
    }
    state = <String>{...state, id};
    final Result<void> restored = await repository.undo(id);
    if (ref.mounted) {
      state = <String>{
        for (final String pending in state)
          if (pending != id) pending,
      };
    }
    return restored;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/feedback_filter.dart';
import '../domain/removed_feedback.dart';
import 'delete_feedback_view.dart';
import 'feedback_providers.dart';

/// Filters, selects and deletes matching feedback.
final class DeleteFeedbackController extends Notifier<DeleteFeedbackView> {
  /// Creates the controller.
  DeleteFeedbackController();

  @override
  DeleteFeedbackView build() {
    return (
      filter: const FeedbackFilter(),
      selected: const <String>{},
      visible: AppConstants.userFeedback.listPageSize,
      busy: false,
      error: null,
    );
  }

  /// Replaces the filter, drops selection outside it, and resets the page.
  void setFilter(FeedbackFilter filter) {
    state = (
      filter: filter,
      selected: state.selected,
      visible: AppConstants.userFeedback.listPageSize,
      busy: false,
      error: null,
    );
  }

  /// Shows another page of matching rows.
  void showMore() {
    state = (
      filter: state.filter,
      selected: state.selected,
      visible: state.visible + AppConstants.userFeedback.listPageSize,
      busy: state.busy,
      error: state.error,
    );
  }

  /// Ticks or unticks [id].
  void toggle(String id) {
    final Set<String> next = Set<String>.of(state.selected);
    if (!next.add(id)) {
      next.remove(id);
    }
    state = (
      filter: state.filter,
      selected: next,
      visible: state.visible,
      busy: state.busy,
      error: state.error,
    );
  }

  /// Ticks every id in [ids], or clears when all of them are already ticked.
  void toggleAll(Iterable<String> ids) {
    final Set<String> all = ids.toSet();
    final bool allOn = all.isNotEmpty && all.every(state.selected.contains);
    state = (
      filter: state.filter,
      selected: allOn ? <String>{} : all,
      visible: state.visible,
      busy: state.busy,
      error: state.error,
    );
  }

  /// Deletes the ticked entries. Completes after the write is durable.
  Future<Result<List<RemovedFeedback>>> removeSelected() async {
    if (state.selected.isEmpty) {
      return const Success<List<RemovedFeedback>>(<RemovedFeedback>[]);
    }
    state = (
      filter: state.filter,
      selected: state.selected,
      visible: state.visible,
      busy: true,
      error: null,
    );
    final Result<List<RemovedFeedback>> result = await ref
        .read(feedbackRepositoryProvider)
        .remove(state.selected);
    switch (result) {
      case Success<List<RemovedFeedback>>():
        state = (
          filter: state.filter,
          selected: const <String>{},
          visible: state.visible,
          busy: false,
          error: null,
        );
        return result;
      case FailureResult<List<RemovedFeedback>>(:final Failure failure):
        state = (
          filter: state.filter,
          selected: state.selected,
          visible: state.visible,
          busy: false,
          error: failure.message,
        );
        return result;
    }
  }

  /// Puts entries [removeSelected] returned back.
  Future<Result<void>> restore(List<RemovedFeedback> removed) {
    return ref.read(feedbackRepositoryProvider).restore(removed);
  }
}

/// Filter, selection and delete state for [DeleteFeedbackScreen].
final NotifierProvider<DeleteFeedbackController, DeleteFeedbackView>
deleteFeedbackControllerProvider =
    NotifierProvider<DeleteFeedbackController, DeleteFeedbackView>(
      DeleteFeedbackController.new,
    );

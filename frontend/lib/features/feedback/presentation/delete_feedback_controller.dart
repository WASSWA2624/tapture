import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/feedback_filter.dart';
import '../domain/feedback_repository.dart';
import '../domain/removed_feedback.dart';
import 'delete_feedback_view.dart';
import 'feedback_providers.dart';

/// Filters, selects and deletes matching feedback.
final class DeleteFeedbackController extends Notifier<DeleteFeedbackView> {
  /// Creates the controller.
  DeleteFeedbackController();

  /// Held so [restore] still works from the snackbar after the screen closes.
  late FeedbackRepository _repository;

  @override
  DeleteFeedbackView build() {
    _repository = ref.watch(feedbackRepositoryProvider);
    return (
      filter: const FeedbackFilter(),
      moreFilters: false,
      selected: const <String>{},
      visible: AppConstants.userFeedback.listPageSize,
      busy: false,
      error: null,
    );
  }

  /// Replaces the filter, drops selection outside it, and resets the page.
  void setFilter(FeedbackFilter filter) {
    _set(
      filter: filter,
      visible: AppConstants.userFeedback.listPageSize,
      busy: false,
      error: null,
    );
  }

  /// Opens or folds the facets beyond search and type.
  void toggleMoreFilters() {
    _set(moreFilters: !state.moreFilters);
  }

  /// Shows another page of matching rows.
  void showMore() {
    _set(visible: state.visible + AppConstants.userFeedback.listPageSize);
  }

  /// Ticks or unticks [id].
  void toggle(String id) {
    final Set<String> next = Set<String>.of(state.selected);
    if (!next.add(id)) {
      next.remove(id);
    }
    _set(selected: next);
  }

  /// Ticks every id in [ids], or clears when all of them are already ticked.
  void toggleAll(Iterable<String> ids) {
    final Set<String> all = ids.toSet();
    final bool allOn = all.isNotEmpty && all.every(state.selected.contains);
    _set(selected: allOn ? <String>{} : all);
  }

  /// Deletes the ticked entries. Completes after the write is durable.
  Future<Result<List<RemovedFeedback>>> removeSelected() async {
    if (state.selected.isEmpty) {
      return const Success<List<RemovedFeedback>>(<RemovedFeedback>[]);
    }
    _set(busy: true, error: null);
    final Result<List<RemovedFeedback>> result = await _repository.remove(
      state.selected,
    );
    // The delete is durable either way; a closed screen has no state to set.
    if (!ref.mounted) {
      return result;
    }
    switch (result) {
      case Success<List<RemovedFeedback>>():
        _set(selected: const <String>{}, busy: false, error: null);
      case FailureResult<List<RemovedFeedback>>(:final Failure failure):
        _set(busy: false, error: failure.message);
    }
    return result;
  }

  /// Puts entries [removeSelected] returned back. Safe after the screen has
  /// closed: undo lives on the snackbar, which can outlast it.
  Future<Result<void>> restore(List<RemovedFeedback> removed) {
    return _repository.restore(removed);
  }

  /// [state] with the given parts replaced. [error] is kept unless given.
  void _set({
    FeedbackFilter? filter,
    bool? moreFilters,
    Set<String>? selected,
    int? visible,
    bool? busy,
    Object? error = _keep,
  }) {
    state = (
      filter: filter ?? state.filter,
      moreFilters: moreFilters ?? state.moreFilters,
      selected: selected ?? state.selected,
      visible: visible ?? state.visible,
      busy: busy ?? state.busy,
      error: identical(error, _keep) ? state.error : error as String?,
    );
  }
}

/// Marks "leave the error as it is" in [DeleteFeedbackController._set].
const Object _keep = Object();

/// Filter, selection and delete state for [DeleteFeedbackScreen]. Disposed
/// with the screen, so every opening starts with nothing ticked
/// (FE-STATE-09).
final NotifierProvider<DeleteFeedbackController, DeleteFeedbackView>
deleteFeedbackControllerProvider =
    NotifierProvider.autoDispose<DeleteFeedbackController, DeleteFeedbackView>(
      DeleteFeedbackController.new,
    );

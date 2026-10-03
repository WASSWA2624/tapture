import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/reference_repository.dart';
import '../reference.dart' show referenceRepositoryProvider;

/// One dataset row being corrected in place, or added from capture when
/// the target names no row (task 010 step 5).
///
/// The key is read from the dataset's key column, whichever position that
/// column holds. Every change is written with the values it replaces, so
/// the audit trail keeps them; records already prefilled from the row keep
/// the values they captured.
final class DatasetRowController extends AsyncNotifier<DatasetRowView> {
  /// Creates the controller for [target].
  DatasetRowController(this.target);

  /// The dataset, and the row to edit or '' to add one.
  final DatasetRowTarget target;

  @override
  Future<DatasetRowView> build() async {
    final ReferenceRepository repository = ref.watch(
      referenceRepositoryProvider,
    );
    ReferenceRow? row;
    if (target.rowId.isNotEmpty) {
      row = _ok(await repository.rowById(target.rowId));
      if (row == null) {
        return (
          row: null,
          dataset: null,
          saveError: null,
          localizedSaveError: null,
        );
      }
    }
    final String datasetId = row?.datasetId ?? target.datasetId;
    final ReferenceDataset? dataset = datasetId.isEmpty
        ? null
        : _ok(await repository.byId(datasetId));
    return (
      row: row,
      dataset: dataset,
      saveError: null,
      localizedSaveError: null,
    );
  }

  /// Writes [values] (column → value) as the row. Editing keeps the row's
  /// id and records what each value replaced; adding flags the new row
  /// added on this device. Completes with the stored row, or null when it
  /// was not stored; the reason is then [DatasetRowView.saveError] and the
  /// typed values stay on screen.
  Future<ReferenceRow?> save(Map<String, String> values) async {
    final DatasetRowView? view = state.value;
    final ReferenceDataset? dataset = view?.dataset;
    if (view == null || dataset == null) {
      return null;
    }
    final ReferenceRow? existing = view.row;
    final String key = (values[dataset.keyColumn] ?? existing?.key ?? '')
        .trim();
    final Map<String, String> cells = <String, String>{
      ...values,
      if (values.containsKey(dataset.keyColumn)) dataset.keyColumn: key,
    };
    final ReferenceRow row = existing == null
        ? ReferenceRow(
            id: '',
            datasetId: dataset.id,
            key: key,
            values: cells,
            addedOnDevice: true,
          )
        : existing.copyWith(key: key, values: cells);
    final Result<ReferenceRow> saved = await ref
        .read(referenceRepositoryProvider)
        .saveRow(row, previousValues: existing?.values);
    if (!ref.mounted) {
      return null;
    }
    switch (saved) {
      case FailureResult<ReferenceRow>(:final Failure failure):
        state = AsyncData<DatasetRowView>((
          row: existing,
          dataset: dataset,
          saveError: failure.message,
          localizedSaveError: failure.explanation,
        ));
        return null;
      case Success<ReferenceRow>(:final ReferenceRow value):
        state = AsyncData<DatasetRowView>((
          row: existing == null ? null : value,
          dataset: dataset,
          saveError: null,
          localizedSaveError: null,
        ));
        return value;
    }
  }
}

/// The dataset a row belongs to and the row's id, '' for a new row.
typedef DatasetRowTarget = ({String datasetId, String rowId});

/// The row as stored (null when it is missing, or not yet added), its
/// dataset, and why the last save failed.
typedef DatasetRowView = ({
  ReferenceRow? row,
  ReferenceDataset? dataset,
  String? saveError,
  LocalizedMessage? localizedSaveError,
});

/// One row edit or addition. Auto-dispose: closing the form drops it
/// (FE-STATE-09).
final datasetRowControllerProvider = AsyncNotifierProvider.autoDispose
    .family<DatasetRowController, DatasetRowView, DatasetRowTarget>(
      DatasetRowController.new,
      retry: (int _, Object _) => null,
    );

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw failure,
  };
}

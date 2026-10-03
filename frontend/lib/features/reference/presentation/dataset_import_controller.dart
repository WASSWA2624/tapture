import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';

import '../domain/dataset_import_draft.dart';
import '../domain/reference_dataset.dart';
import '../domain/reference_row.dart';
import '../reference.dart' show DatasetImport, referenceRepositoryProvider;

/// The end of every dataset import (task 010 step 3): read the chosen
/// table off the UI thread, let the operator pick its key column, and save
/// it, marked as holding duplicates only once they have said so.
final class DatasetImportController extends Notifier<DatasetImportView> {
  /// Creates the controller, starting from [seed] when a draft was handed
  /// over already parsed.
  DatasetImportController(this.seed);

  /// A draft parsed before the screen opened, or null to choose a file.
  final DatasetImportDraft? seed;

  CancellationToken? _cancel;

  @override
  DatasetImportView build() {
    ref.onDispose(() => _cancel?.cancel());
    final DatasetImportDraft? draft = seed;
    return (
      draft: draft,
      keyColumn: draft?.dataset.keyColumn,
      reading: false,
      progress: 0,
      failure: null,
      saving: false,
    );
  }

  /// Opens the document picker and reads the chosen CSV, JSON or
  /// spreadsheet into a draft for [projectId]. Closing the picker changes
  /// nothing.
  Future<void> pick({String? projectId}) async {
    if (state.reading || state.saving) {
      return;
    }
    final CancellationToken cancel = CancellationToken();
    _cancel = cancel;
    state = _next(reading: true, progress: 0, clearFailure: true);
    final Result<PickedDocument> picked = await ref
        .read(documentPickerProvider)
        .pick(
          extensions: const <String>['csv', 'xlsx', 'json'],
          mimeType: '',
          maxBytes: AppConstants.imports.spreadsheetMaxBytes,
        );
    if (!ref.mounted) {
      return;
    }
    final Result<DatasetImportDraft> parsed = await picked.fold(
      FailureResult<DatasetImportDraft>.new,
      (PickedDocument document) => DatasetImport.read(
        document,
        projectId: projectId,
        cancel: cancel,
        onProgress: _progress,
      ),
    );
    if (!ref.mounted) {
      return;
    }
    switch (parsed) {
      case FailureResult<DatasetImportDraft>(:final Failure failure):
        state = failure is CancelledFailure
            ? _next(reading: false)
            : _next(reading: false, failure: failure);
      case Success<DatasetImportDraft>(:final DatasetImportDraft value):
        state = (
          draft: value,
          keyColumn: value.dataset.keyColumn,
          reading: false,
          progress: 1,
          failure: null,
          saving: false,
        );
    }
  }

  /// Makes [column] the key the dataset is saved under.
  void chooseKey(String column) {
    final DatasetImportDraft? draft = state.draft;
    if (draft == null || !draft.dataset.columns.contains(column)) {
      return;
    }
    state = _next(keyColumn: column, clearFailure: true);
  }

  /// Saves the draft keyed on the chosen column, marked as holding
  /// duplicates when that column repeats (the screen asks first). Completes
  /// with the stored dataset, or null when it could not be saved; the reason
  /// is then in [DatasetImportView.failure].
  Future<ReferenceDataset?> save() async {
    final DatasetImportDraft? draft = state.draft;
    final String? key = state.keyColumn;
    if (draft == null || key == null || state.saving) {
      return null;
    }
    state = _next(saving: true, clearFailure: true);
    final List<ReferenceRow> rows = <ReferenceRow>[
      for (final ReferenceRow row in draft.rows)
        row.copyWith(key: row.values[key] ?? ''),
    ];
    final Result<ReferenceDataset> saved = await ref
        .read(referenceRepositoryProvider)
        .importDataset(
          dataset: draft.dataset.copyWith(
            keyColumn: key,
            duplicatesAllowed: (draft.duplicateCounts[key] ?? 0) > 0,
            rowCount: rows.length,
          ),
          rows: rows,
        );
    if (!ref.mounted) {
      return null;
    }
    switch (saved) {
      case FailureResult<ReferenceDataset>(:final Failure failure):
        state = _next(saving: false, failure: failure);
        return null;
      case Success<ReferenceDataset>(:final ReferenceDataset value):
        state = _next(saving: false);
        return value;
    }
  }

  void _progress(double fraction) {
    if (ref.mounted && state.reading) {
      state = _next(progress: fraction);
    }
  }

  DatasetImportView _next({
    String? keyColumn,
    bool? reading,
    double? progress,
    Failure? failure,
    bool clearFailure = false,
    bool? saving,
  }) {
    return (
      draft: state.draft,
      keyColumn: keyColumn ?? state.keyColumn,
      reading: reading ?? state.reading,
      progress: progress ?? state.progress,
      failure: clearFailure ? null : (failure ?? state.failure),
      saving: saving ?? state.saving,
    );
  }
}

/// The import in progress: the parsed draft and its chosen key, whether a
/// file is being read and how far, why the last step failed, and whether
/// the dataset is being saved.
typedef DatasetImportView = ({
  DatasetImportDraft? draft,
  String? keyColumn,
  bool reading,
  double progress,
  Failure? failure,
  bool saving,
});

/// One import. Auto-dispose: leaving the key screen cancels a read and
/// drops the draft (FE-STATE-09).
final datasetImportControllerProvider = NotifierProvider.autoDispose
    .family<DatasetImportController, DatasetImportView, DatasetImportDraft?>(
      DatasetImportController.new,
      retry: (int _, Object _) => null,
    );

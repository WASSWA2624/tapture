import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/projects/projects.dart';

import '../domain/reference_dataset.dart';
import '../reference.dart' show DatasetExport, referenceRepositoryProvider;

/// The dataset browser's intent: what it searches for, which columns it
/// shows, and writing the dataset back out (task 010 steps 4 and 8).
final class DatasetBrowserController extends Notifier<DatasetBrowserView> {
  /// Creates the controller for [datasetId].
  DatasetBrowserController(this.datasetId);

  /// The dataset browsed.
  final String datasetId;

  @override
  DatasetBrowserView build() {
    return (query: '', columns: null, exporting: false);
  }

  /// Filters the rows on the key and the visible values.
  void search(String query) {
    state = (
      query: query.trim(),
      columns: state.columns,
      exporting: state.exporting,
    );
  }

  /// Shows [columns] beside the key, in dataset order.
  void showColumns(Set<String> columns) {
    state = (
      query: state.query,
      columns: Set<String>.unmodifiable(columns),
      exporting: state.exporting,
    );
  }

  /// Writes [dataset] as JSON when [json] is true, else CSV, into the
  /// exports of [projectId] (or the dataset's or open project) and hands it
  /// to the platform. Completes with the saved location or why not, or null
  /// when an export is already running.
  Future<Result<String?>?> export(
    ReferenceDataset dataset, {
    required bool json,
    String? projectId,
  }) async {
    if (state.exporting) {
      return null;
    }
    _exporting(true);
    try {
      final String? id =
          _present(projectId) ??
          _present(dataset.projectId) ??
          _present(ref.read(currentProjectProvider));
      final Project? project = id == null
          ? null
          : await ref.read(projectByIdProvider(id).future);
      if (!ref.mounted) {
        return null;
      }
      if (project == null) {
        return FailureResult<String?>(_noProject);
      }
      return await DatasetExport.download(
        dataset: dataset,
        repository: ref.read(referenceRepositoryProvider),
        downloads: ref.read(downloadServiceProvider),
        storageRoot: ref.read(storageRootProvider),
        projectFolder: project.folderName,
        exportId: UuidV7Service(const SystemClock()).newId(),
        json: json,
      );
    } on Object catch (error) {
      return FailureResult<String?>(Failure.from(error));
    } finally {
      if (ref.mounted) {
        _exporting(false);
      }
    }
  }

  void _exporting(bool on) {
    state = (query: state.query, columns: state.columns, exporting: on);
  }
}

/// What the browser shows: the search, the columns chosen beside the key
/// (null keeps the default), and whether an export is being written.
typedef DatasetBrowserView = ({
  String query,
  Set<String>? columns,
  bool exporting,
});

/// One browser's search and columns. Auto-dispose: leaving the dataset
/// forgets them (FE-STATE-09).
final datasetBrowserControllerProvider = NotifierProvider.autoDispose
    .family<DatasetBrowserController, DatasetBrowserView, String>(
      DatasetBrowserController.new,
      retry: (int _, Object _) => null,
    );

String? _present(String? id) => id == null || id.isEmpty ? null : id;

final StorageFailure _noProject = StorageFailure(
  localizedMessage: Copy.messages.datasetsExportNoProject,
  localizedRecovery: Copy.messages.datasetsExportNoProjectRecovery,
);

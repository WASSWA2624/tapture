import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/reference_dataset.dart';
import '../domain/reference_row.dart';
import '../reference.dart' show referenceRepositoryProvider;

// The dataset browser's reads (task 010 step 4). Search and paging happen in
// the repository; the browser never holds a dataset, only the pages on screen
// (FE-PERF-03, FE-PERF-09).

/// The dataset with this id, for the browser's title and columns. Null
/// when it is no longer on this device.
final datasetHeaderProvider = FutureProvider.autoDispose
    .family<ReferenceDataset?, String>((Ref ref, String id) async {
      final Result<ReferenceDataset?> read = await ref
          .watch(referenceRepositoryProvider)
          .byId(id);
      return switch (read) {
        Success<ReferenceDataset?>(:final ReferenceDataset? value) => value,
        FailureResult<ReferenceDataset?>(:final failure) => throw failure,
      };
    }, retry: (int _, Object _) => null);

/// How many of a dataset's rows a search keeps, kept current. The list's
/// length and its empty states read it. Auto-dispose: a count nobody shows
/// is dropped (FE-STATE-09).
final datasetRowCountProvider = StreamProvider.autoDispose
    .family<int, ({String datasetId, String query})>((
      Ref ref,
      ({String datasetId, String query}) search,
    ) {
      return ref
          .watch(referenceRepositoryProvider)
          .watchRowCount(datasetId: search.datasetId, query: search.query);
    }, retry: (int _, Object _) => null);

/// Page [page] of a dataset's matching rows in key order: [AppConstants.lists]
/// `pageSize` rows from `page * pageSize`, kept current.
///
/// Each row reads the page its index falls in, so only the pages on screen
/// are held; a page nobody shows is dropped with its query (FE-PERF-03).
final datasetRowsPageProvider = StreamProvider.autoDispose
    .family<List<ReferenceRow>, ({String datasetId, String query, int page})>((
      Ref ref,
      ({String datasetId, String query, int page}) at,
    ) {
      final int size = AppConstants.lists.pageSize;
      return ref
          .watch(referenceRepositoryProvider)
          .watchRows(
            datasetId: at.datasetId,
            offset: at.page * size,
            limit: size,
            query: at.query,
          );
    }, retry: (int _, Object _) => null);

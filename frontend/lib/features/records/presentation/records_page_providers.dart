import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/record_facets.dart';
import '../domain/record_filter.dart';
import '../domain/record_sort.dart';
import '../domain/record_summary.dart';
import '../records.dart' show recordRepositoryProvider;

// The records list's reads (task 014 step 2). Filtering, search, ordering and
// paging all happen in the query; the list never holds a project's records,
// only the pages on screen (FE-PERF-03).

/// How many of a project's records [RecordFilter] matches, kept current.
/// The list's length and its empty states read it. Auto-dispose: a count
/// nobody shows is dropped (FE-STATE-09).
final recordsCountProvider = StreamProvider.autoDispose
    .family<int, ({String projectId, RecordFilter filter})>((
      Ref ref,
      ({String projectId, RecordFilter filter}) query,
    ) {
      return ref
          .watch(recordRepositoryProvider)
          .watchCount(query.projectId, query.filter);
    }, retry: (int _, Object _) => null);

/// Page [page] of a project's matching records in the chosen order:
/// [AppConstants.lists] `pageSize` rows from `page * pageSize`, kept current.
///
/// Each list row reads the page its index falls in, so only the pages on
/// screen are held; a page nobody shows is dropped with its query
/// (FE-PERF-03, FE-STATE-09).
final recordsPageProvider = StreamProvider.autoDispose
    .family<
      List<RecordSummary>,
      ({String projectId, RecordFilter filter, RecordSort sort, int page})
    >((
      Ref ref,
      ({String projectId, RecordFilter filter, RecordSort sort, int page})
      query,
    ) {
      final int size = AppConstants.lists.pageSize;
      return ref
          .watch(recordRepositoryProvider)
          .watchPage(
            query.projectId,
            filter: query.filter,
            sort: query.sort,
            offset: query.page * size,
            limit: size,
          );
    }, retry: (int _, Object _) => null);

/// What a project's filter sheet offers, read once when the sheet opens.
/// A failed read is an error the sheet shows with a retry. Auto-dispose:
/// closing the sheet drops it, so the next opening reads fresh choices.
final recordsFacetsProvider = FutureProvider.autoDispose
    .family<RecordFacets, String>((Ref ref, String projectId) async {
      final Result<RecordFacets> read = await ref
          .watch(recordRepositoryProvider)
          .facets(projectId);
      return switch (read) {
        Success<RecordFacets>(:final RecordFacets value) => value,
        FailureResult<RecordFacets>(:final failure) => throw failure,
      };
    }, retry: (int _, Object _) => null);

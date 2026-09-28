import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/normalise/fuzzy_matcher.dart';

import '../domain/domain.dart';

/// Indexed key lookups followed by bounded, off-thread column matching.
abstract final class LookupSearch {
  /// Exact and normalised results precede optional scored suggestions.
  static Future<Result<LookupSearchResult>> find({
    required ReferenceRepository repository,
    required LookupBinding binding,
    required ReferenceDataset dataset,
    required String query,
  }) async {
    try {
      final String trimmed = query.trim();
      if (trimmed.isEmpty) {
        return const Success<LookupSearchResult>((
          matches: <ReferenceRow>[],
          suggested: false,
        ));
      }
      final ReferenceRow? exact = _ok(
        await repository.lookupByKey(datasetId: dataset.id, keyValue: trimmed),
      );
      if (exact != null) {
        return Success<LookupSearchResult>((
          matches: <ReferenceRow>[exact],
          suggested: false,
        ));
      }
      final List<ReferenceRow> folded = _ok(
        await repository.lookupByNormalised(
          datasetId: dataset.id,
          query: trimmed,
        ),
      );
      if (folded.isNotEmpty) {
        return Success<LookupSearchResult>((matches: folded, suggested: false));
      }
      final List<String> columns = binding.matchColumns.isEmpty
          ? <String>[dataset.keyColumn]
          : binding.matchColumns;
      final List<List<ReferenceRow>> exactByColumn = <List<ReferenceRow>>[
        for (final String _ in columns) <ReferenceRow>[],
      ];
      final List<_Scored> suggestions = <_Scored>[];
      int offset = 0;
      const int limit = AppConstants.listPageSize;
      while (true) {
        final List<ReferenceRow> page = _ok(
          await repository.pageRows(
            datasetId: dataset.id,
            offset: offset,
            limit: limit,
          ),
        );
        final _PageMatches matched = _ok(
          await runIsolate<_SearchPage, _PageMatches>(_matchPage, (
            rows: page,
            columns: columns,
            query: trimmed,
            fuzzy: binding.fuzzyEnabled,
            threshold: binding.fuzzyThreshold,
          )),
        );
        for (int i = 0; i < columns.length; i++) {
          exactByColumn[i].addAll(
            matched.exact[i].take(limit - exactByColumn[i].length),
          );
        }
        suggestions.addAll(matched.suggested);
        suggestions.sort((_Scored a, _Scored b) => b.score.compareTo(a.score));
        if (suggestions.length > limit) {
          suggestions.removeRange(limit, suggestions.length);
        }
        if (page.length < limit) {
          break;
        }
        offset += page.length;
      }
      for (final List<ReferenceRow> matches in exactByColumn) {
        if (matches.isNotEmpty) {
          return Success<LookupSearchResult>((
            matches: matches,
            suggested: false,
          ));
        }
      }
      return Success<LookupSearchResult>((
        matches: <ReferenceRow>[
          for (final _Scored suggestion in suggestions) suggestion.item,
        ],
        suggested: suggestions.isNotEmpty,
      ));
    } on Object catch (error) {
      return FailureResult<LookupSearchResult>(Failure.from(error));
    }
  }
}

/// Suggestions require confirmation even when only one candidate was found.
typedef LookupSearchResult = ({List<ReferenceRow> matches, bool suggested});
typedef _SearchPage = ({
  List<ReferenceRow> rows,
  List<String> columns,
  String query,
  bool fuzzy,
  double threshold,
});
typedef _PageMatches = ({
  List<List<ReferenceRow>> exact,
  List<_Scored> suggested,
});

/// A row and how closely it resembles the query, 0 to 1.
typedef _Scored = ({ReferenceRow item, double score});

_PageMatches _matchPage(_SearchPage page) {
  final List<List<ReferenceRow>> exact = <List<ReferenceRow>>[
    for (final String column in page.columns)
      LookupMatcher.match(
        rows: page.rows,
        query: page.query,
        matchColumns: <String>[column],
      ),
  ];
  final Map<String, _Scored> best = <String, _Scored>{};
  if (page.fuzzy) {
    for (final String column in page.columns) {
      for (final _Scored hit in FuzzyMatcher.rank<ReferenceRow>(
        items: page.rows,
        query: page.query,
        textOf: (ReferenceRow row) => row.values[column] ?? '',
        threshold: page.threshold,
      )) {
        if (hit.score > (best[hit.item.id]?.score ?? -1)) {
          best[hit.item.id] = hit;
        }
      }
    }
  }
  return (exact: exact, suggested: best.values.toList());
}

T _ok<T>(Result<T> result) => switch (result) {
  Success<T>(:final T value) => value,
  FailureResult<T>(failure: final Failure resultFailure) => throw resultFailure,
};

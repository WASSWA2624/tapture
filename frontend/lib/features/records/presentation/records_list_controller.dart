import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/logging/logger.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/projects/projects.dart'
    show projectSettingsStoreProvider;
import 'package:tapture/features/settings/settings.dart'
    show SettingKeys, SettingsStore;

import '../domain/record_filter.dart';
import '../domain/record_sort.dart';

/// What one project's records list shows, keyed by project id (task 014
/// step 2). Auto-dispose: leaving the list drops it, and the next visit
/// reads the remembered filter and sort back from the settings store, so
/// they survive a restart (D11, FE-STATE-09).
final recordsListControllerProvider = NotifierProvider.autoDispose
    .family<RecordsListController, RecordsListCriteria, String>(
      RecordsListController.new,
      retry: (int _, Object _) => null,
    );

/// The filter, sort and search text of one project's records list.
///
/// The filter and sort are remembered per project under
/// [SettingKeys.recordListCriteria] and read back on the next visit; the
/// search text lives only as long as the list (D11). Every change is applied
/// in the query, never to rows already loaded (step 2).
final class RecordsListController extends Notifier<RecordsListCriteria> {
  /// Creates the list state of [projectId].
  RecordsListController(this.projectId);

  /// The project whose records are listed.
  final String projectId;

  @override
  RecordsListCriteria build() {
    final SettingsStore store = ref.watch(projectSettingsStoreProvider);
    return _restore(store.read(SettingKeys.recordListCriteria), projectId);
  }

  /// Narrows the list to records matching [text] in their values, captions,
  /// transcripts and OCR text. Not remembered.
  void setSearch(String text) {
    if (text == state.filter.search) {
      return;
    }
    state = (filter: state.filter.copyWith(search: text), sort: state.sort);
  }

  /// Applies [filter]'s dimensions and remembers them for the project. The
  /// search text stays as typed, whatever [filter] carries.
  void applyFilter(RecordFilter filter) {
    final RecordFilter next = filter.copyWith(search: state.filter.search);
    if (next == state.filter) {
      return;
    }
    state = (filter: next, sort: state.sort);
    _remember();
  }

  /// Orders the list by [sort] and remembers it for the project.
  void applySort(RecordSort sort) {
    if (sort == state.sort) {
      return;
    }
    state = (filter: state.filter, sort: sort);
    _remember();
  }

  /// Turns every filter off in one tap and remembers that. The search text
  /// stays: its field shows it and clears it.
  void clearFilters() {
    applyFilter(state.filter.withoutCriteria());
  }

  /// Turns every filter off and empties the search: what a list that
  /// matches nothing offers.
  void clearAll() {
    clearFilters();
    setSearch('');
  }

  /// Lists only [status] for this visit, as a deep link such as the
  /// processing notification's `?filter=needsReview` asks. The remembered
  /// filter is left as it was until the operator changes something.
  void showOnly(RecordStatus status) {
    final RecordFilter next = state.filter.copyWith(
      statuses: <RecordStatus>{status},
    );
    if (next == state.filter) {
      return;
    }
    state = (filter: next, sort: state.sort);
  }

  /// Writes this project's filter (without search) and sort into the
  /// per-project map. A project back at the defaults leaves the map.
  void _remember() {
    final SettingsStore store = ref.read(projectSettingsStoreProvider);
    final Map<String, Object?> all = _decode(
      store.read(SettingKeys.recordListCriteria),
    );
    final RecordFilter kept = state.filter.withoutSearch();
    if (kept == RecordFilter.none && state.sort == RecordSort.newestFirst) {
      all.remove(projectId);
    } else {
      all[projectId] = <String, Object?>{
        _filterField: kept.toJson(),
        _sortField: state.sort.toJson(),
      };
    }
    unawaited(_write(store, jsonEncode(all)));
  }

  Future<void> _write(SettingsStore store, String encoded) async {
    final Result<void> written = await store.write(
      SettingKeys.recordListCriteria,
      encoded,
    );
    if (written is FailureResult<void>) {
      Logger.current.warn('records', 'list filter and sort were not saved');
    }
  }
}

/// A records list's filter, whose search text is part of it, and its order.
typedef RecordsListCriteria = ({RecordFilter filter, RecordSort sort});

const String _filterField = 'filter';
const String _sortField = 'sort';

const RecordsListCriteria _defaults = (
  filter: RecordFilter.none,
  sort: RecordSort.newestFirst,
);

/// [projectId]'s remembered criteria out of the stored map [raw]. Anything
/// missing, malformed or unknown falls back to the defaults, never throws.
RecordsListCriteria _restore(String raw, String projectId) {
  final Object? entry = _decode(raw)[projectId];
  if (entry is! Map<String, Object?>) {
    return _defaults;
  }
  final Object? filter = entry[_filterField];
  final Object? sort = entry[_sortField];
  return (
    filter: filter is Map<String, Object?>
        ? RecordFilter.fromJson(filter).withoutSearch()
        : RecordFilter.none,
    sort: sort is Map<String, Object?>
        ? RecordSort.fromJson(sort)
        : RecordSort.newestFirst,
  );
}

Map<String, Object?> _decode(String raw) {
  try {
    final Object? decoded = jsonDecode(raw);
    if (decoded is Map<String, Object?>) {
      return Map<String, Object?>.of(decoded);
    }
  } on FormatException {
    // A broken map reads as empty; the next change rewrites it.
  }
  return <String, Object?>{};
}

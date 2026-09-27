import 'dart:convert';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/normalise/fuzzy_matcher.dart';
import 'package:tapture/core/normalise/search_text.dart';

import 'duplicate_signal.dart';
import 'possible_duplicate.dart';

/// Finds incoming records that may duplicate local ones (specification §40,
/// task 076, W22). Pure: rows in, pairs out, nothing written (FE-STR-05).
/// Rows are keyed by SQL column name, as a project package carries them.
///
/// Only records crossing the boundary are compared, and only against live
/// local records under the matched template, so two records captured on one
/// device are never paired here.
abstract final class DuplicateSignals {
  /// Pairs each record of [candidates] (incoming ids the merge would insert)
  /// with every live local record that looks like it, strongest signal
  /// first. [templateMapping] maps incoming template ids to local ones.
  static List<PossibleDuplicate> find({
    required Map<String, List<Map<String, Object?>>> incoming,
    required Map<String, List<Map<String, Object?>>> local,
    required Map<String, String> templateMapping,
    required Iterable<String> candidates,
  }) {
    final _Side theirs = _Side(incoming);
    final _Side mine = _Side(local);
    final Map<String, List<Map<String, Object?>>> byTemplate =
        <String, List<Map<String, Object?>>>{};
    for (final Map<String, Object?> record in mine.live) {
      byTemplate
          .putIfAbsent(record['template_id']! as String, () => [])
          .add(record);
    }
    final List<PossibleDuplicate> pairs = <PossibleDuplicate>[];
    for (final String id in candidates) {
      final Map<String, Object?>? record = theirs.records[id];
      if (record == null) {
        continue;
      }
      final String? template = templateMapping[record['template_id']];
      if (template == null) {
        continue;
      }
      final List<String> identity = mine.identityFields(template);
      for (final Map<String, Object?> other
          in byTemplate[template] ?? const <Map<String, Object?>>[]) {
        final String otherId = other['id']! as String;
        final PossibleDuplicate? pair =
            _identity(theirs, id, mine, otherId, identity) ??
            _photo(theirs, id, mine, otherId) ??
            _caption(theirs, record, mine, other);
        if (pair != null) {
          pairs.add(pair);
        }
      }
    }
    pairs.sort((PossibleDuplicate a, PossibleDuplicate b) {
      final int bySignal = a.signal.index.compareTo(b.signal.index);
      return bySignal != 0 ? bySignal : b.score.compareTo(a.score);
    });
    return pairs;
  }

  static PossibleDuplicate? _identity(
    _Side theirs,
    String id,
    _Side mine,
    String otherId,
    List<String> fields,
  ) {
    var shared = 0;
    for (final String field in fields) {
      final String a = theirs.value(id, field);
      final String b = mine.value(otherId, field);
      if (a.isEmpty || b.isEmpty) {
        continue;
      }
      if (foldSearchText(a) != foldSearchText(b)) {
        return null;
      }
      shared += 1;
    }
    if (shared == 0) {
      return null;
    }
    return PossibleDuplicate(
      incomingId: id,
      localId: otherId,
      signal: DuplicateSignal.identity,
      score: 1,
    );
  }

  static PossibleDuplicate? _photo(
    _Side theirs,
    String id,
    _Side mine,
    String otherId,
  ) {
    final Set<String> here = mine.photoHashes(otherId);
    if (here.isEmpty || !theirs.photoHashes(id).any(here.contains)) {
      return null;
    }
    return PossibleDuplicate(
      incomingId: id,
      localId: otherId,
      signal: DuplicateSignal.photo,
      score: 1,
    );
  }

  static PossibleDuplicate? _caption(
    _Side theirs,
    Map<String, Object?> record,
    _Side mine,
    Map<String, Object?> other,
  ) {
    if (!_sameContext(record['context_json'], other['context_json'])) {
      return null;
    }
    final Object? at = record['captured_at'];
    final Object? otherAt = other['captured_at'];
    if (at is! int ||
        otherAt is! int ||
        (at - otherAt).abs() > AppConstants.merge.duplicateWindow.inSeconds) {
      return null;
    }
    final String caption = theirs.caption(record['id']! as String);
    final String otherCaption = mine.caption(other['id']! as String);
    if (caption.isEmpty || otherCaption.isEmpty) {
      return null;
    }
    final double score = FuzzyMatcher.similarity(caption, otherCaption);
    if (score < AppConstants.merge.duplicateCaptionSimilarity) {
      return null;
    }
    return PossibleDuplicate(
      incomingId: record['id']! as String,
      localId: other['id']! as String,
      signal: DuplicateSignal.caption,
      score: score,
    );
  }

  static bool _sameContext(Object? left, Object? right) {
    final Map<String, String> a = _context(left);
    final Map<String, String> b = _context(right);
    if (a.length != b.length) {
      return false;
    }
    for (final MapEntry<String, String> entry in a.entries) {
      if (b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  static Map<String, String> _context(Object? json) {
    if (json is! String || json.isEmpty) {
      return const <String, String>{};
    }
    try {
      final Object? decoded = jsonDecode(json);
      if (decoded is! Map) {
        return const <String, String>{};
      }
      return <String, String>{
        for (final MapEntry<Object?, Object?> entry in decoded.entries)
          if (entry.value != null && '${entry.value}'.trim().isNotEmpty)
            '${entry.key}': foldSearchText('${entry.value}'.trim()),
      };
    } on FormatException {
      return const <String, String>{};
    }
  }
}

/// One side's rows, indexed once.
final class _Side {
  _Side(Map<String, List<Map<String, Object?>>> tables)
    : records = <String, Map<String, Object?>>{
        for (final Map<String, Object?> row in _rows(tables, 'records'))
          row['id']! as String: row,
      },
      _deleted = <String>{
        for (final Map<String, Object?> tomb in _rows(tables, 'tombstones'))
          '${tomb['entity_type']}/${tomb['entity_id']}',
      },
      _templates = <String, Map<String, Object?>>{
        for (final Map<String, Object?> row in _rows(tables, 'templates'))
          row['id']! as String: row,
      },
      _values = <String, String>{
        for (final Map<String, Object?> row in _rows(tables, 'record_fields'))
          '${row['record_id']}/${row['field_key']}': _effective(row),
      },
      _captions = <String, String>{
        for (final Map<String, Object?> row in _rows(tables, 'captions'))
          if (row['owner_type'] == 'record')
            row['owner_id']! as String: _captionText(row),
      },
      _photos = <String, Set<String>>{} {
    for (final Map<String, Object?> photo in _rows(tables, 'photos')) {
      final Object? record = photo['record_id'];
      if (record is String && !_deleted.contains('photos/${photo['id']}')) {
        _photos
            .putIfAbsent(record, () => <String>{})
            .add(photo['sha256']! as String);
      }
    }
  }

  final Map<String, Map<String, Object?>> records;
  final Set<String> _deleted;
  final Map<String, Map<String, Object?>> _templates;
  final Map<String, String> _values;
  final Map<String, String> _captions;
  final Map<String, Set<String>> _photos;

  /// Records not deleted on this side.
  Iterable<Map<String, Object?>> get live => records.values.where(
    (Map<String, Object?> record) =>
        !_deleted.contains('records/${record['id']}'),
  );

  String value(String recordId, String fieldKey) =>
      _values['$recordId/$fieldKey'] ?? '';

  String caption(String recordId) => _captions[recordId] ?? '';

  Set<String> photoHashes(String recordId) =>
      _photos[recordId] ?? const <String>{};

  /// The field keys [templateId] names as a record's identity.
  List<String> identityFields(String templateId) {
    final Object? json = _templates[templateId]?['identity_fields'];
    if (json is! String || json.isEmpty) {
      return const <String>[];
    }
    try {
      final Object? decoded = jsonDecode(json);
      return decoded is List
          ? <String>[for (final Object? key in decoded) ?key?.toString()]
          : const <String>[];
    } on FormatException {
      return const <String>[];
    }
  }
}

List<Map<String, Object?>> _rows(
  Map<String, List<Map<String, Object?>>> tables,
  String table,
) => tables[table] ?? const <Map<String, Object?>>[];

String _effective(Map<String, Object?> row) {
  for (final String column in const <String>[
    'value_final',
    'value_refined',
    'value_raw',
  ]) {
    final Object? value = row[column];
    if (value != null) {
      return '$value'.trim();
    }
  }
  return '';
}

String _captionText(Map<String, Object?> row) {
  final Object? refined = row['text_refined'];
  if (refined is String && refined.trim().isNotEmpty) {
    return refined.trim();
  }
  return '${row['text_raw'] ?? ''}'.trim();
}

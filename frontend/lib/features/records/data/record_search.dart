import 'package:drift/drift.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/record_schema.dart';
import 'package:tapture/core/normalise/search_text.dart';

/// The text typed into a records list's search field, as the SQL that
/// narrows the list to the records whose search document holds every word
/// (task 014 step 3, D5, FE-PERF-01).
///
/// The words come from [searchWords], so the search folds case and accents
/// and skips connectives exactly as every other search in the app does.
/// Each word is double-quoted (inner quotes doubled) and suffixed with `*`,
/// and the words are joined by spaces, which FTS5 reads as AND. The index
/// uses the trigram tokenizer, which cannot match fewer than three
/// characters, so shorter words are dropped; when no word is left the
/// search narrows nothing ([narrows] is false).
///
/// The index is only ever reached through an `IN` subquery on the FTS
/// table, never a join: a join lets SQLite run the MATCH once per document,
/// seconds at ten thousand records, while the subquery runs it once
/// (milliseconds). The FTS tables are unknown to drift, so a watched query
/// using this declares `readsFrom` on the source tables (see
/// [RecordSchema]).
final class RecordSearch {
  /// The search for [text], as typed.
  factory RecordSearch(String text) {
    return RecordSearch._(<String>[
      for (final String word in searchWords(text))
        if (word.runes.length >= AppConstants.search.minWordLength) word,
    ]);
  }

  const RecordSearch._(this.words);

  /// A search that narrows nothing.
  static const RecordSearch none = RecordSearch._(<String>[]);

  /// The folded words every matching record holds, in the order typed.
  final List<String> words;

  /// Whether the search narrows the list at all.
  bool get narrows => words.isNotEmpty;

  /// The FTS5 MATCH expression: `"word"*` per word, AND-ed by spaces.
  /// Empty when the search does not narrow.
  String get match => words.map(_quoted).join(' ');

  /// The SQL condition keeping rows whose record id, held in
  /// [recordIdColumn] (for example `r.id`), has a matching document. Binds
  /// [variables]. For lists ordered by number or capture date.
  String recordCondition(String recordIdColumn) {
    return '$recordIdColumn IN (SELECT found.record_id FROM '
        '${RecordSchema.searchDocsTable} found '
        'WHERE ${docCondition('found.doc')})';
  }

  /// The SQL condition keeping [RecordSchema.searchDocsTable] rows whose
  /// document id, held in [docColumn] (for example `sd.doc`), matches. Binds
  /// [variables]. For lists ordered by name, which read the documents
  /// table in its name order.
  String docCondition(String docColumn) {
    return '$docColumn IN (SELECT rowid FROM ${RecordSchema.searchTable} '
        'WHERE ${RecordSchema.searchTable} MATCH ?)';
  }

  /// The one argument [recordCondition] and [docCondition] bind: [match].
  List<Variable<Object>> get variables => <Variable<Object>>[
    Variable<String>(match),
  ];

  @override
  int get hashCode => Object.hashAll(words);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! RecordSearch || other.words.length != words.length) {
      return false;
    }
    for (int index = 0; index < words.length; index++) {
      if (other.words[index] != words[index]) {
        return false;
      }
    }
    return true;
  }

  /// Counts only: search text never reaches a log (FE-CODE-08).
  @override
  String toString() => 'RecordSearch(${words.length} words)';
}

String _quoted(String word) => '"${word.replaceAll('"', '""')}"*';

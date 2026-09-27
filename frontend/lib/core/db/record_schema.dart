import 'package:drift/drift.dart';
import 'package:tapture/core/errors/failure.dart';

/// The record schema drift's `createAll` does not build: the indexes the
/// records list and its triggers read through, status normalisation, the
/// per-project record number and the device-local search index (task 014).
///
/// [ensure] runs from `onCreate` and from the version 21 upgrade step, so a
/// fresh database and an upgraded one end with the same `sqlite_master`.
///
/// Search is one FTS5 document per record, rebuilt by triggers in the same
/// transaction as every write that changes what the record says: its field
/// values, its own and its photos' captions, its transcripts and the OCR
/// text of its photos. A record whose status is `deleted` keeps its document
/// so a restore finds it again; lists exclude deleted records by status. The
/// index is never exported: bundles select their tables by name.
///
/// Build the MATCH text from each search word double-quoted (inner quotes
/// doubled) and suffixed with `*`, joined by spaces (AND), dropping words
/// shorter than three characters, which the trigram tokenizer cannot match.
/// Filter with an `IN` subquery on the FTS table rather than joining it:
/// a join lets SQLite run the MATCH once per document and takes seconds at
/// ten thousand records, the subquery runs it once and takes milliseconds.
///
/// ```sql
/// SELECT r.* FROM records r
/// JOIN record_search_docs d ON d.record_id = r.id
/// WHERE d.project_id = ?1
///   AND d.doc IN (SELECT rowid FROM record_search
///                 WHERE record_search MATCH ?2)   -- '"pump"* "serial"*'
/// ORDER BY d.sort_name, d.record_id
/// LIMIT ?3 OFFSET ?4;
/// ```
///
/// Sorting by number or capture date filters the same way, as
/// `r.project_id = ?1 AND r.id IN (SELECT d.record_id FROM record_search_docs
/// d WHERE d.doc IN (SELECT rowid FROM record_search WHERE record_search
/// MATCH ?2)) ORDER BY r.record_number DESC, r.id DESC`. Drift does not know
/// these tables, so a watched query declares `readsFrom` on the sources:
/// `db.records`, `db.recordFields`, `db.captions`, `db.photos`,
/// `db.tombstones`, `db.ocrCacheEntries`, `db.processing`,
/// `db.processingResults` and `db.meetings`.
abstract final class RecordSchema {
  /// Every stored record status, spelled as `RecordStatus.name` and in the
  /// enum's order. Legacy spellings (`NEEDS_REVIEW`, `needs_review`) are
  /// rewritten to these by the migration and by triggers.
  static const List<String> statusNames = <String>[
    'draft',
    'captured',
    'queued',
    'processing',
    'extracted',
    'needsReview',
    'approved',
    'failed',
    'archived',
    'deleted',
  ];

  /// One row per record: the FTS document id, the project and the two sort
  /// keys. `doc` is the `rowid` of the record's [searchTable] row.
  static const String searchDocsTable = 'record_search_docs';

  /// The FTS5 table, one column `body`, `rowid` = [searchDocsTable]`.doc`.
  static const String searchTable = 'record_search';

  /// The view every trigger rebuilds a document from: `record_id`,
  /// `project_id`, `body`, `sort_name` and `identifier` per record.
  static const String searchSourceView = 'record_search_source';

  /// Index serving `WHERE project_id = ? ORDER BY sort_name, record_id` on
  /// [searchDocsTable].
  static const String searchDocsByName = 'record_search_docs_by_project_name';

  /// Holds one row while [deferIndexing] runs; the triggers then note the
  /// record in [searchPendingTable] instead of rebuilding its document.
  static const String searchHoldTable = 'record_search_hold';

  /// Records whose documents [deferIndexing] rebuilds before it returns.
  static const String searchPendingTable = 'record_search_pending';

  /// Tokenizers tried in order when the search table is created. Trigram
  /// keeps today's substring matching; `remove_diacritics` needs SQLite 3.45
  /// and trigram needs 3.34. The last is a fallback for an older library,
  /// where a quoted word followed by `*` becomes a prefix match.
  static const List<String> tokenizers = <String>[
    'trigram remove_diacritics 1',
    'trigram',
    'unicode61 remove_diacritics 2',
  ];

  /// Indexes created by [ensure], by name.
  static const List<String> indexNames = <String>[
    'records_by_project_number',
    'photos_by_record',
    'photos_by_sha256',
    'processing_jobs_by_record',
    'processing_results_by_job',
    'field_evidence_by_photo',
    'tombstones_by_type_deleted',
    'meetings_by_record',
    searchDocsByName,
  ];

  /// Triggers created by [ensure], by name.
  static const List<String> triggerNames = <String>[
    'records_number_ai',
    'records_status_ai',
    'records_status_au',
    'records_search_ai',
    'records_search_au',
    'records_search_ad',
    'record_fields_search_ai',
    'record_fields_search_au',
    'record_fields_search_ad',
    'captions_search_ai',
    'captions_search_au',
    'captions_search_ad',
    'photos_search_ai',
    'photos_search_au',
    'photos_search_ad',
    'ocr_cache_search_ai',
    'ocr_cache_search_au',
    'ocr_cache_search_ad',
    'processing_results_search_ai',
    'processing_results_search_au',
    'processing_results_search_ad',
    'processing_jobs_search_ai',
    'processing_jobs_search_au',
    'processing_jobs_search_ad',
    'meetings_search_ai',
    'meetings_search_au',
    'meetings_search_ad',
    'tombstones_search_ai',
    'tombstones_search_au',
    'tombstones_search_ad',
  ];

  /// Tables [ensure] reads or writes. A partial schema (a test fixture that
  /// holds only some tables) gets nothing.
  static const List<String> requiredTables = <String>[
    'records',
    'record_fields',
    'photos',
    'captions',
    'tombstones',
    'processing_jobs',
    'processing_results',
    'ocr_cache',
    'meetings',
    'field_evidence',
    'templates',
    'template_fields',
    'template_rows',
  ];

  /// Creates or refreshes everything above inside the caller's migration,
  /// then normalises stored statuses, numbers unnumbered records per project
  /// in capture order and rebuilds every search document.
  ///
  /// Tables and indexes use `IF NOT EXISTS`; the view and the triggers are
  /// dropped and created again, so a second run leaves the same schema and
  /// the same rows.
  static Future<void> ensure(GeneratedDatabase db) async {
    final List<QueryRow> tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    final Set<String> present = <String>{
      for (final QueryRow row in tables) row.read<String>('name'),
    };
    if (!requiredTables.every(present.contains)) {
      return;
    }
    for (final String statement in _indexes) {
      await db.customStatement(statement);
    }
    await db.customStatement(
      'UPDATE records SET status = ${_canonical('status')} '
      'WHERE ${_needsCanonical('status')}',
    );
    await db.customStatement(_numberBackfill);
    await db.customStatement(_docsTable);
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS $searchDocsByName ON $searchDocsTable '
      '(project_id, sort_name, record_id)',
    );
    await db.customStatement(
      'CREATE TABLE IF NOT EXISTS $searchHoldTable (held INTEGER NOT NULL)',
    );
    await db.customStatement(
      'CREATE TABLE IF NOT EXISTS $searchPendingTable '
      '(record_id TEXT NOT NULL PRIMARY KEY)',
    );
    await db.customStatement('DELETE FROM $searchHoldTable');
    await db.customStatement('DELETE FROM $searchPendingTable');
    await _createSearchTable(db);
    await _createSourceView(db);
    for (final String name in triggerNames) {
      await db.customStatement('DROP TRIGGER IF EXISTS $name');
    }
    for (final String statement in _triggers) {
      await db.customStatement(statement);
    }
    for (final String statement in _rebuildAll) {
      await db.customStatement(statement);
    }
  }

  /// Runs [body] in one transaction (joining the caller's) with document
  /// rebuilds deferred to its end, for bulk writers such as a merge import
  /// or a seeded test database.
  ///
  /// While [body] runs, the search triggers only note which records changed;
  /// before the transaction commits each noted document is rebuilt once, so
  /// the index still changes in the same transaction as the writes. A throw
  /// rolls back the writes and the hold together. A nested call joins the
  /// outer one and leaves the rebuild to it.
  static Future<T> deferIndexing<T>(
    GeneratedDatabase db,
    Future<T> Function() body,
  ) {
    return db.transaction(() async {
      final QueryRow? held = await db
          .customSelect('SELECT 1 AS held FROM $searchHoldTable LIMIT 1')
          .getSingleOrNull();
      if (held != null) {
        return body();
      }
      await db.customStatement(
        'INSERT INTO $searchHoldTable (held) VALUES (1)',
      );
      final T value = await body();
      await db.customStatement('DELETE FROM $searchHoldTable');
      for (final String statement in _rebuildStatements(
        'SELECT record_id FROM $searchPendingTable',
      )) {
        await db.customStatement(statement);
      }
      await db.customStatement('DELETE FROM $searchPendingTable');
      return value;
    });
  }

  /// SQL expression: the canonical spelling of the status held by [column].
  ///
  /// Case and `_` are folded, so `NEEDS_REVIEW`, `needs_review` and
  /// `needsReview` all read `needsReview`; an unknown value is returned as
  /// stored.
  static String canonicalExpression(String column) => _canonical(column);

  static Future<void> _createSearchTable(GeneratedDatabase db) async {
    for (final String tokenizer in tokenizers) {
      try {
        await db.customStatement(
          'CREATE VIRTUAL TABLE IF NOT EXISTS $searchTable '
          "USING fts5(body, tokenize = '$tokenizer')",
        );
        return;
      } on Object {
        continue;
      }
    }
    throw const StorageFailure(
      message: 'This device cannot build the record search index.',
      recoveryAction: 'Update the app, then open it again.',
    );
  }

  static String _folded(String column) => "lower(replace($column, '_', ''))";

  static String get _statusList =>
      statusNames.map((String name) => "'$name'").join(', ');

  static String get _foldedList =>
      statusNames.map((String name) => "'${name.toLowerCase()}'").join(', ');

  static String _canonical(String column) {
    final String cases = statusNames
        .map((String name) => "WHEN '${name.toLowerCase()}' THEN '$name'")
        .join(' ');
    return 'CASE ${_folded(column)} $cases ELSE $column END';
  }

  static String _needsCanonical(String column) =>
      '$column NOT IN ($_statusList) AND ${_folded(column)} IN ($_foldedList)';

  static const List<String> _indexes = <String>[
    'CREATE INDEX IF NOT EXISTS records_by_project_number ON records '
        '(project_id, record_number, id)',
    'CREATE INDEX IF NOT EXISTS photos_by_record ON photos (record_id)',
    'CREATE INDEX IF NOT EXISTS photos_by_sha256 ON photos (sha256)',
    'CREATE INDEX IF NOT EXISTS processing_jobs_by_record ON processing_jobs '
        '(record_id)',
    'CREATE INDEX IF NOT EXISTS processing_results_by_job ON '
        'processing_results (job_id)',
    'CREATE INDEX IF NOT EXISTS field_evidence_by_photo ON field_evidence '
        '(photo_id)',
    'CREATE INDEX IF NOT EXISTS tombstones_by_type_deleted ON tombstones '
        '(entity_type, deleted_at)',
    'CREATE INDEX IF NOT EXISTS meetings_by_record ON meetings (record_id)',
  ];

  /// Numbers every unnumbered record after the highest number its project
  /// already holds, in `captured_at, id` order. The numbered set is computed
  /// before any row changes.
  static const String _numberBackfill =
      'UPDATE records SET record_number = numbered.n FROM ('
      'SELECT r.id AS id, '
      '(SELECT COALESCE(MAX(x.record_number), 0) FROM records x '
      'WHERE x.project_id = r.project_id) + '
      'ROW_NUMBER() OVER (PARTITION BY r.project_id '
      'ORDER BY r.captured_at, r.id) AS n '
      'FROM records r WHERE r.record_number IS NULL'
      ') AS numbered WHERE records.id = numbered.id';

  static const String _docsTable =
      'CREATE TABLE IF NOT EXISTS $searchDocsTable ('
      'doc INTEGER PRIMARY KEY, '
      'record_id TEXT NOT NULL UNIQUE, '
      'project_id TEXT NOT NULL, '
      "sort_name TEXT NOT NULL DEFAULT '' COLLATE NOCASE, "
      "identifier TEXT NOT NULL DEFAULT '')";

  static String _live(String type, String id, String alias) =>
      'NOT EXISTS (SELECT 1 FROM tombstones $alias '
      "WHERE $alias.entity_type = '$type' AND $alias.entity_id = $id)";

  static String _display(String f) =>
      "COALESCE(NULLIF(trim($f.value_final), ''), "
      "NULLIF(trim($f.value_refined), ''), NULLIF(trim($f.value_raw), ''))";

  static String _json(String column, String path) =>
      "(CASE WHEN json_valid($column) THEN json_extract($column, '$path') END)";

  static const String _identityKeys =
      'FROM templates it, json_each(CASE WHEN json_valid(it.identity_fields) '
      "THEN it.identity_fields ELSE '[]' END) ij "
      'WHERE it.id = r.template_id AND ij.value = f.field_key';

  /// True for a value (alias `f`, template field `tf`) that identifies the
  /// record: listed in the template's `identity_fields`, or flagged identity
  /// on the field.
  static String get _isIdentity =>
      '(EXISTS (SELECT 1 $_identityKeys) '
      "OR ${_json('tf.validation', r'$._tapture.identity')} IS 1)";

  /// True for a template field (alias `tf`) a person sees and fills: not
  /// hidden, not automatic, not bound to a context level, and not a photo,
  /// document, signature, location or yes/no field. A value with no template
  /// field passes.
  static String get _isNameField =>
      '(tf.id IS NULL OR ('
      "${_json('tf.validation', r'$._tapture.hidden')} IS NOT 1 "
      "AND upper(tf.input_mode) <> 'AUTO' "
      'AND tf.auto_fill = 0 '
      'AND tf.context_level IS NULL '
      "AND lower(replace(replace(tf.type, '_', ''), ' ', '')) NOT IN "
      "('photoreference', 'documentreference', 'signature', 'gpslocation', "
      "'boolean')))";

  static const String _fieldJoin =
      'FROM record_fields f LEFT JOIN template_fields tf '
      'ON tf.template_id = r.template_id AND tf.field_key = f.field_key';

  static String get _liveValue =>
      'f.record_id = r.id AND f.retired_at IS NULL AND '
      "${_live('record_fields', 'f.id', 'xf')} AND ${_display('f')} IS NOT NULL";

  /// Name: the displayed value of the first name field by template order that
  /// is not an identity field and was not copied from context or a default,
  /// else the record's latest caption, else empty.
  static String get _sortName =>
      'COALESCE('
      '(SELECT ${_display('f')} $_fieldJoin '
      'WHERE $_liveValue '
      "AND lower(f.source) NOT IN ('context', 'default') "
      'AND NOT $_isIdentity AND $_isNameField '
      'ORDER BY tf.id IS NULL, tf.sort_order, tf.label, f.field_key LIMIT 1), '
      '(SELECT substr(replace(replace(trim(COALESCE(c.text_refined, '
      "c.text_raw)), char(13), ' '), char(10), ' '), 1, 120) FROM captions c "
      "WHERE c.owner_type = 'record' AND c.owner_id = r.id "
      "AND ${_live('captions', 'c.id', 'xc')} "
      "AND trim(COALESCE(c.text_refined, c.text_raw)) <> '' "
      'ORDER BY c.created_at DESC, c.id DESC LIMIT 1), '
      "'')";

  /// Identifier: the identity values joined by a space, in the template's
  /// `identity_fields` order then field order, else the checklist row's
  /// identifier, else empty.
  ///
  /// SQLite has no correlated subquery in a FROM clause, so the order comes
  /// from an ordered aggregate (SQLite 3.44). [ordered] false drops the
  /// ordering for an older library, which then joins in scan order.
  static String _identifier({required bool ordered}) {
    final String order = ordered
        ? ' ORDER BY COALESCE((SELECT CAST(ij.key AS INTEGER) $_identityKeys '
              'LIMIT 1), 1000000 + COALESCE(tf.sort_order, 0)), f.field_key'
        : '';
    return 'COALESCE('
        "(SELECT group_concat(${_display('f')}, ' '$order) $_fieldJoin "
        'WHERE $_liveValue AND $_isIdentity), '
        "(SELECT NULLIF(trim(tr.identifier), '') FROM template_rows tr "
        'WHERE tr.id = r.template_row_id), '
        "'')";
  }

  /// Body: every live value (raw, then refined and approved where they
  /// differ), the record's and its live photos' captions, stored transcripts
  /// (processing results of kind `transcript`, meeting transcripts and
  /// minutes), the OCR text of its live photos, and its checklist row. Each
  /// source is one correlated aggregate, one line per text.
  static String get _body {
    final String field =
        'FROM record_fields f WHERE f.record_id = r.id '
        "AND ${_live('record_fields', 'f.id', 'xf')}";
    final String photo =
        "p.record_id = r.id AND ${_live('photos', 'p.id', 'xp')}";
    final List<String> sources = <String>[
      'SELECT group_concat(f.value_raw, char(10)) $field',
      'SELECT group_concat(f.value_refined, char(10)) $field '
          'AND f.value_refined IS NOT f.value_raw',
      'SELECT group_concat(f.value_final, char(10)) $field '
          'AND f.value_final IS NOT f.value_refined '
          'AND f.value_final IS NOT f.value_raw',
      'SELECT group_concat(COALESCE(c.text_refined, c.text_raw), char(10)) '
          "FROM captions c WHERE c.owner_type = 'record' "
          "AND c.owner_id = r.id AND ${_live('captions', 'c.id', 'xc')}",
      'SELECT group_concat(COALESCE(c.text_refined, c.text_raw), char(10)) '
          "FROM photos p JOIN captions c ON c.owner_type = 'photo' "
          "AND c.owner_id = p.id WHERE $photo "
          "AND ${_live('captions', 'c.id', 'xc')}",
      'SELECT group_concat(o.recognised_text, char(10)) FROM photos p '
          'JOIN ocr_cache o ON o.content_hash = p.sha256 WHERE $photo',
      'SELECT group_concat(pr.raw_response, char(10)) FROM processing_jobs j '
          'JOIN processing_results pr ON pr.job_id = j.id '
          'WHERE j.record_id = r.id AND pr.parsed_ok = 1 '
          "AND ${_isTranscript('pr')}",
      "SELECT group_concat(m.transcript_raw || char(10) || "
          "COALESCE(m.minutes_refined, ''), char(10)) FROM meetings m "
          "WHERE m.record_id = r.id AND ${_live('meetings', 'm.id', 'xm')}",
      'SELECT tr.identifier || char(10) || tr.label FROM template_rows tr '
          'WHERE tr.id = r.template_row_id',
    ];
    return sources
        .map((String source) => "COALESCE(($source), '')")
        .join(' || char(10) || ');
  }

  static String _sourceView({required bool ordered}) =>
      'CREATE VIEW $searchSourceView AS SELECT '
      'r.id AS record_id, r.project_id AS project_id, '
      '$_body AS body, $_sortName AS sort_name, '
      '${_identifier(ordered: ordered)} AS identifier '
      'FROM records r';

  static Future<void> _createSourceView(GeneratedDatabase db) async {
    await db.customStatement('DROP VIEW IF EXISTS $searchSourceView');
    try {
      await db.customStatement(_sourceView(ordered: true));
    } on Object {
      await db.customStatement(_sourceView(ordered: false));
    }
  }

  /// Statements that rebuild the documents of every record id [ids] (a
  /// SELECT) returns. Ids with no record row are skipped. [unlessHeld] adds
  /// the [deferIndexing] guard the trigger bodies carry.
  static List<String> _rebuildStatements(
    String ids, {
    bool unlessHeld = false,
  }) {
    final String free = unlessHeld
        ? ' AND NOT EXISTS (SELECT 1 FROM $searchHoldTable)'
        : '';
    return <String>[
      'INSERT OR IGNORE INTO $searchDocsTable (record_id, project_id) '
          'SELECT id, project_id FROM records WHERE id IN ($ids)$free',
      'UPDATE $searchDocsTable SET (project_id, sort_name, identifier) = '
          '(SELECT s.project_id, s.sort_name, s.identifier '
          'FROM $searchSourceView s '
          'WHERE s.record_id = $searchDocsTable.record_id) '
          'WHERE record_id IN ($ids) AND EXISTS (SELECT 1 FROM records x '
          'WHERE x.id = $searchDocsTable.record_id)$free',
      'DELETE FROM $searchTable WHERE rowid IN (SELECT doc '
          'FROM $searchDocsTable WHERE record_id IN ($ids))$free',
      'INSERT INTO $searchTable (rowid, body) SELECT d.doc, s.body '
          'FROM $searchDocsTable d JOIN $searchSourceView s '
          'ON s.record_id = d.record_id WHERE d.record_id IN ($ids)$free',
    ];
  }

  /// A trigger body that rebuilds the documents of [ids], or only notes them
  /// in [searchPendingTable] while [deferIndexing] holds the index.
  static String _rebuild(String ids) {
    return <String>[
      'INSERT OR IGNORE INTO $searchPendingTable (record_id) '
          'SELECT id FROM records WHERE id IN ($ids) '
          'AND EXISTS (SELECT 1 FROM $searchHoldTable)',
      ..._rebuildStatements(ids, unlessHeld: true),
    ].map((String statement) => '$statement;').join(' ');
  }

  static String _trigger(String name, String event, String when, String body) =>
      'CREATE TRIGGER $name AFTER $event'
      '${when.isEmpty ? '' : ' WHEN $when'} BEGIN $body END';

  static String _captionOwner(String row) =>
      "SELECT $row.owner_id WHERE $row.owner_type = 'record' "
      'UNION SELECT p.record_id FROM photos p '
      "WHERE $row.owner_type = 'photo' AND p.id = $row.owner_id";

  static String _ocrOwners(String row) =>
      'SELECT p.record_id FROM photos p WHERE p.sha256 = $row.content_hash';

  static String _jobOwner(String row) =>
      'SELECT j.record_id FROM processing_jobs j WHERE j.id = $row.job_id';

  static String _isTranscript(String row) =>
      "${_json('$row.request_summary', r'$.kind')} = 'transcript'";

  static const String _searchedTombstones =
      "('record_fields', 'photos', 'captions', 'meetings')";

  static String _tombstoneOwners(String row) =>
      'SELECT f.record_id FROM record_fields f '
      "WHERE $row.entity_type = 'record_fields' AND f.id = $row.entity_id "
      'UNION SELECT p.record_id FROM photos p '
      "WHERE $row.entity_type = 'photos' AND p.id = $row.entity_id "
      'UNION SELECT c.owner_id FROM captions c '
      "WHERE $row.entity_type = 'captions' AND c.id = $row.entity_id "
      "AND c.owner_type = 'record' "
      'UNION SELECT p.record_id FROM captions c JOIN photos p '
      "ON p.id = c.owner_id WHERE $row.entity_type = 'captions' "
      "AND c.id = $row.entity_id AND c.owner_type = 'photo' "
      'UNION SELECT m.record_id FROM meetings m '
      "WHERE $row.entity_type = 'meetings' AND m.id = $row.entity_id";

  static List<String> get _triggers => <String>[
    _trigger(
      'records_number_ai',
      'INSERT ON records',
      'NEW.record_number IS NULL',
      'UPDATE records SET record_number = (SELECT COALESCE(MAX(n.record_number), '
          '0) + 1 FROM records n WHERE n.project_id = NEW.project_id) '
          'WHERE rowid = NEW.rowid;',
    ),
    _trigger(
      'records_status_ai',
      'INSERT ON records',
      _needsCanonical('NEW.status'),
      'UPDATE records SET status = ${_canonical('NEW.status')} '
          'WHERE rowid = NEW.rowid;',
    ),
    _trigger(
      'records_status_au',
      'UPDATE OF status ON records',
      _needsCanonical('NEW.status'),
      'UPDATE records SET status = ${_canonical('NEW.status')} '
          'WHERE rowid = NEW.rowid;',
    ),
    _trigger('records_search_ai', 'INSERT ON records', '', _rebuild('NEW.id')),
    _trigger(
      'records_search_au',
      'UPDATE OF id, project_id, template_id, template_row_id ON records',
      '',
      '${_rebuild('NEW.id')} '
          'DELETE FROM $searchTable WHERE OLD.id IS NOT NEW.id AND rowid IN '
          '(SELECT doc FROM $searchDocsTable WHERE record_id = OLD.id); '
          'DELETE FROM $searchDocsTable WHERE OLD.id IS NOT NEW.id '
          'AND record_id = OLD.id;',
    ),
    _trigger(
      'records_search_ad',
      'DELETE ON records',
      '',
      'DELETE FROM $searchTable WHERE rowid IN (SELECT doc FROM '
          '$searchDocsTable WHERE record_id = OLD.id); '
          'DELETE FROM $searchDocsTable WHERE record_id = OLD.id;',
    ),
    _trigger(
      'record_fields_search_ai',
      'INSERT ON record_fields',
      '',
      _rebuild('SELECT NEW.record_id'),
    ),
    _trigger(
      'record_fields_search_au',
      'UPDATE OF id, record_id, field_key, value_raw, value_refined, '
          'value_final, source, retired_at ON record_fields',
      '',
      _rebuild('SELECT NEW.record_id UNION SELECT OLD.record_id'),
    ),
    _trigger(
      'record_fields_search_ad',
      'DELETE ON record_fields',
      '',
      _rebuild('SELECT OLD.record_id'),
    ),
    _trigger(
      'captions_search_ai',
      'INSERT ON captions',
      '',
      _rebuild(_captionOwner('NEW')),
    ),
    _trigger(
      'captions_search_au',
      'UPDATE OF id, owner_type, owner_id, text_raw, text_refined ON captions',
      '',
      _rebuild('${_captionOwner('NEW')} UNION ${_captionOwner('OLD')}'),
    ),
    _trigger(
      'captions_search_ad',
      'DELETE ON captions',
      '',
      _rebuild(_captionOwner('OLD')),
    ),
    _trigger(
      'photos_search_ai',
      'INSERT ON photos',
      'NEW.record_id IS NOT NULL',
      _rebuild('SELECT NEW.record_id'),
    ),
    _trigger(
      'photos_search_au',
      'UPDATE OF id, record_id, sha256 ON photos',
      'NEW.record_id IS NOT NULL OR OLD.record_id IS NOT NULL',
      _rebuild('SELECT NEW.record_id UNION SELECT OLD.record_id'),
    ),
    _trigger(
      'photos_search_ad',
      'DELETE ON photos',
      'OLD.record_id IS NOT NULL',
      _rebuild('SELECT OLD.record_id'),
    ),
    _trigger(
      'ocr_cache_search_ai',
      'INSERT ON ocr_cache',
      '',
      _rebuild(_ocrOwners('NEW')),
    ),
    _trigger(
      'ocr_cache_search_au',
      'UPDATE OF content_hash, recognised_text ON ocr_cache',
      '',
      _rebuild('${_ocrOwners('NEW')} UNION ${_ocrOwners('OLD')}'),
    ),
    _trigger(
      'ocr_cache_search_ad',
      'DELETE ON ocr_cache',
      '',
      _rebuild(_ocrOwners('OLD')),
    ),
    _trigger(
      'processing_results_search_ai',
      'INSERT ON processing_results',
      _isTranscript('NEW'),
      _rebuild(_jobOwner('NEW')),
    ),
    _trigger(
      'processing_results_search_au',
      'UPDATE OF job_id, request_summary, raw_response, parsed_ok '
          'ON processing_results',
      '${_isTranscript('NEW')} OR ${_isTranscript('OLD')}',
      _rebuild('${_jobOwner('NEW')} UNION ${_jobOwner('OLD')}'),
    ),
    _trigger(
      'processing_results_search_ad',
      'DELETE ON processing_results',
      _isTranscript('OLD'),
      _rebuild(_jobOwner('OLD')),
    ),
    _trigger(
      'processing_jobs_search_ai',
      'INSERT ON processing_jobs',
      'EXISTS (SELECT 1 FROM processing_results pr WHERE pr.job_id = NEW.id)',
      _rebuild('SELECT NEW.record_id'),
    ),
    _trigger(
      'processing_jobs_search_au',
      'UPDATE OF id, record_id ON processing_jobs',
      '(NEW.id IS NOT OLD.id OR NEW.record_id IS NOT OLD.record_id) AND '
          'EXISTS (SELECT 1 FROM processing_results pr '
          'WHERE pr.job_id IN (NEW.id, OLD.id))',
      _rebuild('SELECT NEW.record_id UNION SELECT OLD.record_id'),
    ),
    _trigger(
      'processing_jobs_search_ad',
      'DELETE ON processing_jobs',
      'EXISTS (SELECT 1 FROM processing_results pr WHERE pr.job_id = OLD.id)',
      _rebuild('SELECT OLD.record_id'),
    ),
    _trigger(
      'meetings_search_ai',
      'INSERT ON meetings',
      '',
      _rebuild('SELECT NEW.record_id'),
    ),
    _trigger(
      'meetings_search_au',
      'UPDATE OF id, record_id, transcript_raw, minutes_refined ON meetings',
      '',
      _rebuild('SELECT NEW.record_id UNION SELECT OLD.record_id'),
    ),
    _trigger(
      'meetings_search_ad',
      'DELETE ON meetings',
      '',
      _rebuild('SELECT OLD.record_id'),
    ),
    _trigger(
      'tombstones_search_ai',
      'INSERT ON tombstones',
      'NEW.entity_type IN $_searchedTombstones',
      _rebuild(_tombstoneOwners('NEW')),
    ),
    _trigger(
      'tombstones_search_au',
      'UPDATE OF entity_type, entity_id ON tombstones',
      '(NEW.entity_type IS NOT OLD.entity_type OR '
          'NEW.entity_id IS NOT OLD.entity_id) AND '
          '(NEW.entity_type IN $_searchedTombstones OR '
          'OLD.entity_type IN $_searchedTombstones)',
      _rebuild('${_tombstoneOwners('NEW')} UNION ${_tombstoneOwners('OLD')}'),
    ),
    _trigger(
      'tombstones_search_ad',
      'DELETE ON tombstones',
      'OLD.entity_type IN $_searchedTombstones',
      _rebuild(_tombstoneOwners('OLD')),
    ),
  ];

  /// Statements that rebuild every document from scratch.
  static const List<String> _rebuildAll = <String>[
    'DELETE FROM $searchDocsTable WHERE record_id NOT IN '
        '(SELECT id FROM records)',
    'INSERT OR IGNORE INTO $searchDocsTable (record_id, project_id) '
        'SELECT id, project_id FROM records',
    'UPDATE $searchDocsTable SET (project_id, sort_name, identifier) = '
        '(SELECT s.project_id, s.sort_name, s.identifier '
        'FROM $searchSourceView s '
        'WHERE s.record_id = $searchDocsTable.record_id)',
    'DELETE FROM $searchTable',
    'INSERT INTO $searchTable (rowid, body) SELECT d.doc, s.body '
        'FROM $searchDocsTable d JOIN $searchSourceView s '
        'ON s.record_id = d.record_id',
  ];
}

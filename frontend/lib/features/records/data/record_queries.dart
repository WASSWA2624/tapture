import 'dart:async';

import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart' show AppDatabase;
import 'package:tapture/core/db/record_schema.dart';
import 'package:tapture/core/db/tables/attachment_owners.dart'
    show AttachmentOwnerType;
import 'package:tapture/core/db/tables/attachments.dart' show AttachmentKind;
import 'package:tapture/core/db/tables/audit_log.dart' show AuditAction;
import 'package:tapture/core/db/tables/captions.dart' show CaptionOwnerType;
import 'package:tapture/core/db/tables/duplicates.dart'
    show DuplicatePairStatus;
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/record_status.dart';

import '../domain/deleted_record.dart';
import '../domain/record_entry.dart';
import '../domain/record_facets.dart';
import '../domain/record_filter.dart';
import '../domain/record_flag.dart';
import '../domain/record_history_event.dart';
import '../domain/record_sort.dart';
import '../domain/record_summary.dart';
import 'record_mapper.dart';
import 'record_search.dart';

/// The read side of the Drift record store (task 014): one record read
/// whole, a filtered, searched, sorted page of a project's records and its
/// count, the filter sheet's choices, a record's history and the recycle
/// bin. `RecordRepositoryImpl` answers every `RecordRepository` read here.
///
/// Everything a list shows is filtered, searched, ordered and paged in SQL,
/// never over a materialised list in Dart (step 2, FE-PERF-03). A page is
/// two steps in one statement: the ids of the page are chosen from the
/// records (and, ordered by name, the search documents) alone, with LIMIT
/// and OFFSET; only those rows then get their name, thumbnail, context label
/// and flags, so a page costs the same at ten thousand records as at ten.
/// Search reaches the FTS index only through the IN subquery
/// [RecordSearch] builds (D5).
///
/// Every watched query declares `readsFrom` on each table it reads, so a
/// write through drift re-emits it. Rows the database writes on its own (the
/// search documents, a normalised status, an allocated number) change in
/// the same transaction as the write that caused them.
final class RecordQueries {
  /// Reads [db]. [localOperator], when given and not blank, names this
  /// device's operator in the operator facet in place of the operator name
  /// stored in the device profile.
  RecordQueries({required this._db, this._localOperator});

  /// The reason a project delete writes on its records' tombstones. Those
  /// records never enter the recycle bin; they come back with the project.
  static const String projectDeletedReason = 'Project deleted';

  final AppDatabase _db;
  final String Function()? _localOperator;

  /// Record [id] read whole, and again after every change to it; null when
  /// it is not on this device. Deleted records are included.
  Stream<RecordEntry?> watchEntry(String id) {
    return _guard(
      _db
          .customSelect(
            _entrySql,
            variables: <Variable<Object>>[Variable<String>(id)],
            readsFrom: _entryTables,
          )
          .watch()
          .asyncMap(
            (List<QueryRow> rows) async =>
                rows.isEmpty ? null : await _entryOf(rows.first),
          ),
    ).distinct();
  }

  /// Record [id] read whole once, in one snapshot; null when it is not on
  /// this device. Deleted records are included.
  Future<Result<RecordEntry?>> byId(String id) {
    return _attempt(() {
      return _db.transaction(() async {
        final List<QueryRow> rows = await _db
            .customSelect(
              _entrySql,
              variables: <Variable<Object>>[Variable<String>(id)],
            )
            .get();
        return rows.isEmpty ? null : _entryOf(rows.first);
      });
    });
  }

  /// [limit] of [projectId]'s records from [offset], matching [filter] and
  /// ordered by [sort] with the record id as a tiebreak in the same
  /// direction. Deleted records are never listed, archived ones only when
  /// [filter] asks, and a record tombstoned with its project not at all.
  Stream<List<RecordSummary>> watchPage(
    String projectId, {
    required RecordFilter filter,
    required RecordSort sort,
    required int offset,
    required int limit,
  }) {
    if (limit <= 0) {
      return Stream<List<RecordSummary>>.value(const <RecordSummary>[]);
    }
    final bool byName = sort.key == RecordSortKey.name;
    final _Criteria where = _Criteria.of(projectId, filter, byName: byName);
    final String direction = sort.ascending ? 'ASC' : 'DESC';
    final String key = switch (sort.key) {
      RecordSortKey.number => 'r.record_number',
      RecordSortKey.capturedAt => 'r.captured_at',
      RecordSortKey.name => 'sd.sort_name',
    };
    final String page = byName
        ? 'SELECT r.id AS page_id, $key AS page_key '
              'FROM ${RecordSchema.searchDocsTable} sd '
              'CROSS JOIN records r ON r.id = sd.record_id '
              'WHERE ${where.sql} '
              'ORDER BY $key $direction, sd.record_id $direction '
              'LIMIT ? OFFSET ?'
        : 'SELECT r.id AS page_id, $key AS page_key FROM records r '
              'WHERE ${where.sql} '
              'ORDER BY $key $direction, r.id $direction '
              'LIMIT ? OFFSET ?';
    final String collate = byName ? ' COLLATE NOCASE' : '';
    return _guard(
      _db
          .customSelect(
            'SELECT $_summaryColumns FROM ($page) pg '
            'JOIN records r ON r.id = pg.page_id $_summaryJoins '
            'ORDER BY pg.page_key$collate $direction, pg.page_id $direction',
            variables: <Variable<Object>>[
              ...where.variables,
              Variable<int>(limit),
              Variable<int>(offset < 0 ? 0 : offset),
            ],
            readsFrom: _listTables,
          )
          .watch()
          .map(
            (List<QueryRow> rows) => <RecordSummary>[
              for (final QueryRow row in rows) RecordMapper.summary(row),
            ],
          ),
    ).distinct(_sameList);
  }

  /// How many of [projectId]'s records [filter] matches, under the rules of
  /// [watchPage].
  Stream<int> watchCount(String projectId, RecordFilter filter) {
    final _Criteria where = _Criteria.of(projectId, filter, byName: false);
    return _guard(
      _db
          .customSelect(
            'SELECT COUNT(*) AS n FROM records r WHERE ${where.sql}',
            variables: where.variables,
            readsFrom: _listTables,
          )
          .watch()
          .map((List<QueryRow> rows) => rows.first.read<int>('n')),
    ).distinct();
  }

  /// The choices [projectId]'s filter sheet offers, read from its records
  /// that are neither deleted nor tombstoned: the templates they use (with
  /// names), the context levels their snapshots set (labelled from the
  /// project's context definitions, in hierarchy order), who captured them
  /// (this device labelled with its operator), the condition values on
  /// their condition fields and the statuses they are in.
  Future<Result<RecordFacets>> facets(String projectId) {
    return _attempt(() => _db.transaction(() => _facets(projectId)));
  }

  /// Record [id]'s history from the local audit table, oldest first: its
  /// own rows plus the rows of its photos and of its own and its photos'
  /// captions, ordered by time then audit id.
  Stream<List<RecordHistoryEvent>> watchHistory(String id) {
    return _guard(
      _db
          .customSelect(
            _historySql,
            variables: <Variable<Object>>[
              Variable<String>(id),
              Variable<String>(id),
              Variable<String>(id),
            ],
            readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
              _db.auditLog,
              _db.photos,
              _db.recordFields,
              _db.templates,
            },
          )
          .watch()
          .map(
            (List<QueryRow> rows) => <RecordHistoryEvent>[
              for (final QueryRow row in rows) RecordMapper.historyEvent(row),
            ],
          ),
    ).distinct(_sameList);
  }

  /// Every record in the recycle bin, across projects, newest deletion
  /// first: status deleted with a records tombstone, except records removed
  /// with their project ([projectDeletedReason], or a project that is
  /// itself tombstoned).
  Stream<List<DeletedRecord>> watchBin() {
    return _guard(
      _db
          .customSelect(
            _binSql,
            variables: <Variable<Object>>[
              Variable<String>(RecordStatus.deleted.stored),
              const Variable<String>(projectDeletedReason),
            ],
            readsFrom: _listTables,
          )
          .watch()
          .map(
            (List<QueryRow> rows) => <DeletedRecord>[
              for (final QueryRow row in rows) RecordMapper.deleted(row),
            ],
          ),
    ).distinct(_sameList);
  }

  // ------------------------------------------------------------------ reads

  Future<RecordEntry> _entryOf(QueryRow record) async {
    final List<Variable<Object>> id = <Variable<Object>>[
      Variable<String>(record.read<String>('id')),
    ];
    final List<QueryRow> values = await _db
        .customSelect(_valuesSql, variables: id)
        .get();
    final List<QueryRow> photos = await _db
        .customSelect(_photosSql, variables: id)
        .get();
    return RecordMapper.entry(record, values: values, photos: photos);
  }

  Future<RecordFacets> _facets(String projectId) async {
    final List<Variable<Object>> project = <Variable<Object>>[
      Variable<String>(projectId),
    ];
    final List<QueryRow> templates = await _db
        .customSelect(
          "SELECT r.template_id AS id, COALESCE(MAX(t.name), '') AS name "
          'FROM records r LEFT JOIN templates t ON t.id = r.template_id '
          'WHERE $_liveInProject GROUP BY r.template_id '
          'ORDER BY name COLLATE NOCASE, id',
          variables: project,
        )
        .get();
    final List<QueryRow> seen = await _db
        .customSelect(
          'SELECT cj.key AS key, cj.value AS value FROM records r, '
          'json_each(${_contextObject('r.context_json')}) cj '
          "WHERE $_liveInProject AND cj.type = 'text' "
          "AND trim(cj.value) <> '' GROUP BY cj.key, cj.value "
          'ORDER BY cj.value COLLATE NOCASE, cj.value',
          variables: project,
        )
        .get();
    final List<QueryRow> levels = await _db
        .customSelect(
          'SELECT cd.field_key AS key, cd.label AS label FROM '
          'context_definitions cd WHERE cd.project_id = ? '
          "AND ${_live('context_definitions', 'cd.id')} "
          'ORDER BY cd.level, cd.field_key',
          variables: project,
        )
        .get();
    final List<QueryRow> operators = await _db
        .customSelect(
          'SELECT r.captured_by AS id, '
          "MAX(COALESCE(dp.operator_name, '')) AS profile_name, "
          'MAX(dp.device_id IS NOT NULL) AS local FROM records r '
          'LEFT JOIN device_profile dp ON dp.device_id = r.captured_by '
          "WHERE $_liveInProject AND trim(r.captured_by) <> '' "
          'GROUP BY r.captured_by',
          variables: project,
        )
        .get();
    final List<QueryRow> conditions = await _db
        .customSelect(
          'SELECT DISTINCT ${_display('f')} AS value FROM record_fields f '
          'JOIN records r ON r.id = f.record_id '
          'WHERE $_liveInProject '
          'AND f.field_key IN (${_marks(RecordFilter.conditionFieldKeys)}) '
          'AND f.retired_at IS NULL '
          "AND ${_live('record_fields', 'f.id')} "
          "AND ${_display('f')} <> '' "
          'ORDER BY value COLLATE NOCASE, value',
          variables: <Variable<Object>>[
            ...project,
            for (final String key in RecordFilter.conditionFieldKeys)
              Variable<String>(key),
          ],
        )
        .get();
    final List<QueryRow> statuses = await _db
        .customSelect(
          'SELECT DISTINCT r.status AS status FROM records r '
          'WHERE $_liveInProject',
          variables: project,
        )
        .get();
    return RecordFacets(
      templates: <({String id, String name})>[
        for (final QueryRow row in templates)
          (id: row.read<String>('id'), name: row.read<String>('name')),
      ],
      contextLevels: _levels(levels, seen),
      operators: _operators(operators),
      conditions: <String>[
        for (final QueryRow row in conditions) row.read<String>('value'),
      ],
      statuses: <RecordStatus>{
        for (final QueryRow row in statuses)
          ?RecordStatus.fromStored(row.read<String>('status')),
      },
    );
  }

  /// Context levels with the values seen at each: the project's levels in
  /// hierarchy order first, then keys no level declares, by key.
  List<({String key, String label, List<String> values})> _levels(
    List<QueryRow> declared,
    List<QueryRow> seen,
  ) {
    final Map<String, List<String>> values = <String, List<String>>{};
    for (final QueryRow row in seen) {
      values
          .putIfAbsent(row.read<String>('key'), () => <String>[])
          .add(row.read<String>('value'));
    }
    final Map<String, String> labels = <String, String>{
      for (final QueryRow row in declared)
        row.read<String>('key'): row.read<String>('label'),
    };
    final List<String> keys = <String>[
      for (final String key in labels.keys)
        if (values.containsKey(key)) key,
      ...(values.keys.where((String key) => !labels.containsKey(key)).toList()
        ..sort()),
    ];
    return <({String key, String label, List<String> values})>[
      for (final String key in keys)
        (
          key: key,
          label: (labels[key] ?? '').trim().isEmpty ? key : labels[key]!,
          values: values[key]!,
        ),
    ];
  }

  /// Who captured the records, each labelled: this device with its
  /// operator's name, any other device with its id. By label, then id.
  List<({String id, String label})> _operators(List<QueryRow> rows) {
    final String local = _localOperator?.call().trim() ?? '';
    final List<({String id, String label})> operators =
        <({String id, String label})>[
          for (final QueryRow row in rows)
            (
              id: row.read<String>('id'),
              label: _operatorLabel(
                id: row.read<String>('id'),
                isLocal: row.read<int>('local') != 0,
                profileName: row.read<String>('profile_name').trim(),
                localName: local,
              ),
            ),
        ];
    return operators
      ..sort((({String id, String label}) a, ({String id, String label}) b) {
        final int byLabel = a.label.toLowerCase().compareTo(
          b.label.toLowerCase(),
        );
        return byLabel != 0 ? byLabel : a.id.compareTo(b.id);
      });
  }

  static String _operatorLabel({
    required String id,
    required bool isLocal,
    required String profileName,
    required String localName,
  }) {
    if (!isLocal) {
      return id;
    }
    if (localName.isNotEmpty) {
      return localName;
    }
    return profileName.isEmpty ? id : profileName;
  }

  // ---------------------------------------------------------------- helpers

  Future<Result<T>> _attempt<T>(Future<T> Function() read) async {
    try {
      return Success<T>(await read());
    } on Failure catch (failure) {
      return FailureResult<T>(failure);
    } on Object catch (error) {
      return FailureResult<T>(storageFailureFrom(error));
    }
  }

  /// [source] with every database error surfaced as a [Failure].
  static Stream<T> _guard<T>(Stream<T> source) {
    return source.transform(
      StreamTransformer<T, T>.fromHandlers(
        handleError: (Object error, StackTrace stack, EventSink<T> sink) {
          sink.addError(
            error is Failure ? error : storageFailureFrom(error),
            stack,
          );
        },
      ),
    );
  }

  /// The tables a record read touches, so a write to any of them re-emits.
  Set<ResultSetImplementation<dynamic, dynamic>> get _entryTables =>
      <ResultSetImplementation<dynamic, dynamic>>{
        _db.records,
        _db.recordFields,
        _db.photos,
        _db.captions,
        _db.tombstones,
        _db.attachments,
        _db.attachmentOwners,
        _db.auditLog,
        _db.duplicates,
        _db.variances,
        _db.mergeConflicts,
        _db.projects,
        _db.templates,
        _db.templateFields,
        _db.templateRows,
      };

  /// The tables a list page or count touches: the records, every source of
  /// the search index (D5), what names and identifies a record, the quality
  /// flags' tables, the thumbnail's project and the context definitions.
  Set<ResultSetImplementation<dynamic, dynamic>> get _listTables =>
      <ResultSetImplementation<dynamic, dynamic>>{
        _db.records,
        _db.recordFields,
        _db.captions,
        _db.photos,
        _db.tombstones,
        _db.ocrCacheEntries,
        _db.processing,
        _db.processingResults,
        _db.meetings,
        // Segment inserts change no document (spec §30.4.6); a document
        // reads segments again only when its transcript row changes.
        _db.transcripts,
        _db.attachmentOwners,
        _db.templates,
        _db.templateFields,
        _db.templateRows,
        _db.projects,
        _db.duplicates,
        _db.variances,
        _db.mergeConflicts,
        _db.auditLog,
        _db.context,
      };
}

/// The WHERE clause of a page or a count and the arguments it binds, in
/// order. Every dimension of the filter is one AND-ed condition.
final class _Criteria {
  _Criteria._(this.sql, this.variables);

  /// The conditions [filter] sets on [projectId]'s records, aliased `r`.
  /// [byName] adds the documents table's project condition (alias `sd`)
  /// and narrows a search by document id, for the name-ordered page.
  factory _Criteria.of(
    String projectId,
    RecordFilter filter, {
    required bool byName,
  }) {
    final List<String> clauses = <String>[];
    final List<Variable<Object>> variables = <Variable<Object>>[];
    void add(String clause, [Iterable<Variable<Object>> bound = const []]) {
      clauses.add(clause);
      variables.addAll(bound);
    }

    List<Variable<Object>> texts(Iterable<String> values) => <Variable<Object>>[
      for (final String value in values) Variable<String>(value),
    ];

    if (byName) {
      add('sd.project_id = ?', texts(<String>[projectId]));
    }
    add('r.project_id = ?', texts(<String>[projectId]));
    final List<String> statuses = <String>[
      for (final RecordStatus status in RecordStatus.values)
        if (filter.listedStatuses.contains(status)) status.stored,
    ];
    add(
      statuses.isEmpty ? '0' : 'r.status IN (${_marks(statuses)})',
      texts(statuses),
    );
    add(_live('records', 'r.id'));
    if (filter.templateIds.isNotEmpty) {
      final List<String> ids = _sorted(filter.templateIds);
      add('r.template_id IN (${_marks(ids)})', texts(ids));
    }
    for (final String key in _sorted(filter.context.keys)) {
      final List<String> accepted = _sorted(filter.context[key]!);
      if (accepted.isEmpty) {
        continue;
      }
      final String snapshot = _contextObject('r.context_json');
      if (key.contains('"')) {
        add(
          '(SELECT cj.value FROM json_each($snapshot) cj WHERE cj.key = ?) '
          'IN (${_marks(accepted)})',
          texts(<String>[key, ...accepted]),
        );
      } else {
        add(
          'json_extract($snapshot, ?) IN (${_marks(accepted)})',
          texts(<String>['\$."$key"', ...accepted]),
        );
      }
    }
    final DateTime? from = filter.capturedFrom;
    if (from != null) {
      add('r.captured_at >= ?', <Variable<Object>>[
        Variable<int>(
          (from.microsecondsSinceEpoch / Duration.microsecondsPerSecond).ceil(),
        ),
      ]);
    }
    final DateTime? to = filter.capturedTo;
    if (to != null) {
      add('r.captured_at <= ?', <Variable<Object>>[
        Variable<int>(
          (to.microsecondsSinceEpoch / Duration.microsecondsPerSecond).floor(),
        ),
      ]);
    }
    if (filter.operators.isNotEmpty) {
      final List<String> ids = _sorted(filter.operators);
      add('r.captured_by IN (${_marks(ids)})', texts(ids));
    }
    if (filter.conditions.isNotEmpty) {
      final List<String> keys = _sorted(RecordFilter.conditionFieldKeys);
      final List<String> codes = _sorted(filter.conditions);
      add(
        'EXISTS (SELECT 1 FROM record_fields cf WHERE cf.record_id = r.id '
        'AND cf.field_key IN (${_marks(keys)}) AND cf.retired_at IS NULL '
        "AND ${_live('record_fields', 'cf.id')} "
        'AND ${_display('cf')} IN (${_marks(codes)}))',
        texts(<String>[...keys, ...codes]),
      );
    }
    for (final RecordFlag flag in RecordFlag.values) {
      if (filter.flags.contains(flag)) {
        add(_flagCondition(flag));
      }
    }
    final RecordSearch search = RecordSearch(filter.search);
    if (search.narrows) {
      add(
        byName ? search.docCondition('sd.doc') : search.recordCondition('r.id'),
        search.variables,
      );
    }
    return _Criteria._(clauses.join(' AND '), variables);
  }

  /// The AND-ed conditions.
  final String sql;

  /// The arguments [sql] binds, in order.
  final List<Variable<Object>> variables;
}

// -------------------------------------------------------------------- SQL

const String _recordsEntity = 'records';

/// The record row [RecordMapper.entry] reads, for the record bound to `?`.
final String _entrySql =
    'SELECT r.id AS id, r.project_id AS project_id, '
    'r.template_id AS template_id, r.template_row_id AS template_row_id, '
    'r.template_version AS template_version, '
    'r.record_number AS record_number, r.status AS status, '
    'r.processing_mode AS processing_mode, r.source AS source, '
    'r.context_json AS context_json, r.captured_at AS captured_at, '
    'r.captured_by AS captured_by, r.updated_at AS updated_at, '
    'r.approved_at AS approved_at, r.approved_by AS approved_by, '
    "COALESCE(sd.sort_name, '') AS name, "
    "COALESCE(sd.identifier, '') AS identifier, "
    "COALESCE((${_latestCaption(CaptionOwnerType.record, 'r.id')}), '') "
    'AS caption, '
    '(SELECT COUNT(DISTINCT o.attachment_id) FROM attachment_owners o '
    'JOIN attachments a ON a.id = o.attachment_id '
    "WHERE o.owner_type = '${AttachmentOwnerType.record.name}' "
    "AND o.owner_id = r.id AND a.kind = '${AttachmentKind.audio.name}' "
    "AND ${_live('attachments', 'a.id')} "
    "AND ${_live('attachment_owners', 'o.id')}) AS audio_clips, "
    '(SELECT MAX(ea.at) FROM audit_log ea '
    "WHERE ea.entity_type = '$_recordsEntity' AND ea.entity_id = r.id "
    "AND ea.field_key = 'export' "
    "AND ea.action = '${AuditAction.updated.name}' "
    "AND ea.new_value GLOB 'v[0-9]*') AS exported_at, "
    '$_flagColumns '
    'FROM records r '
    'LEFT JOIN ${RecordSchema.searchDocsTable} sd ON sd.record_id = r.id '
    'WHERE r.id = ?';

/// A record's values, retired ones included and tombstoned ones left out,
/// in the order its template declares them, then undeclared ones in the
/// order they were written.
const String _valuesSql =
    'SELECT f.field_key AS field_key, f.value_raw AS value_raw, '
    'f.value_refined AS value_refined, f.value_final AS value_final, '
    'f.source AS source, f.confidence AS confidence, '
    'f.confidence_band AS confidence_band, f.verified AS verified, '
    'f.evidence_removed_at AS evidence_removed_at, '
    'f.retired_at AS retired_at, f.provider AS provider, f.model AS model, '
    'f.method AS method '
    'FROM record_fields f JOIN records r ON r.id = f.record_id '
    'LEFT JOIN template_fields tf ON tf.template_id = r.template_id '
    'AND tf.field_key = f.field_key '
    'WHERE f.record_id = ? '
    "AND NOT EXISTS (SELECT 1 FROM tombstones ft WHERE ft.entity_type = "
    "'record_fields' AND ft.entity_id = f.id) "
    'ORDER BY tf.id IS NULL, tf.sort_order, f.created_at, f.rowid';

/// A record's live photos with their captions, in sort order; the storage
/// path is relative to the storage root, as the thumbnail service takes it.
final String _photosSql =
    'SELECT p.id AS id, p.sha256 AS sha256, '
    "'projects/' || COALESCE(pr.folder_name, '') || '/' || p.relative_path "
    'AS storage_path, p.rotation_degrees AS rotation_degrees, '
    'p.sort_order AS sort_order, p.photo_type AS photo_type, '
    "COALESCE((${_latestCaption(CaptionOwnerType.photo, 'p.id')}), '') "
    'AS caption '
    'FROM photos p LEFT JOIN projects pr ON pr.id = p.project_id '
    'WHERE p.record_id = ? AND $_activePhoto '
    'ORDER BY $_photoOrder';

/// A record's audit rows and its photos' and captions' rows, oldest first.
/// Binds the record id three times. `has_field` and `known_template` let
/// the mapper tell a value keyed like a marker from the marker itself.
const String _historySql =
    'SELECT a.id AS id, a.entity_type AS entity_type, '
    'CAST(a.action AS TEXT) AS action, a.field_key AS field_key, '
    'a.previous_value AS previous_value, a.new_value AS new_value, '
    'a.reason AS reason, a.operator AS operator, a.device AS device, '
    'a.at AS at, '
    "(a.entity_type = '$_recordsEntity' AND a.field_key IS NOT NULL AND "
    'EXISTS (SELECT 1 FROM record_fields hf WHERE hf.record_id = '
    'a.entity_id AND hf.field_key = a.field_key)) AS has_field, '
    "(a.entity_type = '$_recordsEntity' AND a.field_key = 'templateId' AND "
    'EXISTS (SELECT 1 FROM templates ht WHERE ht.id = a.new_value)) '
    'AS known_template '
    'FROM audit_log a '
    "WHERE a.entity_type IN ('$_recordsEntity', 'captions', 'photos') "
    'AND a.entity_id IN (SELECT ? UNION ALL '
    'SELECT hp.id FROM photos hp WHERE hp.record_id = ?) '
    "AND (a.entity_type <> '$_recordsEntity' OR a.entity_id = ?) "
    'ORDER BY a.at, a.id';

/// The recycle bin: deleted records with their tombstone and project name.
/// Binds the deleted status and the project-delete reason.
final String _binSql =
    'SELECT $_summaryColumns, bt.deleted_at AS deleted_at, '
    "bt.reason AS bin_reason, COALESCE(bp.name, '') AS project_name "
    'FROM tombstones bt JOIN records r ON r.id = bt.entity_id '
    'LEFT JOIN projects bp ON bp.id = r.project_id '
    '$_summaryJoins '
    "WHERE bt.entity_type = '$_recordsEntity' AND r.status = ? "
    'AND bt.reason <> ? '
    'AND NOT EXISTS (SELECT 1 FROM tombstones gone WHERE '
    "gone.entity_type = 'projects' AND gone.entity_id = r.project_id) "
    'ORDER BY bt.deleted_at DESC, r.id';

/// The list row [RecordMapper.summary] reads, on `r` joined by
/// [_summaryJoins].
final String _summaryColumns =
    'r.id AS id, r.project_id AS project_id, r.template_id AS template_id, '
    'r.record_number AS record_number, r.status AS status, '
    'r.captured_at AS captured_at, '
    "COALESCE(sd.sort_name, '') AS name, "
    "COALESCE(sd.identifier, '') AS identifier, "
    '$_contextLabel AS context_label, '
    '(SELECT COUNT(*) FROM photos p WHERE p.record_id = r.id '
    'AND $_activePhoto) AS photo_count, '
    'tp.id AS thumb_id, tp.sha256 AS thumb_sha256, '
    "'projects/' || COALESCE(tpr.folder_name, '') || '/' || tp.relative_path "
    'AS thumb_storage_path, tp.rotation_degrees AS thumb_rotation_degrees, '
    'tp.sort_order AS thumb_sort_order, tp.photo_type AS thumb_photo_type, '
    "COALESCE((${_latestCaption(CaptionOwnerType.photo, 'tp.id')}), '') "
    'AS thumb_caption, '
    '$_flagColumns';

/// The search document (name, identifier) and the first live photo of `r`.
const String _summaryJoins =
    'LEFT JOIN ${RecordSchema.searchDocsTable} sd ON sd.record_id = r.id '
    'LEFT JOIN photos tp ON tp.id = (SELECT p.id FROM photos p '
    'WHERE p.record_id = r.id AND $_activePhoto '
    'ORDER BY $_photoOrder LIMIT 1) '
    'LEFT JOIN projects tpr ON tpr.id = tp.project_id';

const String _photoOrder = 'p.sort_order, p.captured_at DESC, p.id';

/// True for a photo (alias `p`) the capture tray shows: not tombstoned and
/// not replaced by a live derived version. Means exactly what the core
/// `activePhotoCondition` means, but the replaced photos are an
/// uncorrelated list SQLite builds once per statement: `photos` has no
/// index on `derived_from`, so the core condition's correlated check scans
/// every photo for each photo it tests (FE-PERF-03).
const String _activePhoto =
    'NOT EXISTS (SELECT 1 FROM tombstones pt WHERE '
    "pt.entity_type = 'photos' AND pt.entity_id = p.id) "
    'AND p.id NOT IN (SELECT dp.derived_from FROM photos dp '
    'WHERE dp.derived_from IS NOT NULL AND NOT EXISTS (SELECT 1 FROM '
    "tombstones dt WHERE dt.entity_type = 'photos' AND dt.entity_id = dp.id))";

/// Every quality flag of `r` as a 0/1 column named by
/// [RecordMapper.flagColumns].
final String _flagColumns = <String>[
  for (final MapEntry<RecordFlag, String> flag
      in RecordMapper.flagColumns.entries)
    '(${_flagCondition(flag.key)}) AS ${flag.value}',
].join(', ');

/// The condition that [flag] holds for record `r`.
String _flagCondition(RecordFlag flag) {
  return switch (flag) {
    RecordFlag.hasPhotos =>
      'EXISTS (SELECT 1 FROM photos p WHERE p.record_id = r.id '
          'AND $_activePhoto)',
    RecordFlag.hasDuplicate =>
      'r.id IN (SELECT dl.left_record_id FROM duplicates dl '
          "WHERE ${_unresolvedPair('dl')} UNION ALL SELECT dl.right_record_id "
          "FROM duplicates dl WHERE ${_unresolvedPair('dl')})",
    RecordFlag.hasConflict =>
      'r.id IN (SELECT mc.entity_id FROM merge_conflicts mc '
          "WHERE mc.resolution IS NULL AND mc.entity_type = '$_recordsEntity' "
          'UNION ALL SELECT mf.record_id FROM merge_conflicts mc '
          'JOIN record_fields mf ON mf.id = mc.entity_id '
          "WHERE mc.resolution IS NULL AND mc.entity_type = 'record_fields' "
          'UNION ALL SELECT mp.record_id FROM merge_conflicts mc '
          'JOIN photos mp ON mp.id = mc.entity_id '
          "WHERE mc.resolution IS NULL AND mc.entity_type = 'photos')",
    RecordFlag.hasVariance =>
      'EXISTS (SELECT 1 FROM variances v WHERE v.record_id = r.id '
          "AND v.status <> 'match' AND v.resolved_at IS NULL "
          "AND ${_live('variances', 'v.id')})",
    RecordFlag.evidenceRemoved =>
      'EXISTS (SELECT 1 FROM record_fields ef WHERE ef.record_id = r.id '
          'AND ef.evidence_removed_at IS NOT NULL '
          "AND ${_live('record_fields', 'ef.id')})",
    RecordFlag.mergedFromBundle =>
      'EXISTS (SELECT 1 FROM audit_log ma WHERE '
          "ma.entity_type = '$_recordsEntity' AND ma.entity_id = r.id "
          "AND ma.field_key = 'merge' AND ("
          "(ma.action = '${AuditAction.created.name}' "
          "AND ma.new_value = 'inserted') OR "
          "(ma.action = '${AuditAction.updated.name}' "
          "AND ma.new_value = 'updated')))",
  };
}

String _unresolvedPair(String alias) =>
    "$alias.status = '${DuplicatePairStatus.unresolved.name}' "
    "AND ${_live('duplicates', '$alias.id')} "
    // A pair whose other record went to the recycle bin no longer asks for a
    // choice (task 015): the quality list and counts leave it out too.
    'AND NOT EXISTS (SELECT 1 FROM records gone WHERE gone.id IN '
    "($alias.left_record_id, $alias.right_record_id) "
    "AND gone.status = '${RecordStatus.deleted.stored}')";

/// The deepest context value of `r`: the value of the project's lowest
/// context level set in its snapshot, else the last text value in the
/// snapshot, else empty.
final String _contextLabel =
    'COALESCE((SELECT cj.value FROM context_definitions cd '
    'JOIN json_each(${_contextObject('r.context_json')}) cj '
    'ON cj.key = cd.field_key WHERE cd.project_id = r.project_id '
    "AND cj.type = 'text' AND trim(cj.value) <> '' "
    'ORDER BY cd.level DESC, cd.id LIMIT 1), '
    '(SELECT cj.value FROM json_each(${_contextObject('r.context_json')}) cj '
    "WHERE cj.type = 'text' AND trim(cj.value) <> '' "
    "ORDER BY cj.id DESC LIMIT 1), '')";

/// Live, listable records of the project bound to `?`, aliased `r`.
final String _liveInProject =
    "r.project_id = ? AND r.status <> '${RecordStatus.deleted.stored}' "
    "AND ${_live('records', 'r.id')}";

/// The context snapshot held in [column] as a flat JSON object of level
/// key to value, as [RecordMapper.context] reads it: capture's flat object
/// as it is, the context writer's `{levels, values, pinned}` as its values
/// with the pinned values over them, and anything else as `{}`.
String _contextObject(String column) {
  return "(CASE WHEN json_valid($column) IS NOT 1 THEN '{}' "
      "WHEN json_type($column) <> 'object' THEN '{}' "
      "WHEN json_type($column, '\$.levels') = 'array' "
      "AND json_type($column, '\$.values') = 'object' "
      "THEN json_patch(json_extract($column, '\$.values'), "
      "CASE WHEN json_type($column, '\$.pinned') = 'object' "
      "THEN json_extract($column, '\$.pinned') ELSE '{}' END) "
      'ELSE $column END)';
}

/// The newest live caption of the [owner] row whose id is [ownerId]: its
/// refined text when one was written, its raw text otherwise.
String _latestCaption(CaptionOwnerType owner, String ownerId) {
  return 'SELECT COALESCE(c.text_refined, c.text_raw) FROM captions c '
      "WHERE c.owner_type = '${owner.name}' AND c.owner_id = $ownerId "
      "AND ${_live('captions', 'c.id')} "
      'ORDER BY c.created_at DESC, c.id DESC LIMIT 1';
}

/// What value [alias] displays, as `RecordValue.display` reads it: the
/// final value, else the refined one, else the raw one, the first that is
/// not empty.
String _display(String alias) {
  return "COALESCE(NULLIF($alias.value_final, ''), "
      "NULLIF($alias.value_refined, ''), COALESCE($alias.value_raw, ''))";
}

/// True while the [entityType] row whose id is [id] has no tombstone.
String _live(String entityType, String id) {
  return 'NOT EXISTS (SELECT 1 FROM tombstones xt '
      "WHERE xt.entity_type = '$entityType' AND xt.entity_id = $id)";
}

String _marks(Iterable<Object> values) =>
    List<String>.filled(values.length, '?').join(', ');

List<String> _sorted(Iterable<String> values) => values.toList()..sort();

bool _sameList<T>(List<T> left, List<T> right) {
  if (left.length != right.length) {
    return false;
  }
  for (int index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

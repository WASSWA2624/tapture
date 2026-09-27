import 'conflict_kind.dart';
import 'field_conflict.dart';
import 'merge_plan.dart';
import 'settlement_rule.dart';

/// Works out a merge by content (task 076, W21, D16): rows in, a
/// [MergePlan] out, nothing written (FE-STR-05). Rows are keyed by SQL
/// column name, as a project package carries them.
///
/// A row new to this device is inserted, moved into the target project,
/// its template mapped to the matched local one. Identical content is
/// skipped. A differing field value goes through specification §47's
/// rules in order, then to a person; so do a differing caption and status.
/// A delete applies when this side has not changed since; otherwise a
/// person decides. Photos and attachments already here by content are not
/// copied twice.
abstract final class MergePlanner {
  /// Plans merging [incoming] into [local], the target project's rows.
  ///
  /// [templateMapping] maps incoming template ids to local ones.
  /// [elsewhere] lists, by table, incoming ids this device holds outside the
  /// target project, which are left alone. [skipRecords] are records a
  /// person chose not to import (W22). [decided] holds conflicts a person
  /// already settled by keeping this device's value, as
  /// `<conflict id>|<incoming value>`; they are not raised again.
  static MergePlan plan({
    required Map<String, List<Map<String, Object?>>> incoming,
    required Map<String, List<Map<String, Object?>>> local,
    required Map<String, String> templateMapping,
    required String targetProjectId,
    required String incomingProjectId,
    Map<String, Set<String>> elsewhere = const <String, Set<String>>{},
    Set<String> skipRecords = const <String>{},
    Set<String> decided = const <String>{},
  }) {
    return _Planner(
      incoming: incoming,
      local: local,
      templates: <String, String>{...templateMapping},
      target: targetProjectId,
      source: incomingProjectId,
      elsewhere: elsewhere,
      skip: skipRecords,
      decided: decided,
    ).run();
  }
}

final class _Planner {
  _Planner({
    required this.incoming,
    required this.local,
    required this.templates,
    required this.target,
    required this.source,
    required this.elsewhere,
    required this.skip,
    required this.decided,
  });

  final Map<String, List<Map<String, Object?>>> incoming;
  final Map<String, List<Map<String, Object?>>> local;
  final Map<String, String> templates;
  final String target;
  final String source;
  final Map<String, Set<String>> elsewhere;
  final Set<String> skip;
  final Set<String> decided;

  final Map<String, List<Map<String, Object?>>> _inserts =
      <String, List<Map<String, Object?>>>{};
  final Map<String, Set<String>> _inserted = <String, Set<String>>{};
  final List<({String entry, String target})> _files =
      <({String entry, String target})>[];
  final List<
    ({
      String rowId,
      String fieldKey,
      String previous,
      String value,
      bool verified,
      SettlementRule rule,
    })
  >
  _settled =
      <
        ({
          String rowId,
          String fieldKey,
          String previous,
          String value,
          bool verified,
          SettlementRule rule,
        })
      >[];
  final List<FieldConflict> _conflicts = <FieldConflict>[];
  final Set<String> _updatedRecords = <String>{};
  int _newPhotos = 0;
  int _photosHere = 0;
  int _deletions = 0;
  int _kept = 0;
  int _elsewhere = 0;

  List<Map<String, Object?>> _theirs(String table) =>
      incoming[table] ?? const <Map<String, Object?>>[];

  List<Map<String, Object?>> _mine(String table) =>
      local[table] ?? const <Map<String, Object?>>[];

  Map<String, Map<String, Object?>> _mineById(String table) =>
      <String, Map<String, Object?>>{
        for (final Map<String, Object?> row in _mine(table))
          row['id']! as String: row,
      };

  bool _isElsewhere(String table, String id) =>
      elsewhere[table]?.contains(id) ?? false;

  void _add(String table, Map<String, Object?> row) {
    _inserts.putIfAbsent(table, () => <Map<String, Object?>>[]).add(row);
    _inserted.putIfAbsent(table, () => <String>{}).add(row['id']! as String);
  }

  bool _wasInserted(String table, String id) =>
      _inserted[table]?.contains(id) ?? false;

  /// Inserts every incoming row of [table] this device lacks whose parent
  /// [ready] accepts, [move] adjusting it first.
  void _union(
    String table, {
    bool Function(Map<String, Object?> row)? ready,
    Map<String, Object?> Function(Map<String, Object?> row)? move,
  }) {
    final Set<String> mine = _mineById(table).keys.toSet();
    for (final Map<String, Object?> row in _theirs(table)) {
      final String id = row['id']! as String;
      if (mine.contains(id) || _wasInserted(table, id)) {
        continue;
      }
      if (_isElsewhere(table, id)) {
        _elsewhere += 1;
        continue;
      }
      if (ready != null && !ready(row)) {
        continue;
      }
      _add(table, move == null ? row : move(row));
    }
  }

  Map<String, Object?> _intoTarget(Map<String, Object?> row) =>
      <String, Object?>{...row, 'project_id': target};

  MergePlan run() {
    _context();
    _templates();
    _reference();
    final Set<String> records = _records();
    final Set<String> fields = _fieldValues(records);
    _union(
      'field_evidence',
      ready: (Map<String, Object?> row) =>
          fields.contains(row['record_field_id']),
    );
    final Set<String> photos = _media('photos', records);
    final Set<String> attachments = _media('attachments', records);
    final Set<String> owners = <String>{...records, ...photos};
    _union(
      'attachment_owners',
      ready: (Map<String, Object?> row) =>
          attachments.contains(row['attachment_id']) &&
          owners.contains(row['owner_id']),
    );
    _captions(owners);
    _union(
      'meetings',
      ready: (Map<String, Object?> row) => records.contains(row['record_id']),
    );
    final Set<String> meetings = <String>{
      ..._mineById('meetings').keys,
      ...?_inserted['meetings'],
    };
    for (final String table in const <String>['attendees', 'meeting_actions']) {
      _union(
        table,
        ready: (Map<String, Object?> row) =>
            meetings.contains(row['meeting_id']),
      );
    }
    _union(
      'variances',
      ready: (Map<String, Object?> row) => records.contains(row['record_id']),
      move: _intoTarget,
    );
    _union(
      'processing_jobs',
      ready: (Map<String, Object?> row) => records.contains(row['record_id']),
    );
    final Set<String> jobs = <String>{
      ..._mineById('processing_jobs').keys,
      ...?_inserted['processing_jobs'],
    };
    _union(
      'processing_results',
      ready: (Map<String, Object?> row) => jobs.contains(row['job_id']),
    );
    _union(
      'duplicates',
      ready: (Map<String, Object?> row) =>
          records.contains(row['left_record_id']) &&
          records.contains(row['right_record_id']),
      move: _intoTarget,
    );
    _tombstones();
    final Set<String> known = <String>{
      for (final Set<String> ids in _inserted.values) ...ids,
      for (final List<Map<String, Object?>> rows in local.values)
        for (final Map<String, Object?> row in rows) row['id']! as String,
    };
    _union(
      'audit_log',
      ready: (Map<String, Object?> row) => known.contains(row['entity_id']),
    );
    return MergePlan(
      inserts: _inserts,
      files: _files,
      settled: _settled,
      conflicts: _conflicts,
      insertedRecords: <String>[...?_inserted['records']],
      updatedRecords: _updatedRecords.toList(),
      counts: (
        newRecords: _inserted['records']?.length ?? 0,
        updatedRecords: _updatedRecords.length,
        newPhotos: _newPhotos,
        photosHere: _photosHere,
        deletions: _deletions,
        kept: _kept,
        elsewhere: _elsewhere,
      ),
    );
  }

  /// Levels union by field key and are appended after this device's;
  /// presets union by name. The current values stay local.
  void _context() {
    final Set<String> keys = <String>{
      for (final Map<String, Object?> level in _mine('context_definitions'))
        level['field_key']! as String,
    };
    var next = -1;
    for (final Map<String, Object?> level in _mine('context_definitions')) {
      final Object? order = level['level'];
      if (order is int && order > next) {
        next = order;
      }
    }
    final List<Map<String, Object?>> levels =
        List<Map<String, Object?>>.of(_theirs('context_definitions'))..sort(
          (Map<String, Object?> a, Map<String, Object?> b) =>
              ((a['level'] as int?) ?? 0).compareTo((b['level'] as int?) ?? 0),
        );
    final Set<String> mine = _mineById('context_definitions').keys.toSet();
    for (final Map<String, Object?> level in levels) {
      final String id = level['id']! as String;
      if (mine.contains(id) || keys.contains(level['field_key'])) {
        continue;
      }
      if (_isElsewhere('context_definitions', id)) {
        _elsewhere += 1;
        continue;
      }
      next += 1;
      keys.add(level['field_key']! as String);
      _add('context_definitions', <String, Object?>{
        ...level,
        'project_id': target,
        'level': next,
      });
    }
    final Set<String> names = <String>{
      for (final Map<String, Object?> preset in _mine('context_presets'))
        preset['name']! as String,
    };
    _union(
      'context_presets',
      ready: (Map<String, Object?> row) => !names.contains(row['name']),
      move: _intoTarget,
    );
  }

  /// Within the same project, a template the other device added arrives
  /// whole; across projects only the mapping applies.
  void _templates() {
    if (target != source) {
      return;
    }
    final Set<String> mine = _mineById('templates').keys.toSet();
    for (final Map<String, Object?> template in _theirs('templates')) {
      final String id = template['id']! as String;
      if (mine.contains(id) || templates.containsKey(id)) {
        continue;
      }
      if (_isElsewhere('templates', id)) {
        _elsewhere += 1;
        continue;
      }
      _add('templates', template);
      templates[id] = id;
    }
    final Set<String> added = <String>{...?_inserted['templates']};
    for (final String table in const <String>[
      'template_fields',
      'template_rows',
    ]) {
      _union(
        table,
        ready: (Map<String, Object?> row) => added.contains(row['template_id']),
      );
    }
  }

  /// A dataset new here arrives with its rows. In a dataset both sides
  /// hold, a new key is added and a differing row keeps this device's
  /// values, counted as kept.
  void _reference() {
    final Map<String, Map<String, Object?>> mine = _mineById(
      'reference_datasets',
    );
    final Map<String, Map<String, Object?>> rows =
        <String, Map<String, Object?>>{
          for (final Map<String, Object?> row in _mine('reference_rows'))
            '${row['dataset_id']}/${row['key_value']}': row,
        };
    final Set<String> rowIds = _mineById('reference_rows').keys.toSet();
    final Set<String> merged = <String>{};
    for (final Map<String, Object?> dataset in _theirs('reference_datasets')) {
      final String id = dataset['id']! as String;
      if (mine.containsKey(id)) {
        merged.add(id);
        continue;
      }
      if (_isElsewhere('reference_datasets', id)) {
        _elsewhere += 1;
        continue;
      }
      _add(
        'reference_datasets',
        dataset['project_id'] == source
            ? <String, Object?>{...dataset, 'project_id': target}
            : dataset,
      );
      merged.add(id);
    }
    for (final Map<String, Object?> row in _theirs('reference_rows')) {
      final String id = row['id']! as String;
      if (!merged.contains(row['dataset_id']) || rowIds.contains(id)) {
        continue;
      }
      if (_isElsewhere('reference_rows', id)) {
        _elsewhere += 1;
        continue;
      }
      final Map<String, Object?>? here =
          rows['${row['dataset_id']}/${row['key_value']}'];
      if (here != null) {
        if (here['values'] != row['values']) {
          _kept += 1;
        }
        continue;
      }
      _add('reference_rows', row);
    }
  }

  /// Returns every record the project holds after the merge.
  Set<String> _records() {
    final Map<String, Map<String, Object?>> mine = _mineById('records');
    final Set<String> all = <String>{...mine.keys};
    for (final Map<String, Object?> record in _theirs('records')) {
      final String id = record['id']! as String;
      if (skip.contains(id)) {
        continue;
      }
      final Map<String, Object?>? here = mine[id];
      if (here != null) {
        final String mineStatus = '${here['status'] ?? ''}';
        final String theirStatus = '${record['status'] ?? ''}';
        if (mineStatus != theirStatus &&
            !_tombstoned(local, 'records', id) &&
            !_tombstoned(incoming, 'records', id)) {
          _raise(
            _conflict(
              ConflictKind.status,
              table: 'records',
              mineRow: here,
              theirRow: record,
              recordId: id,
              mine: mineStatus,
              theirs: theirStatus,
            ),
          );
        }
        continue;
      }
      if (_isElsewhere('records', id)) {
        _elsewhere += 1;
        continue;
      }
      if (_tombstoned(incoming, 'records', id)) {
        continue;
      }
      final String? template = templates[record['template_id']];
      if (template == null) {
        continue;
      }
      _add('records', <String, Object?>{
        ...record,
        'project_id': target,
        'template_id': template,
      });
      all.add(id);
    }
    return all;
  }

  /// Returns every field value row the project holds after the merge.
  Set<String> _fieldValues(Set<String> records) {
    final Map<String, Map<String, Object?>> byId = _mineById('record_fields');
    final Map<String, Map<String, Object?>> byKey =
        <String, Map<String, Object?>>{
          for (final Map<String, Object?> row in _mine('record_fields'))
            '${row['record_id']}/${row['field_key']}': row,
        };
    final Set<String> all = <String>{...byId.keys};
    for (final Map<String, Object?> value in _theirs('record_fields')) {
      final String id = value['id']! as String;
      final String recordId = value['record_id']! as String;
      if (!records.contains(recordId)) {
        continue;
      }
      final Map<String, Object?>? here =
          byId[id] ?? byKey['$recordId/${value['field_key']}'];
      if (here == null) {
        if (_isElsewhere('record_fields', id)) {
          _elsewhere += 1;
          continue;
        }
        _add('record_fields', value);
        all.add(id);
        if (!_wasInserted('records', recordId)) {
          _updatedRecords.add(recordId);
        }
        continue;
      }
      final String mine = _effective(here);
      final String theirs = _effective(value);
      if (mine == theirs) {
        continue;
      }
      switch (_settle(here, value, mine: mine, theirs: theirs)) {
        case (SettlementRule rule, true):
          _settled.add((
            rowId: here['id']! as String,
            fieldKey: here['field_key']! as String,
            previous: mine,
            value: theirs,
            verified: _flag(value['verified']),
            rule: rule,
          ));
          _updatedRecords.add(recordId);
        case (SettlementRule _, false):
          _kept += 1;
        case null:
          _raise(
            _conflict(
              ConflictKind.value,
              table: 'record_fields',
              mineRow: here,
              theirRow: value,
              recordId: recordId,
              fieldKey: here['field_key']! as String,
              mine: mine,
              theirs: theirs,
            ),
          );
      }
    }
    return all;
  }

  /// Photos and attachments: already here by id or by content, or copied
  /// under their own path, or a fresh one when that path holds another
  /// file. Returns every one the project holds after the merge.
  Set<String> _media(String table, Set<String> records) {
    final Set<String> ids = _mineById(table).keys.toSet();
    final Set<String> shas = <String>{
      for (final Map<String, Object?> row in _mine(table))
        row['sha256']! as String,
    };
    final Set<String> paths = <String>{
      for (final Map<String, Object?> row in _mine(table))
        row['relative_path']! as String,
    };
    final Set<String> all = <String>{...ids};
    for (final Map<String, Object?> row in _theirs(table)) {
      final String id = row['id']! as String;
      if (ids.contains(id)) {
        continue;
      }
      if (_isElsewhere(table, id)) {
        _elsewhere += 1;
        continue;
      }
      final Object? record = row['record_id'];
      if ((record is String && !records.contains(record)) ||
          _tombstoned(incoming, table, id)) {
        continue;
      }
      final String sha = row['sha256']! as String;
      if (shas.contains(sha)) {
        if (table == 'photos') {
          _photosHere += 1;
        }
        continue;
      }
      final String path = row['relative_path']! as String;
      final String landing = paths.contains(path)
          ? _mergedPath(id, path)
          : path;
      _add(table, <String, Object?>{
        ...row,
        'project_id': target,
        'relative_path': landing,
      });
      _files.add((entry: path, target: landing));
      shas.add(sha);
      paths.add(landing);
      all.add(id);
      if (table == 'photos') {
        _newPhotos += 1;
      }
    }
    return all;
  }

  void _captions(Set<String> owners) {
    final Map<String, Map<String, Object?>> mine = _mineById('captions');
    for (final Map<String, Object?> caption in _theirs('captions')) {
      final String id = caption['id']! as String;
      final Map<String, Object?>? here = mine[id];
      if (here == null) {
        if (_isElsewhere('captions', id)) {
          _elsewhere += 1;
          continue;
        }
        if (owners.contains(caption['owner_id'])) {
          _add('captions', caption);
        }
        continue;
      }
      final String mineText = _captionText(here);
      final String theirText = _captionText(caption);
      if (mineText == theirText) {
        continue;
      }
      if (theirText.isEmpty) {
        _kept += 1;
        continue;
      }
      _raise(
        _conflict(
          ConflictKind.caption,
          table: 'captions',
          mineRow: here,
          theirRow: caption,
          recordId: caption['owner_id']! as String,
          mine: mineText,
          theirs: theirText,
        ),
      );
    }
  }

  /// Deletions travel both ways, and a change made after a delete goes to a
  /// person rather than being undone silently (specification §44).
  void _tombstones() {
    final Map<String, Map<String, Object?>> mineTombs =
        <String, Map<String, Object?>>{
          for (final Map<String, Object?> row in _mine('tombstones'))
            '${row['entity_type']}/${row['entity_id']}': row,
        };
    final Map<String, Map<String, Object?>> theirTombs =
        <String, Map<String, Object?>>{
          for (final Map<String, Object?> row in _theirs('tombstones'))
            '${row['entity_type']}/${row['entity_id']}': row,
        };
    final Set<String> tombIds = _mineById('tombstones').keys.toSet();
    for (final MapEntry<String, Map<String, Object?>> entry
        in theirTombs.entries) {
      if (mineTombs.containsKey(entry.key)) {
        continue;
      }
      final Map<String, Object?> tomb = entry.value;
      final String type = tomb['entity_type']! as String;
      final String entity = tomb['entity_id']! as String;
      final String id = tomb['id']! as String;
      if (tombIds.contains(id) || _isElsewhere('tombstones', id)) {
        continue;
      }
      if (_wasInserted(type, entity)) {
        _add('tombstones', tomb);
        continue;
      }
      final Map<String, Object?>? here = _mineById(type)[entity];
      if (here == null) {
        continue;
      }
      if (_at(here['updated_at']) <= _at(tomb['deleted_at'])) {
        _add('tombstones', tomb);
        _deletions += 1;
        continue;
      }
      _raise(
        _conflict(
          ConflictKind.deletedThere,
          table: type,
          mineRow: here,
          theirRow: tomb,
          recordId: type == 'records' ? entity : '${here['record_id'] ?? ''}',
          mine: '',
          theirs: '',
        ),
      );
    }
    for (final MapEntry<String, Map<String, Object?>> entry
        in mineTombs.entries) {
      if (theirTombs.containsKey(entry.key)) {
        continue;
      }
      final Map<String, Object?> tomb = entry.value;
      final String type = tomb['entity_type']! as String;
      final String entity = tomb['entity_id']! as String;
      Map<String, Object?>? theirs;
      for (final Map<String, Object?> row in _theirs(type)) {
        if (row['id'] == entity) {
          theirs = row;
        }
      }
      if (theirs == null) {
        continue;
      }
      if (_at(theirs['updated_at']) <= _at(tomb['deleted_at'])) {
        _kept += 1;
        continue;
      }
      _raise(
        _conflict(
          ConflictKind.deletedHere,
          table: type,
          mineRow: tomb,
          theirRow: theirs,
          recordId: type == 'records' ? entity : '${theirs['record_id'] ?? ''}',
          mine: '',
          theirs: '',
          rowId: entity,
        ),
      );
    }
  }

  /// Adds [conflict] for a person, unless one already kept this device's
  /// value against the same incoming value.
  void _raise(FieldConflict conflict) {
    if (decided.contains('${conflict.id}|${conflict.theirs}')) {
      _kept += 1;
      return;
    }
    _conflicts.add(conflict);
  }

  FieldConflict _conflict(
    ConflictKind kind, {
    required String table,
    required Map<String, Object?> mineRow,
    required Map<String, Object?> theirRow,
    required String recordId,
    required String mine,
    required String theirs,
    String fieldKey = '',
    String? rowId,
  }) {
    return FieldConflict(
      kind: kind,
      table: table,
      rowId: rowId ?? mineRow['id']! as String,
      recordId: recordId,
      fieldKey: fieldKey,
      fieldLabel: fieldKey.isEmpty ? '' : _fieldLabel(recordId, fieldKey),
      recordLabel: _recordLabel(recordId),
      mine: mine,
      theirs: theirs,
      mineDevice: '${mineRow['updated_by_device'] ?? ''}',
      theirsDevice: '${theirRow['updated_by_device'] ?? ''}',
      mineAt: mineRow['updated_at'],
      theirsAt: theirRow['updated_at'] ?? theirRow['deleted_at'],
    );
  }

  String _fieldLabel(String recordId, String fieldKey) {
    final Object? template = _mineById('records')[recordId]?['template_id'];
    for (final Map<String, Object?> field in _mine('template_fields')) {
      if (field['template_id'] == template && field['field_key'] == fieldKey) {
        final Object? label = field['label'];
        if (label is String && label.trim().isNotEmpty) {
          return label;
        }
      }
    }
    return fieldKey;
  }

  String _recordLabel(String recordId) {
    for (final Map<String, Object?> caption in _mine('captions')) {
      if (caption['owner_id'] == recordId) {
        final String text = _captionText(caption);
        if (text.isNotEmpty) {
          return text;
        }
      }
    }
    return '';
  }
}

/// §47's rules for two differing values, in order. Returns the rule and
/// whether the incoming value wins, or null when a person must decide.
(SettlementRule, bool)? _settle(
  Map<String, Object?> here,
  Map<String, Object?> there, {
  required String mine,
  required String theirs,
}) {
  final bool hereVerified = _flag(here['verified']);
  final bool thereVerified = _flag(there['verified']);
  if (hereVerified != thereVerified) {
    return (SettlementRule.verifiedBeatsUnverified, thereVerified);
  }
  final bool hereScanned = _scanned(here['source']);
  final bool thereScanned = _scanned(there['source']);
  if (hereScanned && _inferred(there['source'])) {
    return (SettlementRule.scannedBeatsInferred, false);
  }
  if (thereScanned && _inferred(here['source'])) {
    return (SettlementRule.scannedBeatsInferred, true);
  }
  if (mine.isEmpty && _untouched(here)) {
    return (SettlementRule.valueBeatsUntouchedEmpty, true);
  }
  if (theirs.isEmpty && _untouched(there)) {
    return (SettlementRule.valueBeatsUntouchedEmpty, false);
  }
  return null;
}

/// What a field value reads as: final, else refined, else as captured.
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

bool _flag(Object? value) => value == true || value == 1;

/// Stored instants arrive as whole seconds; anything else sorts first.
int _at(Object? value) => value is int ? value : 0;

/// Never edited since it was written.
bool _untouched(Map<String, Object?> row) {
  final Object? rev = row['rev'];
  return rev == null || (rev is int && rev <= 1);
}

String _source(Object? value) =>
    '${value ?? ''}'.toLowerCase().replaceAll(RegExp('[^a-z]'), '');

/// Read from a code or a register rather than guessed.
bool _scanned(Object? source) => const <String>{
  'barcode',
  'qr',
  'lookup',
  'reference',
}.contains(_source(source));

/// Read or inferred by a machine: open to doubt.
bool _inferred(Object? source) => const <String>{
  'ocr',
  'extraction',
  'aivision',
  'aitext',
  'ai',
  'stt',
  'caption',
  'default',
}.contains(_source(source));

bool _tombstoned(
  Map<String, List<Map<String, Object?>>> side,
  String table,
  String id,
) {
  for (final Map<String, Object?> tomb
      in side['tombstones'] ?? const <Map<String, Object?>>[]) {
    if (tomb['entity_type'] == table && tomb['entity_id'] == id) {
      return true;
    }
  }
  return false;
}

/// A fresh place for a file whose path this project already uses for
/// another file: `<folder>/_merged/<id><extension>`.
String _mergedPath(String id, String path) {
  final int slash = path.lastIndexOf('/');
  final String folder = slash < 0 ? '' : path.substring(0, slash + 1);
  final String name = slash < 0 ? path : path.substring(slash + 1);
  final int dot = name.lastIndexOf('.');
  final String extension = dot <= 0 ? '' : name.substring(dot);
  return '${folder}_merged/$id$extension';
}

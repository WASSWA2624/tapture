import 'dart:io';

import 'package:drift/drift.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// The type this file is named for (FE-STR-06). The contract name is
/// [IntegrityFinding].
typedef IntegrityCheck = IntegrityFinding;

/// One broken reference the startup check reports and never repairs.
sealed class IntegrityFinding {
  /// Creates a finding.
  const IntegrityFinding();

  /// Table the broken row sits in.
  String get entityType;

  /// Merge id of the broken row.
  String get entityId;

  /// What is wrong, in operator language.
  String get detail;
}

/// Runs a read-only integrity pass over [db].
///
/// Rows are examined in pages of [AppConstants.lists.pageSize]. File existence
/// runs off the UI thread. Nothing is deleted, rewritten or repaired.
Future<Result<List<IntegrityFinding>>> runIntegrityCheck(AppDatabase db) {
  return Result.captureAsync(() => _scan(db));
}

final class _Finding extends IntegrityFinding {
  const _Finding({
    required this.entityType,
    required this.entityId,
    required this.detail,
  });

  @override
  final String entityType;

  @override
  final String entityId;

  @override
  final String detail;
}

Future<List<IntegrityFinding>> _scan(AppDatabase db) async {
  return <IntegrityFinding>[
    ...await _orphans(
      db,
      sql:
          'SELECT rf.id AS id FROM record_fields rf '
          'WHERE rf.id > ? AND NOT EXISTS ('
          'SELECT 1 FROM records r WHERE r.id = rf.record_id'
          ') ORDER BY rf.id LIMIT ?',
      entityType: 'record_fields',
      detail: 'The record this field belongs to is gone.',
    ),
    ...await _missingFiles(
      db,
      table: 'photos',
      detail: 'The file this photo points at is missing.',
    ),
    ...await _missingFiles(
      db,
      table: 'attachments',
      detail: 'The file this attachment points at is missing.',
    ),
    ...await _orphans(
      db,
      sql:
          'SELECT j.id AS id FROM processing_jobs j '
          'WHERE j.id > ? AND NOT EXISTS ('
          'SELECT 1 FROM records r WHERE r.id = j.record_id'
          ') ORDER BY j.id LIMIT ?',
      entityType: 'processing_jobs',
      detail: 'The record this job points at is gone.',
    ),
    ...await _orphans(
      db,
      sql:
          'SELECT e.id AS id FROM field_evidence e '
          'WHERE e.id > ? AND NOT EXISTS ('
          'SELECT 1 FROM record_fields f '
          'JOIN records r ON r.id = f.record_id '
          'WHERE f.id = e.record_field_id'
          ') ORDER BY e.id LIMIT ?',
      entityType: 'field_evidence',
      detail: 'The record this evidence points at is gone.',
    ),
    ...await _orphans(
      db,
      sql:
          'SELECT r.id AS id FROM records r '
          'WHERE r.id > ? AND r.status = ? AND NOT EXISTS ('
          'SELECT 1 FROM tombstones t '
          'WHERE t.entity_type = ? AND t.entity_id = r.id'
          ') ORDER BY r.id LIMIT ?',
      entityType: 'records',
      detail: 'This row is marked deleted and has no tombstone.',
      extra: <Variable<Object>>[
        const Variable<String>('deleted'),
        const Variable<String>('records'),
      ],
    ),
    ...await _orphans(
      db,
      sql:
          'SELECT p.id AS id FROM projects p '
          'WHERE p.id > ? AND p.status = ? AND NOT EXISTS ('
          'SELECT 1 FROM tombstones t '
          'WHERE t.entity_type = ? AND t.entity_id = p.id'
          ') ORDER BY p.id LIMIT ?',
      entityType: 'projects',
      detail: 'This row is marked deleted and has no tombstone.',
      extra: <Variable<Object>>[
        const Variable<String>('deleted'),
        const Variable<String>('projects'),
      ],
    ),
    ...await _foreignKeys(db),
  ];
}

Future<List<IntegrityFinding>> _orphans(
  AppDatabase db, {
  required String sql,
  required String entityType,
  required String detail,
  List<Variable<Object>> extra = const <Variable<Object>>[],
}) async {
  final List<IntegrityFinding> findings = <IntegrityFinding>[];
  String after = '';
  while (true) {
    final List<QueryRow> rows = await db
        .customSelect(
          sql,
          variables: <Variable<Object>>[
            Variable<String>(after),
            ...extra,
            Variable<int>(AppConstants.lists.pageSize),
          ],
        )
        .get();
    if (rows.isEmpty) {
      break;
    }
    for (final QueryRow row in rows) {
      final String id = row.read<String>('id');
      findings.add(
        _Finding(entityType: entityType, entityId: id, detail: detail),
      );
      after = id;
    }
  }
  return findings;
}

Future<List<IntegrityFinding>> _missingFiles(
  AppDatabase db, {
  required String table,
  required String detail,
}) async {
  final List<IntegrityFinding> findings = <IntegrityFinding>[];
  String after = '';
  while (true) {
    final List<QueryRow> rows = await db
        .customSelect(
          'SELECT id, relative_path AS path FROM $table '
          'WHERE id > ? ORDER BY id LIMIT ?',
          variables: <Variable<Object>>[
            Variable<String>(after),
            Variable<int>(AppConstants.lists.pageSize),
          ],
        )
        .get();
    if (rows.isEmpty) {
      break;
    }
    final List<String> paths = <String>[
      for (final QueryRow row in rows) row.read<String>('path'),
    ];
    final Set<String> missing = await _missingPathSet(paths);
    for (final QueryRow row in rows) {
      final String id = row.read<String>('id');
      after = id;
      final String path = row.read<String>('path');
      if (missing.contains(path)) {
        findings.add(_Finding(entityType: table, entityId: id, detail: detail));
      }
    }
  }
  return findings;
}

Future<Set<String>> _missingPathSet(List<String> paths) async {
  if (paths.isEmpty) {
    return const <String>{};
  }
  final Result<List<String>> result = await runIsolate(
    _pathsWhoseFilesAreMissing,
    paths,
  );
  return switch (result) {
    Success<List<String>>(:final List<String> value) => value.toSet(),
    FailureResult<List<String>>(:final Failure failure) => throw failure,
  };
}

Future<List<IntegrityFinding>> _foreignKeys(AppDatabase db) async {
  final List<QueryRow> rows = await db
      .customSelect('PRAGMA foreign_key_check')
      .get();
  final List<IntegrityFinding> findings = <IntegrityFinding>[];
  for (final QueryRow row in rows) {
    final String table = row.read<String>('table');
    final int rowid = row.read<int>('rowid');
    final QueryRow idRow = await db
        .customSelect(
          'SELECT id FROM "$table" WHERE rowid = ?',
          variables: <Variable<Object>>[Variable<int>(rowid)],
        )
        .getSingle();
    findings.add(
      _Finding(
        entityType: table,
        entityId: idRow.read<String>('id'),
        detail: 'A foreign key on this row does not resolve.',
      ),
    );
  }
  return findings;
}

/// Paths in [paths] that are empty or do not exist on disk.
List<String> _pathsWhoseFilesAreMissing(List<String> paths) {
  return <String>[
    for (final String path in paths)
      if (path.isEmpty || !File(path).existsSync()) path,
  ];
}

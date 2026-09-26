import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/processing.dart' as jobs;
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/projects/projects.dart'
    show ProjectSettings, appProjectSettingsDefaults;
import 'package:tapture/features/settings/settings.dart';

import '../domain/processing_repository.dart';
import 'processing_job_mapper.dart';

/// The read-only queries behind the queue screen: counts, context groups,
/// failures and today's online usage. Counts come from SQL, so the queue
/// is never materialised to draw the screen.
final class ProcessingQueueQueries {
  /// Reads from [db]. [settings] supplies the daily request cap shown
  /// beside today's usage when no project sets its own.
  const ProcessingQueueQueries({
    required this._db,
    required this._clock,
    required this._settings,
  });

  final sqlite.AppDatabase _db;
  final Clock _clock;
  final SettingsStore _settings;

  /// How many jobs are in [status], optionally within [projectId].
  Future<int> count(
    jobs.ProcessingJobStatus status, {
    String? projectId,
  }) async {
    final String projectFilter = projectId == null
        ? ''
        : ' AND EXISTS (SELECT 1 FROM records r '
              'WHERE r.id = processing_jobs.record_id AND r.project_id = ?)';
    final QueryRow row = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM processing_jobs WHERE status = ?'
          '$projectFilter',
          variables: <Variable<Object>>[
            Variable<String>(status.name),
            if (projectId != null) Variable<String>(projectId),
          ],
          readsFrom: <ResultSetImplementation<Object?, Object?>>{
            _db.processing,
            if (projectId != null) _db.records,
          },
        )
        .getSingle();
    return row.read<int>('c');
  }

  /// Counts, groups, failures and usage for the queue screen.
  Future<QueueSnapshot> snapshot({String? projectId}) async {
    final int queued = await count(
      jobs.ProcessingJobStatus.queued,
      projectId: projectId,
    );
    final int running = await count(
      jobs.ProcessingJobStatus.running,
      projectId: projectId,
    );
    final int failed = await count(
      jobs.ProcessingJobStatus.failed,
      projectId: projectId,
    );
    final int unprocessed = await _unprocessed(projectId: projectId);
    final List<sqlite.ProcessingJobRow> failedRows = await _failedRows(
      projectId: projectId,
    );
    final ({int requests, int images}) usage = await usageOn(
      _clock.nowUtc(),
      projectId: projectId,
    );
    return (
      unprocessed: unprocessed,
      queued: queued + running,
      failed: failed,
      requestsToday: usage.requests,
      imagesToday: usage.images,
      requestCap: await _requestCap(projectId),
      groups: await _groups(projectId: projectId),
      failures: <ProcessingJob>[
        for (final sqlite.ProcessingJobRow row in failedRows)
          ProcessingJobMapper.toJob(row),
      ],
    );
  }

  /// Online requests and images stored on the UTC day of [day].
  Future<({int requests, int images})> usageOn(
    DateTime day, {
    String? projectId,
  }) async {
    final DateTime start = DateTime.utc(day.year, day.month, day.day);
    final DateTime end = start.add(AppConstants.processing.dayWindow);
    final String projectFilter = projectId == null
        ? ''
        : 'AND r.project_id = ? ';
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT pr.request_summary FROM processing_results pr '
          'JOIN processing_jobs pj ON pj.id = pr.job_id '
          'JOIN records r ON r.id = pj.record_id '
          'WHERE pr.created_at >= ? AND pr.created_at < ? '
          '$projectFilter'
          'AND pr.request_summary LIKE ?',
          variables: <Variable<Object>>[
            Variable<DateTime>(start),
            Variable<DateTime>(end),
            if (projectId != null) Variable<String>(projectId),
            const Variable<String>('%"kind":"online"%'),
          ],
          readsFrom: <ResultSetImplementation<Object?, Object?>>{
            _db.processingResults,
            _db.processing,
            _db.records,
          },
        )
        .get();
    var images = 0;
    for (final QueryRow row in rows) {
      images += _imageCount(row.read<String>('request_summary'));
    }
    return (requests: rows.length, images: images);
  }

  /// The queue screen's label for a record's stored context: district,
  /// facility, department and room joined, or 'Unassigned'.
  static String contextLabel(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return 'Unassigned';
      }
      final List<String> parts = <String>[];
      for (final String key in const <String>[
        'district',
        'facility',
        'department',
        'room',
      ]) {
        final Object? value = decoded[key];
        if (value is String && value.isNotEmpty) {
          parts.add(value);
        }
      }
      if (parts.isEmpty) {
        return 'Unassigned';
      }
      return parts.join(' / ');
    } on FormatException {
      return 'Unassigned';
    }
  }

  /// The cap the online budget enforces: [projectId]'s own, else the app's.
  Future<int> _requestCap(String? projectId) async {
    final sqlite.Project? project = projectId == null
        ? null
        : await (_db.select(
                _db.projects,
              )..where((sqlite.$ProjectsTable tbl) => tbl.id.equals(projectId)))
              .getSingleOrNull();
    if (project == null) {
      return _settings.read(SettingKeys.aiDailyRequestCap);
    }
    return ProjectSettings.decode(
      project.settings,
    ).resolve(appProjectSettingsDefaults(_settings)).dailyRequestCap;
  }

  Future<int> _unprocessed({String? projectId}) async {
    final String projectFilter = projectId == null ? '' : 'AND project_id = ? ';
    final QueryRow row = await _db
        .customSelect(
          "SELECT COUNT(*) AS c FROM records "
          "WHERE status IN ('CAPTURED', 'captured') "
          '$projectFilter'
          "AND NOT EXISTS ("
          "SELECT 1 FROM processing_jobs "
          "WHERE processing_jobs.record_id = records.id)",
          variables: <Variable<Object>>[
            if (projectId != null) Variable<String>(projectId),
          ],
          readsFrom: <ResultSetImplementation<Object?, Object?>>{
            _db.records,
            _db.processing,
          },
        )
        .getSingle();
    return row.read<int>('c');
  }

  Future<List<QueueGroup>> _groups({String? projectId}) async {
    final String projectFilter = projectId == null ? '' : 'AND project_id = ? ';
    final List<QueryRow> rows = await _db
        .customSelect(
          "SELECT context_json AS label, COUNT(*) AS n FROM records r "
          "WHERE status IN ('CAPTURED', 'captured', 'queued') "
          '$projectFilter'
          "AND (NOT EXISTS (SELECT 1 FROM processing_jobs pj "
          "WHERE pj.record_id = r.id) OR EXISTS ("
          "SELECT 1 FROM processing_jobs pj WHERE pj.record_id = r.id "
          "AND pj.status IN ('queued', 'running'))) "
          "GROUP BY context_json",
          variables: <Variable<Object>>[
            if (projectId != null) Variable<String>(projectId),
          ],
          readsFrom: <ResultSetImplementation<Object?, Object?>>{_db.records},
        )
        .get();
    final Map<String, int> grouped = <String, int>{};
    for (final QueryRow row in rows) {
      final String label = contextLabel(row.read<String>('label'));
      grouped.update(
        label,
        (int count) => count + row.read<int>('n'),
        ifAbsent: () => row.read<int>('n'),
      );
    }
    return <QueueGroup>[
      for (final MapEntry<String, int> entry in grouped.entries)
        (label: entry.key, records: entry.value),
    ];
  }

  Future<List<sqlite.ProcessingJobRow>> _failedRows({String? projectId}) async {
    final JoinedSelectStatement<HasResultSet, Object?> query = _db
        .select(_db.processing)
        .join(<Join<HasResultSet, Object?>>[
          innerJoin(
            _db.records,
            _db.records.id.equalsExp(_db.processing.recordId),
          ),
        ]);
    query.where(
      _db.processing.status.equalsValue(jobs.ProcessingJobStatus.failed) &
          (projectId == null
              ? const Constant<bool>(true)
              : _db.records.projectId.equals(projectId)),
    );
    query.orderBy(<OrderingTerm>[OrderingTerm.asc(_db.processing.queuedAt)]);
    final List<TypedResult> rows = await query.get();
    return <sqlite.ProcessingJobRow>[
      for (final TypedResult row in rows) row.readTable(_db.processing),
    ];
  }
}

int _imageCount(String summary) {
  try {
    final Object? decoded = jsonDecode(summary);
    if (decoded is Map && decoded['images'] is List) {
      return (decoded['images'] as List).length;
    }
    if (decoded is Map && decoded['imageCount'] is int) {
      return decoded['imageCount'] as int;
    }
  } on FormatException {
    return 0;
  }
  return 0;
}

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/record_schema.dart';
import 'package:tapture/core/db/tables/processing.dart' as jobs;
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/projects/projects.dart'
    show ProjectSettings, appProjectSettingsDefaults;
import 'package:tapture/features/settings/settings.dart';

import '../domain/processing_repository.dart';
import 'processing_job_mapper.dart';
import 'processing_usage.dart';

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
        : ' AND r.project_id = ?';
    final QueryRow row = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM processing_jobs pj '
          'JOIN records r ON r.id = pj.record_id '
          'WHERE pj.status = ? AND $_liveJob AND $_liveRecord'
          '$projectFilter',
          variables: <Variable<Object>>[
            Variable<String>(status.name),
            if (projectId != null) Variable<String>(projectId),
          ],
          readsFrom: <ResultSetImplementation<Object?, Object?>>{
            _db.processing,
            _db.records,
            _db.tombstones,
          },
        )
        .getSingle();
    return row.read<int>('c');
  }

  /// Counts, groups and usage for the queue screen; failure rows are paged.
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
    );
  }

  /// Online requests and images stored on the UTC day of [day].
  Future<({int requests, int images})> usageOn(
    DateTime day, {
    String? projectId,
  }) async {
    final usage = (await ProcessingUsage(
      db: _db,
      settings: _settings,
    ).on(day, projectId: projectId)).getOrThrow();
    return (requests: usage.requests, images: usage.images);
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
    final String projectFilter = projectId == null
        ? ''
        : 'AND r.project_id = ? ';
    final QueryRow row = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM records r '
          'WHERE r.status = ? AND $_liveRecord '
          '$projectFilter'
          'AND NOT EXISTS ('
          'SELECT 1 FROM processing_jobs '
          'WHERE processing_jobs.record_id = r.id AND '
          "NOT EXISTS (SELECT 1 FROM tombstones t WHERE t.entity_type = 'processing_jobs' "
          'AND t.entity_id = processing_jobs.id))',
          variables: <Variable<Object>>[
            Variable<String>(RecordStatus.captured.stored),
            if (projectId != null) Variable<String>(projectId),
          ],
          readsFrom: <ResultSetImplementation<Object?, Object?>>{
            _db.records,
            _db.processing,
            _db.tombstones,
          },
        )
        .getSingle();
    return row.read<int>('c');
  }

  Future<List<QueueGroup>> _groups({String? projectId}) async {
    final String projectFilter = projectId == null
        ? ''
        : 'AND r.project_id = ? ';
    final String waiting = List<String>.filled(
      _waitingStatuses.length,
      '?',
    ).join(', ');
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT context_json AS label, COUNT(*) AS n FROM records r '
          'WHERE r.status IN ($waiting) AND $_liveRecord '
          '$projectFilter'
          "AND (NOT EXISTS (SELECT 1 FROM processing_jobs pj "
          "WHERE pj.record_id = r.id AND $_liveJob) OR EXISTS ("
          "SELECT 1 FROM processing_jobs pj WHERE pj.record_id = r.id "
          "AND pj.status IN ('queued', 'running') AND $_liveJob)) "
          "GROUP BY context_json",
          variables: <Variable<Object>>[
            for (final RecordStatus status in _waitingStatuses)
              Variable<String>(status.stored),
            if (projectId != null) Variable<String>(projectId),
          ],
          readsFrom: <ResultSetImplementation<Object?, Object?>>{
            _db.records,
            _db.processing,
            _db.tombstones,
          },
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

  /// A bounded live page; literal status matches the partial queued_at/id
  /// index. Reading limit+1 determines continuation without a count scan.
  Stream<QueueFailurePage> watchFailurePage({
    String? projectId,
    QueueFailureCursor? after,
    int limit = AppConstants.listPageSize,
  }) {
    final int size = limit.clamp(1, AppConstants.listPageSize);
    return _db
        .customSelect(
          'SELECT pj.*, r.record_number AS queue_number, '
          "COALESCE(sd.sort_name, '') AS queue_name "
          'FROM processing_jobs pj JOIN records r ON r.id = pj.record_id '
          'LEFT JOIN ${RecordSchema.searchDocsTable} sd ON sd.record_id = r.id '
          "WHERE pj.status = 'failed' AND $_liveJob AND $_liveRecord "
          '${projectId == null ? '' : 'AND r.project_id = ? '}'
          '${after == null ? '' : 'AND (pj.queued_at, pj.id) > (?, ?) '}'
          'ORDER BY pj.queued_at ASC, pj.id ASC LIMIT ?',
          variables: <Variable<Object>>[
            if (projectId != null) Variable<String>(projectId),
            if (after != null) ...<Variable<Object>>[
              Variable<DateTime>(after.queuedAt),
              Variable<String>(after.id),
            ],
            Variable<int>(size + 1),
          ],
          readsFrom: <ResultSetImplementation<Object?, Object?>>{
            _db.processing,
            _db.records,
            _db.recordFields,
            _db.tombstones,
          },
        )
        .watch()
        .map((List<QueryRow> rows) {
          final List<QueueFailure> failures = <QueueFailure>[
            for (final QueryRow row in rows.take(size))
              (
                job: ProcessingJobMapper.toJob(_db.processing.map(row.data)),
                name: row.read<String>('queue_name'),
                number: row.read<int?>('queue_number'),
              ),
          ];
          final ProcessingJob? last = failures.isEmpty
              ? null
              : failures.last.job;
          return QueueFailurePage(
            items: failures,
            nextCursor: rows.length > size && last != null
                ? (queuedAt: last.queuedAt!, id: last.id)
                : null,
          );
        });
  }
}

const String _liveJob =
    "NOT EXISTS (SELECT 1 FROM tombstones t "
    "WHERE t.entity_type = 'processing_jobs' AND t.entity_id = pj.id)";
const String _liveRecord =
    "r.status != 'deleted' AND NOT EXISTS ("
    "SELECT 1 FROM tombstones t WHERE t.entity_type = 'records' AND t.entity_id = r.id)";

/// Record statuses whose records wait on the queue: captured without a job,
/// or queued or processing with one still to run.
const List<RecordStatus> _waitingStatuses = <RecordStatus>[
  RecordStatus.captured,
  RecordStatus.queued,
  RecordStatus.processing,
];

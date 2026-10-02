import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/constants/app_constants.dart';

import 'bundle_format.dart';
import 'bundle_json.dart';
import 'bundle_vectors.dart';

/// Every row a project package carries, per SQL table, each row keyed by
/// column name with the value as the database stores it (task 076, D7).
///
/// It holds the project row and its settings, context levels and presets,
/// templates with their fields and rows, the project's reference datasets
/// and the global ones its fields or levels look up, records and their field
/// values and evidence, captions, photos, attachments and their owners,
/// meetings, attendees and actions, variances, finished processing jobs and
/// their results, duplicate pairs, audit rows and tombstones. It leaves out
/// capture drafts, the processing queue, the OCR cache, export history,
/// merge bookkeeping and the device profile. Causal clocks travel in the
/// manifest rather than in a table entry.
final class BundleTables {
  /// Creates tables from [rows].
  const BundleTables(
    this.rows, {
    this.vectorRows = const <Map<String, Object?>>[],
  });

  /// Rows by SQL table name. A table with no rows maps to an empty list.
  final Map<String, List<Map<String, Object?>>> rows;

  /// Stored clocks, filtered to the selected entities by [versionVectors].
  final List<Map<String, Object?>> vectorRows;

  /// Rows with entity clocks for planning, never for table serialization.
  Map<String, List<Map<String, Object?>>> get mergeRows =>
      <String, List<Map<String, Object?>>>{
        ...rows,
        'version_vectors': BundleVectors.rows(versionVectors),
      };

  /// Clocks only for rows in this snapshot, including scoped exports.
  BundleVersionVectors get versionVectors {
    final BundleVersionVectors vectors =
        <String, Map<String, Map<String, int>>>{};
    for (final table in rows.entries) {
      if (!BundleFormat.insertOrder.contains(table.key)) continue;
      final Map<String, Map<String, int>> entities =
          <String, Map<String, int>>{};
      for (final Map<String, Object?> row in table.value) {
        final String id = row['id']! as String;
        final Object? device = row['updated_by_device'];
        final Object? rev = row['rev'];
        entities[id] = <String, int>{
          if (device is String && device.isNotEmpty && rev is int && rev > 0)
            device: rev,
        };
      }
      vectors[table.key] = entities;
    }
    final Set<String> stored = <String>{};
    for (final Map<String, Object?> row in vectorRows) {
      final Map<String, int>? counters =
          vectors[row['entity_type']]?[row['entity_id']];
      if (counters == null) continue;
      final String device = row['device_id']! as String;
      final int rev = row['seen_rev']! as int;
      // A stored clock is authoritative; row.rev is only the migration
      // fallback for an entity with no historical vector on this device.
      if (stored.add('${row['entity_type']}/${row['entity_id']}')) {
        counters.clear();
      }
      counters[device] = rev;
    }
    return vectors;
  }

  /// Reads the rows of project [projectId] from [db], or null when there is
  /// no such project. Tombstoned rows travel with their tombstones.
  static Future<BundleTables?> read(
    GeneratedDatabase db,
    String projectId,
  ) async {
    Future<List<Map<String, Object?>>> select(
      String sql, [
      List<Variable<Object>> extra = const <Variable<Object>>[],
    ]) async {
      final List<QueryRow> result = await db
          .customSelect(
            sql,
            variables: <Variable<Object>>[
              Variable<String>(projectId),
              ...extra,
            ],
          )
          .get();
      return <Map<String, Object?>>[
        for (final QueryRow row in result) Map<String, Object?>.of(row.data),
      ];
    }

    final List<Map<String, Object?>> project = await select(
      'SELECT * FROM projects WHERE id = ?1',
    );
    if (project.isEmpty) {
      return null;
    }
    final Map<String, List<Map<String, Object?>>> rows =
        <String, List<Map<String, Object?>>>{
          'projects': project,
          for (final MapEntry<String, String> query in _byProject.entries)
            query.key: await select(query.value),
        };
    final Set<String> datasets = <String>{
      for (final Map<String, Object?> field in rows['template_fields']!)
        ?_datasetOf(field['lookup']),
      for (final Map<String, Object?> level in rows['context_definitions']!)
        ?_datasetOf(level['label']),
    };
    final List<String> referenced = datasets.toList()..sort();
    final String listed = referenced.isEmpty
        ? ''
        : ' OR id IN (${<String>[for (int i = 0; i < referenced.length; i++) '?${i + 2}'].join(', ')})';
    final List<Variable<Object>> ids = <Variable<Object>>[
      for (final String id in referenced) Variable<String>(id),
    ];
    rows['reference_datasets'] = await select(
      'SELECT * FROM reference_datasets WHERE project_id = ?1$listed '
      'ORDER BY id',
      ids,
    );
    rows['reference_rows'] = await select(
      'SELECT * FROM reference_rows WHERE dataset_id IN '
      '(SELECT id FROM reference_datasets WHERE project_id = ?1$listed) '
      'ORDER BY dataset_id, id',
      ids,
    );
    final List<String> owned = <String>{
      for (final List<Map<String, Object?>> table in rows.values)
        for (final Map<String, Object?> row in table) row['id']! as String,
    }.toList();
    final List<Map<String, Object?>> vectors = <Map<String, Object?>>[];
    for (int offset = 0; offset < owned.length; offset += 500) {
      final List<String> chunk = owned.sublist(
        offset,
        offset + 500 < owned.length ? offset + 500 : owned.length,
      );
      final List<QueryRow> selected = await db
          .customSelect(
            'SELECT * FROM version_vectors WHERE entity_id IN '
            '(${List<String>.filled(chunk.length, '?').join(', ')})',
            variables: <Variable<Object>>[
              for (final String id in chunk) Variable<String>(id),
            ],
          )
          .get();
      vectors.addAll(
        selected.map((QueryRow row) => Map<String, Object?>.of(row.data)),
      );
    }
    return BundleTables(rows, vectorRows: vectors);
  }

  /// The project's folder name under `projects/`.
  String get folderName => rows['projects']!.single['folder_name']! as String;

  /// Every file a row points at, by its path inside the project folder:
  /// photos, attachments such as audio, and the cover photo.
  List<String> get filePaths {
    final Set<String> paths = <String>{
      for (final Map<String, Object?> photo in rows['photos']!)
        photo['relative_path']! as String,
      for (final Map<String, Object?> file in rows['attachments']!)
        file['relative_path']! as String,
      ?coverPath,
    };
    return paths.toList()..sort();
  }

  /// The cover photo's path inside the project folder, when one is set.
  String? get coverPath {
    final Object? settings = rows['projects']!.single['settings'];
    final Object? cover = _decode(settings)?['coverPhoto'];
    if (cover is! Map<String, Object?>) {
      return null;
    }
    final Object? path = cover['path'];
    final String prefix = 'projects/$folderName/';
    if (path is! String || !path.startsWith(prefix)) {
      return null;
    }
    return path.substring(prefix.length);
  }

  /// Bytes the files [filePaths] name are expected to take, from the sizes
  /// the rows recorded; the cover photo counts as nothing.
  int get recordedFileBytes {
    var total = 0;
    for (final Map<String, Object?> row in <Map<String, Object?>>[
      ...rows['photos']!,
      ...rows['attachments']!,
    ]) {
      final Object? size = row['file_size'];
      if (size is int) {
        total += size;
      }
    }
    return total;
  }

  /// The JSON entries of the package: one per group in
  /// [BundleFormat.tableEntries], then one per reference dataset under
  /// [BundleFormat.referenceFolder].
  Map<String, List<int>> encode() {
    final Map<String, List<int>> encoded = <String, List<int>>{};
    int remaining = AppConstants.bundles.metadataMaxBytes;
    void add(String path, Object value) {
      final List<int> bytes = BundleJson.encode(value, maximum: remaining);
      remaining -= bytes.length;
      encoded[path] = bytes;
    }

    for (final MapEntry<String, List<String>> entry
        in BundleFormat.tableEntries.entries) {
      add(entry.key, <String, Object?>{
        for (final String table in entry.value)
          table: rows[table] ?? const <Map<String, Object?>>[],
      });
    }
    for (final Map<String, Object?> dataset in rows['reference_datasets']!) {
      add(
        '${BundleFormat.referenceFolder}${dataset['id']}.json',
        <String, Object?>{
          'reference_datasets': <Map<String, Object?>>[dataset],
          'reference_rows': <Map<String, Object?>>[
            for (final Map<String, Object?> row in rows['reference_rows']!)
              if (row['dataset_id'] == dataset['id']) row,
          ],
        },
      );
    }
    return encoded;
  }

  /// Rows per table, for the manifest.
  Map<String, int> get counts => <String, int>{
    for (final MapEntry<String, List<Map<String, Object?>>> table
        in rows.entries)
      table.key: table.value.length,
  };
}

/// Every table but the project row and reference data, each selected by
/// the project id bound as `?1`.
const Map<String, String> _byProject = <String, String>{
  'context_definitions':
      'SELECT * FROM context_definitions WHERE project_id = ?1 ORDER BY level, id',
  'context_presets':
      'SELECT * FROM context_presets WHERE project_id = ?1 ORDER BY id',
  'templates': 'SELECT * FROM templates WHERE project_id = ?1 ORDER BY id',
  'template_fields':
      'SELECT * FROM template_fields WHERE template_id IN $_templates '
      'ORDER BY template_id, sort_order, id',
  'template_rows':
      'SELECT * FROM template_rows WHERE template_id IN $_templates '
      'ORDER BY template_id, output_row_number, id',
  'records': 'SELECT * FROM records WHERE project_id = ?1 ORDER BY id',
  'record_fields':
      'SELECT * FROM record_fields WHERE record_id IN $_records '
      'ORDER BY record_id, id',
  'field_evidence':
      'SELECT * FROM field_evidence WHERE record_field_id IN '
      '(SELECT id FROM record_fields WHERE record_id IN $_records) ORDER BY id',
  'photos': 'SELECT * FROM photos WHERE project_id = ?1 ORDER BY id',
  'attachments': 'SELECT * FROM attachments WHERE project_id = ?1 ORDER BY id',
  'attachment_owners':
      'SELECT * FROM attachment_owners WHERE attachment_id IN '
      '(SELECT id FROM attachments WHERE project_id = ?1) ORDER BY id',
  'captions':
      'SELECT * FROM captions WHERE owner_id IN $_records OR owner_id IN '
      '(SELECT id FROM photos WHERE project_id = ?1) ORDER BY id',
  'meetings': 'SELECT * FROM meetings WHERE record_id IN $_records ORDER BY id',
  'attendees':
      'SELECT * FROM attendees WHERE meeting_id IN $_meetings ORDER BY id',
  'meeting_actions':
      'SELECT * FROM meeting_actions WHERE meeting_id IN $_meetings ORDER BY id',
  'variances': 'SELECT * FROM variances WHERE project_id = ?1 ORDER BY id',
  // Finished jobs are history; a job still queued or running is this
  // device's queue and stays behind (D7).
  'processing_jobs':
      'SELECT * FROM processing_jobs WHERE finished_at IS NOT NULL AND '
      'record_id IN $_records ORDER BY id',
  'processing_results':
      'SELECT * FROM processing_results WHERE job_id IN (SELECT id FROM '
      'processing_jobs WHERE finished_at IS NOT NULL AND record_id IN '
      '$_records) ORDER BY id',
  'duplicates': 'SELECT * FROM duplicates WHERE project_id = ?1 ORDER BY id',
  'audit_log':
      'SELECT * FROM audit_log WHERE entity_id IN ($_owned) ORDER BY at, id',
  'tombstones':
      'SELECT * FROM tombstones WHERE entity_id IN ($_owned) ORDER BY id',
};

const String _templates = '(SELECT id FROM templates WHERE project_id = ?1)';
const String _records = '(SELECT id FROM records WHERE project_id = ?1)';
const String _meetings =
    '(SELECT id FROM meetings WHERE record_id IN $_records)';

/// Every id a package carries, for the audit rows and tombstones about them.
const String _owned =
    'SELECT ?1 '
    'UNION ALL SELECT id FROM context_definitions WHERE project_id = ?1 '
    'UNION ALL SELECT id FROM context_presets WHERE project_id = ?1 '
    'UNION ALL SELECT id FROM templates WHERE project_id = ?1 '
    'UNION ALL SELECT id FROM template_fields WHERE template_id IN $_templates '
    'UNION ALL SELECT id FROM template_rows WHERE template_id IN $_templates '
    'UNION ALL SELECT id FROM records WHERE project_id = ?1 '
    'UNION ALL SELECT id FROM record_fields WHERE record_id IN $_records '
    'UNION ALL SELECT id FROM photos WHERE project_id = ?1 '
    'UNION ALL SELECT id FROM attachments WHERE project_id = ?1 '
    'UNION ALL SELECT id FROM captions WHERE owner_id IN $_records '
    'UNION ALL SELECT id FROM meetings WHERE record_id IN $_records '
    'UNION ALL SELECT id FROM variances WHERE project_id = ?1 '
    'UNION ALL SELECT id FROM duplicates WHERE project_id = ?1 '
    'UNION ALL SELECT id FROM reference_datasets WHERE project_id = ?1';

/// The reference dataset a template field's lookup or a context level's
/// packed label names, or null.
String? _datasetOf(Object? raw) {
  final Object? id = _decode(raw)?['datasetId'];
  return id is String && id.isNotEmpty ? id : null;
}

Map<String, Object?>? _decode(Object? raw) {
  if (raw is! String || !raw.trimLeft().startsWith('{')) {
    return null;
  }
  try {
    final Object? value = jsonDecode(raw);
    return value is Map<String, Object?> ? value : null;
  } on FormatException {
    return null;
  }
}

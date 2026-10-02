import 'dart:convert';

import 'package:tapture/core/security/coordinate_policy.dart';

import 'bundle_tables.dart';

/// Outbound snapshot policy. Stored source rows and files remain unchanged.
final class BundlePrivacy {
  /// Creates an export-only snapshot policy.
  const BundlePrivacy({
    required this.recordIds,
    this.excludeCoordinates = true,
    this.photoRows = const <String, Map<String, Object?>>{},
    this.fileSources = const <String, String>{},
  });

  /// Records allowed by live consent and the selected scope.
  final Set<String> recordIds;

  /// Whether location columns and their recorded history stay on this device.
  final bool excludeCoordinates;

  /// Safe file metadata replacing original photo rows in this snapshot only.
  final Map<String, Map<String, Object?>> photoRows;

  /// Archive-relative photo paths mapped to protected storage derivatives.
  final Map<String, String> fileSources;

  /// Removes excluded owners and location data without changing source rows.
  BundleTables apply(BundleTables source) {
    final Map<String, List<Map<String, Object?>>> rows =
        <String, List<Map<String, Object?>>>{
          for (final MapEntry<String, List<Map<String, Object?>>> table
              in source.rows.entries)
            table.key: table.value.map(Map<String, Object?>.of).toList(),
        };
    void keep(String table, bool Function(Map<String, Object?>) include) {
      rows[table] = (rows[table] ?? <Map<String, Object?>>[])
          .where(include)
          .toList();
    }

    Set<Object?> ids(String table) =>
        rows[table]!.map((Map<String, Object?> row) => row['id']).toSet();
    keep(
      'records',
      (Map<String, Object?> row) => recordIds.contains(row['id']),
    );
    for (final String table in <String>[
      'record_fields',
      'meetings',
      'variances',
      'processing_jobs',
    ]) {
      keep(
        table,
        (Map<String, Object?> row) => recordIds.contains(row['record_id']),
      );
    }
    final Set<Object?> fields = ids('record_fields');
    final Set<Object?> meetings = ids('meetings');
    final Set<Object?> jobs = ids('processing_jobs');
    keep(
      'field_evidence',
      (Map<String, Object?> row) => fields.contains(row['record_field_id']),
    );
    for (final String table in <String>['attendees', 'meeting_actions']) {
      keep(
        table,
        (Map<String, Object?> row) => meetings.contains(row['meeting_id']),
      );
    }
    keep(
      'processing_results',
      (Map<String, Object?> row) => jobs.contains(row['job_id']),
    );
    keep(
      'duplicates',
      (Map<String, Object?> row) =>
          recordIds.contains(row['left_record_id']) &&
          recordIds.contains(row['right_record_id']),
    );
    // Photos with no exported live owner, including retired originals, must
    // not bypass the consent check or reappear beside their protected copy.
    keep(
      'photos',
      (Map<String, Object?> row) => photoRows.containsKey(row['id']),
    );
    rows['photos'] = <Map<String, Object?>>[
      for (final Map<String, Object?> row in rows['photos']!)
        <String, Object?>{...row, ...photoRows[row['id']]!},
    ];
    final Set<Object?> photos = ids('photos');
    for (final Map<String, Object?> evidence in rows['field_evidence']!) {
      if (evidence['photo_id'] != null &&
          !photos.contains(evidence['photo_id'])) {
        evidence['photo_id'] = null;
      }
    }
    keep(
      'captions',
      (Map<String, Object?> row) =>
          recordIds.contains(row['owner_id']) ||
          photos.contains(row['owner_id']),
    );
    keep(
      'attachment_owners',
      (Map<String, Object?> row) =>
          row['owner_type'] == 'project' || recordIds.contains(row['owner_id']),
    );
    final Set<Object?> attachments = rows['attachment_owners']!
        .map((Map<String, Object?> row) => row['attachment_id'])
        .toSet();
    keep(
      'attachments',
      (Map<String, Object?> row) => attachments.contains(row['id']),
    );
    final Set<Object?> owned = <Object?>{
      for (final MapEntry<String, List<Map<String, Object?>>> table
          in rows.entries)
        if (table.key != 'audit_log' && table.key != 'tombstones')
          for (final Map<String, Object?> row in table.value) row['id'],
    };
    keep(
      'audit_log',
      (Map<String, Object?> row) => owned.contains(row['entity_id']),
    );
    keep(
      'tombstones',
      (Map<String, Object?> row) => owned.contains(row['entity_id']),
    );
    // Covers bypass photo ownership. Export only the protected live photos.
    for (final Map<String, Object?> project in rows['projects']!) {
      final Object? settings = jsonDecode(project['settings']! as String);
      if (settings is Map) {
        final Map<String, Object?> safe = Map<String, Object?>.from(settings)
          ..remove('coverPhoto');
        project['settings'] = jsonEncode(safe);
      }
    }
    if (excludeCoordinates) _stripCoordinates(rows);
    return BundleTables(rows, vectorRows: source.vectorRows);
  }
}

void _stripCoordinates(Map<String, List<Map<String, Object?>>> rows) {
  final Map<String, Set<String>> current = <String, Set<String>>{};
  final Map<String, Set<String>> defined = <String, Set<String>>{};
  final Set<Object?> retiredDefinitions = <Object?>{
    for (final Map<String, Object?> row in rows['tombstones']!)
      if (row['entity_type'] == 'template_fields') row['entity_id'],
  };
  for (final Map<String, Object?> field in rows['template_fields']!) {
    if (retiredDefinitions.contains(field['id'])) continue;
    (defined[field['template_id']! as String] ??= <String>{}).add(
      field['field_key']! as String,
    );
    if (CoordinatePolicy.isField(
      key: field['field_key']! as String,
      type: field['type'] as String?,
      validation: field['validation'] as String?,
    )) {
      (current[field['template_id']! as String] ??= <String>{}).add(
        field['field_key']! as String,
      );
    }
  }
  final Map<String, Map<String, Object?>> templates =
      <String, Map<String, Object?>>{
        for (final Map<String, Object?> template in rows['templates']!)
          template['id']! as String: template,
      };
  final Map<String, Map<int, Set<String>>> history =
      <String, Map<int, Set<String>>>{
        for (final MapEntry<String, Map<String, Object?>> template
            in templates.entries)
          template.key: CoordinatePolicy.historicalFieldVersions(
            template.value['detection'],
          ),
      };
  for (final String id in templates.keys) {
    current[id] = CoordinatePolicy.withRetiredFields(
      current: current[id] ?? const <String>{},
      defined: defined[id] ?? const <String>{},
      history: history[id]!,
    );
  }
  final Map<Object?, Set<int>> origins = <Object?, Set<int>>{};
  for (final Map<String, Object?> audit in rows['audit_log']!) {
    if (audit['entity_type'] != 'records' ||
        audit['field_key'] != 'template_version') {
      continue;
    }
    final int? version = int.tryParse('${audit['previous_value'] ?? ''}');
    if (version != null && version >= 0) {
      (origins[audit['entity_id']] ??= <int>{}).add(version);
    }
  }
  final Map<Object?, Set<String>> recordKeys = <Object?, Set<String>>{
    for (final Map<String, Object?> record in rows['records']!)
      record['id']: CoordinatePolicy.withMigrationHistory(
        current: CoordinatePolicy.forVersion(
          current: current[record['template_id']] ?? const <String>{},
          history: history[record['template_id']] ?? const <int, Set<String>>{},
          currentVersion:
              templates[record['template_id']]?['version'] as int? ?? 1,
          capturedVersion: record['template_version'] as int?,
        ),
        history: history[record['template_id']] ?? const <int, Set<String>>{},
        currentVersion:
            templates[record['template_id']]?['version'] as int? ?? 1,
        previousVersions: origins[record['id']] ?? const <int>{},
      ),
  };
  final Set<String> keys = <String>{
    for (final Set<String> fields in recordKeys.values) ...fields,
  };
  final Set<Object?> removedFields = <Object?>{
    for (final Map<String, Object?> field in rows['record_fields']!)
      if (CoordinatePolicy.isKey(field['field_key']! as String) ||
          (recordKeys[field['record_id']]?.contains(field['field_key']) ??
              false))
        field['id'],
  };
  rows['record_fields']!.removeWhere(
    (Map<String, Object?> row) => removedFields.contains(row['id']),
  );
  rows['field_evidence']!.removeWhere(
    (Map<String, Object?> row) =>
        removedFields.contains(row['record_field_id']),
  );
  rows['variances']!.removeWhere(
    (Map<String, Object?> row) =>
        CoordinatePolicy.isKey(row['field_key'] as String? ?? '') ||
        (recordKeys[row['record_id']]?.contains(row['field_key']) ?? false),
  );
  for (final MapEntry<String, List<Map<String, Object?>>> table
      in rows.entries) {
    for (final Map<String, Object?> row in table.value) {
      final Set<String> scopedKeys =
          recordKeys[table.key == 'records' ? row['id'] : row['record_id']] ??
          keys;
      for (final String key in <String>[
        'gps_lat',
        'gps_lon',
        'gpsLat',
        'gpsLon',
        'latitude',
        'longitude',
      ]) {
        if (row.containsKey(key)) row[key] = null;
      }
      for (final String column in <String>[
        'context_json',
        'path_json',
        'values',
        'settings',
      ]) {
        final Object? raw = row[column];
        if (raw is String && raw.isNotEmpty) {
          row[column] = jsonEncode(_strip(jsonDecode(raw), scopedKeys));
        }
      }
    }
  }
  final Map<Object?, Object?> fieldRecords = <Object?, Object?>{
    for (final Map<String, Object?> field in rows['record_fields']!)
      field['id']: field['record_id'],
  };
  final Map<Object?, Object?> photoRecords = <Object?, Object?>{
    for (final Map<String, Object?> photo in rows['photos']!)
      photo['id']: photo['record_id'],
  };
  for (final Map<String, Object?> audit in rows['audit_log']!) {
    final String key = audit['field_key'] as String? ?? '';
    final Object? recordId = switch (audit['entity_type']) {
      'records' => audit['entity_id'],
      'record_fields' => fieldRecords[audit['entity_id']],
      'photos' => photoRecords[audit['entity_id']],
      _ => null,
    };
    final Set<String> scopedKeys = recordKeys[recordId] ?? keys;
    if (scopedKeys.contains(key) ||
        CoordinatePolicy.isKey(key) ||
        removedFields.contains(audit['entity_id'])) {
      audit['previous_value'] = null;
      audit['new_value'] = null;
    } else {
      for (final String value in <String>['previous_value', 'new_value']) {
        final Object? raw = audit[value];
        if (raw is! String) continue;
        try {
          audit[value] = jsonEncode(_strip(jsonDecode(raw), scopedKeys));
        } on FormatException {
          /* Plain text does not carry typed coordinates. */
        }
      }
    }
  }
}

Object? _strip(Object? value, Set<String> fields) {
  if (value is List) {
    return value.map((Object? item) => _strip(item, fields)).toList();
  }
  if (value is! Map) return value;
  return <String, Object?>{
    for (final MapEntry<Object?, Object?> item in value.entries)
      if (!fields.contains(item.key) &&
          !CoordinatePolicy.isKey(item.key! as String))
        item.key! as String: _strip(item.value, fields),
  };
}

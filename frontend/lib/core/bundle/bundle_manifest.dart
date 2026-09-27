import 'bundle_entry.dart';
import 'bundle_format.dart';

/// A project package's `manifest.json`: who wrote it, when, from which
/// project, what it counts, which templates it carries and the checksum of
/// every entry (specification §45.1).
final class BundleManifest {
  /// Creates a manifest.
  const BundleManifest({
    required this.formatVersion,
    required this.appVersion,
    required this.schemaVersion,
    required this.bundleId,
    required this.projectId,
    required this.projectName,
    required this.folderName,
    required this.exportedAt,
    required this.sourceDeviceId,
    required this.counts,
    required this.lineage,
    required this.templates,
    required this.entries,
    this.operatorName,
    this.missingFiles = const <String>[],
    this.format = BundleFormat.name,
  });

  /// Reads a manifest. Throws [FormatException] naming what is wrong when a
  /// field is missing or of the wrong type; the values are data, never
  /// instructions (FE-SEC-05).
  factory BundleManifest.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('The manifest is not an object.');
    }
    return BundleManifest(
      format: _string(json, 'format'),
      formatVersion: _int(json, 'format_version'),
      appVersion: _string(json, 'app_version'),
      schemaVersion: _int(json, 'schema_version'),
      bundleId: _string(json, 'bundle_id'),
      projectId: _string(json, 'project_id'),
      projectName: _string(json, 'project_name'),
      folderName: _string(json, 'folder_name'),
      exportedAt: DateTime.parse(_string(json, 'exported_at')).toUtc(),
      sourceDeviceId: _string(json, 'exported_by_device'),
      operatorName: json['exported_by_operator'] as String?,
      counts: <String, int>{
        for (final MapEntry<String, Object?> count in _map(
          json,
          'counts',
        ).entries)
          count.key: count.value is int
              ? count.value! as int
              : throw const FormatException('A count is not a number.'),
      },
      lineage: <({String device, DateTime at})>[
        for (final Object? step in _list(json, 'lineage'))
          (
            device: _string(_object(step), 'device'),
            at: DateTime.parse(_string(_object(step), 'at')).toUtc(),
          ),
      ],
      templates: <BundleTemplateSummary>[
        for (final Object? template in _list(json, 'templates'))
          (
            id: _string(_object(template), 'id'),
            templateKey: _string(_object(template), 'template_key'),
            version: _int(_object(template), 'version'),
            fields: <String, String>{
              for (final MapEntry<String, Object?> field in _map(
                _object(template),
                'fields',
              ).entries)
                field.key: field.value is String
                    ? field.value! as String
                    : throw const FormatException('A field type is missing.'),
            },
          ),
      ],
      entries: <BundleEntry>[
        for (final Object? entry in _list(json, 'entries'))
          BundleEntry.fromJson(entry),
      ],
      missingFiles: <String>[
        for (final Object? path in _list(json, 'missing_files'))
          path is String
              ? path
              : throw const FormatException('A missing file is not a path.'),
      ],
    );
  }

  /// Always [BundleFormat.name] for a package this app can read.
  final String format;

  /// The layout version this package was written in.
  final int formatVersion;

  /// The app version that wrote it.
  final String appVersion;

  /// The database schema version of the device that wrote it.
  final int schemaVersion;

  /// This package's own id, so a merge can tell one package from another.
  final String bundleId;

  /// The project it carries.
  final String projectId;

  /// The project's name when it was written.
  final String projectName;

  /// The project's folder name under `projects/` on the writing device.
  final String folderName;

  /// When it was written, in UTC.
  final DateTime exportedAt;

  /// The device that wrote it.
  final String sourceDeviceId;

  /// The operator named on that device, when one was set.
  final String? operatorName;

  /// Rows per table, and the files it carries under `files`.
  final Map<String, int> counts;

  /// The devices the project has passed through, oldest first, ending with
  /// the writer.
  final List<({String device, DateTime at})> lineage;

  /// Every template the package carries, with its fields' keys and types,
  /// so a compatibility check can run before the tables are read.
  final List<BundleTemplateSummary> templates;

  /// Every entry but the manifest itself, with its checksum.
  final List<BundleEntry> entries;

  /// Files a row pointed at that were not on the writing device.
  final List<String> missingFiles;

  /// The manifest form, keyed as specification §45.1 writes it.
  Map<String, Object?> toJson() => <String, Object?>{
    'format': format,
    'format_version': formatVersion,
    'app_version': appVersion,
    'schema_version': schemaVersion,
    'bundle_id': bundleId,
    'project_id': projectId,
    'project_name': projectName,
    'folder_name': folderName,
    'exported_at': exportedAt.toUtc().toIso8601String(),
    'exported_by_device': sourceDeviceId,
    'exported_by_operator': operatorName,
    'scope': 'FULL',
    'encrypted': false,
    'counts': counts,
    'lineage': <Map<String, Object?>>[
      for (final ({String device, DateTime at}) step in lineage)
        <String, Object?>{
          'device': step.device,
          'at': step.at.toUtc().toIso8601String(),
        },
    ],
    'templates': <Map<String, Object?>>[
      for (final BundleTemplateSummary template in templates)
        <String, Object?>{
          'id': template.id,
          'template_key': template.templateKey,
          'version': template.version,
          'fields': template.fields,
        },
    ],
    'entries': <Map<String, Object?>>[
      for (final BundleEntry entry in entries) entry.toJson(),
    ],
    'missing_files': missingFiles,
  };

  /// A copy with [entries] and [missingFiles] filled in, as the writer knows
  /// them only once every entry is written.
  BundleManifest withEntries(
    List<BundleEntry> entries, {
    List<String> missingFiles = const <String>[],
  }) {
    return BundleManifest(
      format: format,
      formatVersion: formatVersion,
      appVersion: appVersion,
      schemaVersion: schemaVersion,
      bundleId: bundleId,
      projectId: projectId,
      projectName: projectName,
      folderName: folderName,
      exportedAt: exportedAt,
      sourceDeviceId: sourceDeviceId,
      operatorName: operatorName,
      counts: counts,
      lineage: lineage,
      templates: templates,
      entries: entries,
      missingFiles: missingFiles,
    );
  }
}

/// One template a package carries: its id, stable key, version and each
/// field's type by key.
typedef BundleTemplateSummary = ({
  String id,
  String templateKey,
  int version,
  Map<String, String> fields,
});

Map<String, Object?> _object(Object? value) {
  if (value is! Map<String, Object?>) {
    throw const FormatException('A manifest value is not an object.');
  }
  return value;
}

String _string(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is! String) {
    throw FormatException('The manifest has no $key.');
  }
  return value;
}

int _int(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is! int) {
    throw FormatException('The manifest has no $key.');
  }
  return value;
}

Map<String, Object?> _map(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is! Map<String, Object?>) {
    throw FormatException('The manifest has no $key.');
  }
  return value;
}

List<Object?> _list(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is! List<Object?>) {
    throw FormatException('The manifest has no $key.');
  }
  return value;
}

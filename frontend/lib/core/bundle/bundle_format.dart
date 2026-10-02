/// The one definition of a project package's layout, so the writer and the
/// reader cannot drift apart (specification §45, task 019).
///
/// A package is a plain ZIP: `manifest.json`, one JSON entry per group of
/// tables below, `reference/<datasetId>.json` per reference dataset, every
/// file a row points at under its project-relative path (`photos/…`,
/// `audio/…`, `cover/…`), the operator's workbook `records.xlsx`, and
/// `checksums.txt`. Each JSON entry maps a SQL table name to its rows, each
/// row an object keyed by SQL column name with the value as stored.
abstract final class BundleFormat {
  /// The manifest's `format`.
  static const String name = 'tapture-bundle';

  /// The manifest's `format_version`. A reader refuses a newer one.
  static const int version = 1;

  /// The package's MIME type.
  static const String mimeType = 'application/zip';

  /// The package's file extension, without the dot.
  static const String extension = 'zip';

  /// Identity, versions, counts and every entry's checksum.
  static const String manifest = 'manifest.json';

  /// One `sha256  path` line per entry, for tools outside the app.
  static const String checksums = 'checksums.txt';

  /// The export workbook, for a reader outside the app (task 076, D13).
  static const String workbook = 'records.xlsx';

  /// Folder of one JSON entry per reference dataset.
  static const String referenceFolder = 'reference/';

  /// Entries decoded as JSON objects, sharing the bounded metadata budget.
  static bool isMetadataEntry(String path) =>
      path == manifest ||
      tableEntries.containsKey(path) ||
      (path.startsWith(referenceFolder) && path.endsWith('.json'));

  /// Which tables each JSON entry carries.
  static const Map<String, List<String>> tableEntries = <String, List<String>>{
    'project.json': <String>[
      'projects',
      'context_definitions',
      'context_presets',
    ],
    'templates.json': <String>['templates', 'template_fields', 'template_rows'],
    'records.json': <String>['records', 'record_fields', 'field_evidence'],
    'captions.json': <String>['captions'],
    'media.json': <String>['photos', 'attachments', 'attachment_owners'],
    'meetings.json': <String>['meetings', 'attendees', 'meeting_actions'],
    'variances.json': <String>['variances'],
    'processing.json': <String>['processing_jobs', 'processing_results'],
    'duplicates.json': <String>['duplicates'],
    'audit.json': <String>['audit_log'],
    'tombstones.json': <String>['tombstones'],
  };

  /// The tables a reference entry carries.
  static const List<String> referenceTables = <String>[
    'reference_datasets',
    'reference_rows',
  ];

  /// Every carried table, in the order an import inserts them: owners
  /// before what they own.
  static const List<String> insertOrder = <String>[
    'projects',
    'context_definitions',
    'context_presets',
    'templates',
    'template_fields',
    'template_rows',
    'reference_datasets',
    'reference_rows',
    'records',
    'record_fields',
    'photos',
    'attachments',
    'attachment_owners',
    'field_evidence',
    'captions',
    'meetings',
    'attendees',
    'meeting_actions',
    'variances',
    'processing_jobs',
    'processing_results',
    'duplicates',
    'audit_log',
    'tombstones',
  ];

  /// Columns a row must hold for a reader to accept its table. Every row
  /// also needs `id`.
  static const Map<String, List<String>> requiredColumns =
      <String, List<String>>{
        'projects': <String>['name', 'folder_name'],
        'templates': <String>['project_id', 'name'],
        'template_fields': <String>['template_id', 'field_key'],
        'records': <String>['project_id', 'template_id'],
        'record_fields': <String>['record_id', 'field_key'],
        'photos': <String>['project_id', 'relative_path', 'sha256'],
        'attachments': <String>['project_id', 'relative_path', 'sha256'],
        'reference_datasets': <String>['name'],
        'reference_rows': <String>['dataset_id', 'key_value'],
      };

  /// The entries every package holds, whatever the project contains.
  static Set<String> get requiredEntries => <String>{
    manifest,
    checksums,
    ...tableEntries.keys,
  };
}

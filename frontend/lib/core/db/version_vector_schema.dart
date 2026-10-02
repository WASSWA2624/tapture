import 'package:drift/drift.dart';

import 'app_database.dart';

/// Atomic causal counters for authored package rows, including custom SQL writes.
/// Remote package writes retain their supplied vectors through [remoteWrites].
abstract final class VersionVectorSchema {
  /// Rows exchanged in packages. Internal device state is deliberately excluded.
  static const List<String> tables = <String>[
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

  /// Transaction-local suppression, never exported as application data.
  static const String holdTable = 'version_vector_hold';

  /// Installs triggers once at creation/upgrade and seeds legacy author counters.
  /// Repeating installation preserves observed components and is safe.
  static Future<void> ensure(AppDatabase db) async {
    await db.customStatement(
      'CREATE TABLE IF NOT EXISTS $holdTable '
      '(id INTEGER PRIMARY KEY CHECK (id = 1), depth INTEGER NOT NULL)',
    );
    final Set<String> present = <String>{
      for (final QueryRow row
          in await db
              .customSelect(
                "SELECT name FROM sqlite_master WHERE type = 'table'",
              )
              .get())
        row.read<String>('name'),
    };
    if (!present.contains('version_vectors')) {
      return;
    }
    for (final String table in tables) {
      if (!present.contains(table)) {
        continue;
      }
      await db.customStatement('''
INSERT INTO version_vectors
  (id, created_at, updated_at, updated_by_device, rev,
   entity_type, entity_id, device_id, seen_rev)
SELECT ${_uuid('updated_at')}, created_at, updated_at, updated_by_device, 1,
       '$table', id, updated_by_device, MAX(rev, 1)
FROM "$table" WHERE updated_by_device <> ''
ON CONFLICT(entity_type, entity_id, device_id) DO UPDATE SET
  seen_rev = MAX(version_vectors.seen_rev, excluded.seen_rev)
''');
      for (final String event in <String>['INSERT', 'UPDATE']) {
        final String changed = event == 'UPDATE'
            ? 'AND (NEW.rev IS NOT OLD.rev OR '
                  'NEW.updated_at IS NOT OLD.updated_at OR '
                  'NEW.updated_by_device IS NOT OLD.updated_by_device)'
            : '';
        await db.customStatement('''
CREATE TRIGGER IF NOT EXISTS vector_${table}_${event.toLowerCase()}
AFTER $event ON "$table"
WHEN NEW.updated_by_device <> ''
  AND NOT EXISTS (SELECT 1 FROM $holdTable WHERE depth > 0) $changed
BEGIN
  INSERT INTO version_vectors
    (id, created_at, updated_at, updated_by_device, rev,
     entity_type, entity_id, device_id, seen_rev)
  VALUES (${_uuid('NEW.updated_at')}, NEW.created_at, NEW.updated_at,
          NEW.updated_by_device, 1, '$table', NEW.id,
          NEW.updated_by_device, MAX(NEW.rev, 1))
  ON CONFLICT(entity_type, entity_id, device_id) DO UPDATE SET
    seen_rev = MAX(version_vectors.seen_rev + 1, excluded.seen_rev),
    updated_at = excluded.updated_at,
    updated_by_device = excluded.updated_by_device,
    rev = version_vectors.rev + 1;
END
''');
      }
    }
    if (present.contains('tombstones')) {
      await db.customStatement('''
CREATE TRIGGER IF NOT EXISTS vector_tombstone_entity_insert
AFTER INSERT ON tombstones
WHEN NEW.deleted_by_device <> ''
  AND NOT EXISTS (SELECT 1 FROM $holdTable WHERE depth > 0)
BEGIN
  INSERT INTO version_vectors
    (id, created_at, updated_at, updated_by_device, rev,
     entity_type, entity_id, device_id, seen_rev)
  VALUES (${_uuid('NEW.updated_at')}, NEW.created_at, NEW.updated_at,
          NEW.deleted_by_device, 1, NEW.entity_type, NEW.entity_id,
          NEW.deleted_by_device, 1)
  ON CONFLICT(entity_type, entity_id, device_id) DO UPDATE SET
    seen_rev = version_vectors.seen_rev + 1,
    updated_at = excluded.updated_at,
    updated_by_device = excluded.updated_by_device,
    rev = version_vectors.rev + 1;
END
''');
    }
  }

  /// Applies received rows without counting them as additional authored edits.
  /// The caller must merge received components in the same transaction.
  /// Nested calls and failed writes restore the previous suppression depth.
  static Future<T> remoteWrites<T>(AppDatabase db, Future<T> Function() body) =>
      db.transaction(() async {
        await db.customStatement(
          'INSERT INTO $holdTable (id, depth) VALUES (1, 1) '
          'ON CONFLICT(id) DO UPDATE SET depth = depth + 1',
        );
        try {
          return await body();
        } finally {
          await db.customStatement('UPDATE $holdTable SET depth = depth - 1');
          await db.customStatement('DELETE FROM $holdTable WHERE depth = 0');
        }
      });

  // UUIDv7 uses the injected row timestamp (SQLite datetime seconds), with
  // random suffix bits. It does not read a second system clock in a trigger.
  static String _uuid(String timestamp) {
    final String time = "printf('%012x', CAST($timestamp * 1000 AS INTEGER))";
    return "substr($time, 1, 8) || '-' || substr($time, 9, 4) || '-7' || "
        "lower(substr(hex(randomblob(2)), 2, 3)) || '-' || "
        "printf('%x', 8 + (random() & 3)) || "
        "lower(substr(hex(randomblob(2)), 2, 3)) || '-' || "
        'lower(hex(randomblob(6)))';
  }
}

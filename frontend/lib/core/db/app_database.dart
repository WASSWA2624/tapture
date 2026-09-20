import 'package:drift/drift.dart';

import 'app_database_stub.dart'
    if (dart.library.io) 'app_database_io.dart'
    if (dart.library.js_interop) 'app_database_web.dart'
    as sqlite;
import 'columns.dart';
import 'migrations.dart';
import 'tables/attachments.dart';
import 'tables/audit_log.dart';
import 'tables/captions.dart';
import 'tables/context.dart';
import 'tables/device_profile.dart';
import 'tables/duplicates.dart';
import 'tables/exports.dart';
import 'tables/field_evidence.dart';
import 'tables/meetings.dart';
import 'tables/merge.dart';
import 'tables/photos.dart';
import 'tables/processing.dart';
import 'tables/projects.dart';
import 'tables/record_fields.dart';
import 'tables/records.dart';
import 'tables/reference.dart';
import 'tables/sync_state.dart';
import 'tables/template_fields.dart';
import 'tables/template_rows.dart';
import 'tables/templates.dart';
import 'tables/tombstones.dart';
import 'tables/variances.dart';

part 'app_database.g.dart';

/// Current schema version. Later table tasks bump this and append a named
/// upgrade step; they never edit earlier steps.
const int kSchemaVersion = 14;

/// The local SQLite database. Opens on a WAL connection under the application
/// support directory, or in memory for tests.
@DriftDatabase(
  tables: <Type>[
    Tombstones,
    AuditLog,
    DeviceProfile,
    Projects,
    Context,
    ContextState,
    ContextPresets,
    Templates,
    TemplateFields,
    TemplateRows,
    Records,
    RecordFields,
    Photos,
    Attachments,
    Captions,
    Reference,
    ReferenceRows,
    Processing,
    ProcessingResults,
    FieldEvidence,
    Duplicates,
    Variances,
    Meetings,
    Attendees,
    MeetingActions,
    Exports,
    Merge,
    MergeConflicts,
    SyncState,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Opens against [e], which is a lazy file connection or an in-memory one.
  AppDatabase(super.e);

  /// In-memory database for tests. No suite touches the on-disk file.
  factory AppDatabase.memory() {
    return AppDatabase(sqlite.openMemoryExecutor());
  }

  /// On-disk database in [directoryPath], or the application support
  /// directory when omitted. When [encryptionKey] is set, the same factory
  /// opens the encrypted file produced by DatabaseEncryption.
  factory AppDatabase.open({String? directoryPath, String? encryptionKey}) {
    return AppDatabase(
      sqlite.openFileExecutor(
        directoryPath: directoryPath,
        encryptionKey: encryptionKey,
      ),
    );
  }

  @override
  int get schemaVersion => kSchemaVersion;

  @override
  MigrationStrategy get migration => appMigration(this);
}

import 'package:drift/drift.dart';

import 'app_database_stub.dart'
    if (dart.library.io) 'app_database_io.dart'
    as sqlite;
import 'columns.dart';
import 'migrations.dart';
import 'tables/audit_log.dart';
import 'tables/context.dart';
import 'tables/device_profile.dart';
import 'tables/projects.dart';
import 'tables/record_fields.dart';
import 'tables/records.dart';
import 'tables/template_fields.dart';
import 'tables/template_rows.dart';
import 'tables/templates.dart';
import 'tables/tombstones.dart';

part 'app_database.g.dart';

/// Current schema version. Later table tasks bump this and append a named
/// upgrade step; they never edit earlier steps.
const int kSchemaVersion = 5;

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
  /// directory when omitted.
  factory AppDatabase.open({String? directoryPath}) {
    return AppDatabase(sqlite.openFileExecutor(directoryPath: directoryPath));
  }

  @override
  int get schemaVersion => kSchemaVersion;

  @override
  MigrationStrategy get migration => appMigration(this);
}

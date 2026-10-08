import 'package:tapture/core/db/app_database.dart';

/// Creates an isolated native in-memory database for a screen fixture.
AppDatabase createScreenDatabase() => AppDatabase.memory();

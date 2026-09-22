import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/db/app_database.dart';

/// The one on-disk database opened in `main`.
///
/// A second [AppDatabase.open] over the same file races the first. Tests
/// override this with [AppDatabase.memory] and never open the file
/// (FE-TEST-03, FE-STATE-09).
final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>((
  Ref _,
) {
  throw StateError(
    'appDatabaseProvider must be overridden with the database opened in main.',
  );
});

import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/result.dart';

/// Folds every committed write in the write-ahead log into the database file
/// and truncates the log, the flush the app awaits when it goes to the
/// background (FE-STATE-07).
///
/// A committed write already survives the process being killed; after this
/// the database file alone holds it too, so a copy taken over a cable, a
/// backup or the encryption copy on close misses nothing. A reader still
/// open only shortens the pass, and a browser database, which keeps no log,
/// has nothing to fold. Nothing is ever lost by calling this.
Future<Result<void>> checkpointDatabase(AppDatabase db) {
  return Result.captureAsync(() async {
    await db.customSelect('PRAGMA wal_checkpoint(TRUNCATE)').get();
  });
}

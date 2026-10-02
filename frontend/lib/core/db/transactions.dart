import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:sqlite3/common.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// Zone key so a nested [runInTransaction] joins the open write instead of
/// opening a second transaction.
const Object _transactionZoneKey = #tapture.db.transaction;

/// Runs [body] in a single transaction on [db].
///
/// When a call is already inside [runInTransaction] for this database, the
/// work joins that write: a throw rolls back the whole thing, including rows
/// the outer call had already inserted.
Future<Result<T>> runInTransaction<T>(
  GeneratedDatabase db,
  Future<T> Function() body,
) async {
  if (Zone.current[_transactionZoneKey] == db) {
    return Success<T>(await body());
  }
  try {
    final T value = await db.transaction(() {
      return runZoned(
        body,
        zoneValues: <Object?, Object?>{_transactionZoneKey: db},
      );
    });
    return Success<T>(value);
  } on Object catch (error) {
    return FailureResult<T>(storageFailureFrom(error));
  }
}

/// Maps a thrown database error onto a [StorageFailure] with a recovery
/// action. Uniqueness and busy/locked are distinct; nothing from sqlite3 is
/// interpolated into the message.
StorageFailure storageFailureFrom(Object error) {
  // File connections execute on Drift's worker. Preserve the native cause
  // instead of presenting a locked database as a disk-space problem.
  while (error is DriftRemoteException) {
    error = error.remoteCause;
  }
  if (error is StorageFailure) {
    return error;
  }
  if (error is SqliteException) {
    if (error.resultCode == SqlError.SQLITE_BUSY ||
        error.resultCode == SqlError.SQLITE_LOCKED) {
      return StorageFailure(
        localizedMessage: Copy.messages.failureTheDatabaseIsBusy,
        localizedRecovery: Copy.messages.failureWaitAMomentThenTryTheSave,
      );
    }
    if (error.resultCode == SqlError.SQLITE_CONSTRAINT) {
      return StorageFailure(
        localizedMessage:
            Copy.messages.failureARecordWithThatIdentityAlreadyExists,
        localizedRecovery:
            Copy.messages.failureOpenTheExistingRecordOrChangeThe,
      );
    }
  }
  return StorageFailure(
    localizedMessage: Copy.messages.failureTheDatabaseCouldNotCompleteThatWrite,
    localizedRecovery: Copy.messages.failureFreeUpSpaceOrExportAProject,
  );
}

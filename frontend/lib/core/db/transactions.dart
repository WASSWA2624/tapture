import 'dart:async';

import 'package:drift/drift.dart';
import 'package:sqlite3/common.dart';
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
  if (error is StorageFailure) {
    return error;
  }
  if (error is SqliteException) {
    if (error.resultCode == SqlError.SQLITE_BUSY ||
        error.resultCode == SqlError.SQLITE_LOCKED) {
      return const StorageFailure(
        message: 'The database is busy.',
        recoveryAction: 'Wait a moment, then try the save again.',
      );
    }
    if (error.resultCode == SqlError.SQLITE_CONSTRAINT) {
      return const StorageFailure(
        message: 'A record with that identity already exists.',
        recoveryAction: 'Open the existing record, or change the identity.',
      );
    }
  }
  return const StorageFailure(
    message: 'The database could not complete that write.',
    recoveryAction: 'Free up space or export a project, then try again.',
  );
}

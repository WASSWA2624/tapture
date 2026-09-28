import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/destination_secrets.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/database_provider.dart';
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/cloud/domain/upload_runner.dart';

import '../domain/destination_repository.dart';

/// Drift store for destinations, and upload attempts kept on the exports table.
///
/// An attempt row is inserted when the transfer starts, with outcome
/// `interrupted`, and updated when it ends. The credential value is never
/// written on either table.
///
/// A destination the person removes is tombstoned, so the list no longer
/// shows it and merge never brings it back; the row itself stays (FE-SEC-08).
final class DestinationRepositoryImpl implements DestinationRepository {
  /// Creates the store.
  DestinationRepositoryImpl({
    required this.database,
    required this.secrets,
    required this.clock,
    required this.deviceId,
    required this.ids,
  });

  /// Open database.
  final AppDatabase database;

  /// Credential store. Values never go on [database].
  final DestinationSecrets secrets;

  /// Clock for row timestamps.
  final Clock clock;

  /// Device stamp written on each row.
  final String deviceId;

  /// Identifier source for new attempt rows.
  final IdService ids;

  static const String _uploadProject = 'cloud-upload';
  static const String _uploadFormats = '["cloud-upload"]';
  static const String _removeReason = 'Removed by the operator.';

  @override
  Stream<List<Destination>> watchAll() {
    final $DestinationsTable destinations = database.destinations;
    final $TombstonesTable tombstones = database.tombstones;
    final JoinedSelectStatement<HasResultSet, dynamic> query = database
        .select(destinations)
        .join(<Join<HasResultSet, Object?>>[
          leftOuterJoin(
            tombstones,
            tombstones.entityType.equals(destinations.actualTableName) &
                tombstones.entityId.equalsExp(destinations.id),
            useColumns: false,
          ),
        ]);
    query
      ..where(tombstones.entityId.isNull())
      ..orderBy(<OrderingTerm>[OrderingTerm.asc(destinations.label)]);
    return query.watch().map(
      (List<TypedResult> rows) => <Destination>[
        for (final TypedResult row in rows)
          _destination(row.readTable(destinations)),
      ],
    );
  }

  @override
  Future<Result<void>> save(Destination destination) async {
    try {
      final DateTime now = clock.nowUtc();
      final DestinationRow? existing =
          await (database.select(database.destinations)..where(
                ($DestinationsTable table) => table.id.equals(destination.id),
              ))
              .getSingleOrNull();
      if (existing == null) {
        await database
            .into(database.destinations)
            .insert(
              DestinationsCompanion.insert(
                id: Value<String>(destination.id),
                createdAt: now,
                updatedAt: now,
                updatedByDevice: deviceId,
                kind: destination.kind.name,
                label: destination.label,
                folder: destination.folder,
                credentialRef: destination.credentialRef,
                lastCheck: Value<String?>(destination.lastCheck),
              ),
            );
      } else {
        await (database.update(database.destinations)..where(
              ($DestinationsTable table) => table.id.equals(destination.id),
            ))
            .write(
              DestinationsCompanion(
                kind: Value<String>(destination.kind.name),
                label: Value<String>(destination.label),
                folder: Value<String>(destination.folder),
                credentialRef: Value<String>(destination.credentialRef),
                lastCheck: Value<String?>(destination.lastCheck),
                updatedAt: Value<DateTime>(now),
                updatedByDevice: Value<String>(deviceId),
                rev: Value<int>(existing.rev + 1),
              ),
            );
      }
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(
        error is Failure
            ? error
            : const StorageFailure(
                message: 'The destination could not be saved.',
                recoveryAction: 'Try again.',
              ),
      );
    }
  }

  @override
  Future<Result<void>> remove(String id) async {
    final DestinationRow? row = await _listed(id);
    if (row == null) {
      return const FailureResult<void>(
        ValidationFailure(
          message: 'That destination is no longer listed.',
          recoveryAction: 'Refresh the list.',
        ),
      );
    }
    final Result<void> secret = await secrets.forget(row.credentialRef);
    if (secret is FailureResult<void>) {
      return const FailureResult<void>(
        StorageFailure(
          message:
              'The destination is still listed. The sign-in is still saved.',
          recoveryAction: 'Try removing it again.',
        ),
      );
    }
    try {
      await writeTombstone(
        database,
        entityType: database.destinations.actualTableName,
        entityId: id,
        reason: _removeReason,
        clock: clock,
        deviceId: deviceId,
      );
    } on Object {
      return const FailureResult<void>(
        StorageFailure(
          message: 'The sign-in was removed. The destination is still listed.',
          recoveryAction: 'Try removing it again.',
        ),
      );
    }
    return const Success<void>(null);
  }

  /// Inserts the attempt as interrupted before any byte is sent.
  Future<Result<UploadAttempt>> beginAttempt(UploadAttempt attempt) async {
    try {
      final int version = await _nextVersion();
      final String id = attempt.id.isEmpty ? ids.newId() : attempt.id;
      final DateTime now = clock.nowUtc();
      final UploadAttempt stored = (
        id: id,
        destinationId: attempt.destinationId,
        destinationLabel: attempt.destinationLabel,
        filePath: attempt.filePath,
        remoteName: attempt.remoteName,
        folder: attempt.folder,
        byteSize: attempt.byteSize,
        startedAt: attempt.startedAt,
        endedAt: null,
        outcome: 'interrupted',
        failureReason: null,
        offset: attempt.offset,
      );
      await database
          .into(database.exports)
          .insert(
            ExportsCompanion.insert(
              id: Value<String>(id),
              createdAt: now,
              updatedAt: now,
              updatedByDevice: deviceId,
              projectId: _uploadProject,
              version: version,
              formats: _uploadFormats,
              filters: jsonEncode(_filters(stored)),
              recordCount: 0,
              filePath: stored.filePath,
              fileHash: 'upload',
              createdBy: deviceId,
            ),
          );
      return Success<UploadAttempt>(stored);
    } on Object {
      return const FailureResult<UploadAttempt>(
        StorageFailure(
          message: 'The upload could not be recorded.',
          recoveryAction: 'Try again.',
        ),
      );
    }
  }

  /// Updates the attempt row. The previous row is not replaced by a new id.
  Future<Result<void>> finishAttempt(UploadAttempt attempt) async {
    try {
      await (database.update(
        database.exports,
      )..where(($ExportsTable table) => table.id.equals(attempt.id))).write(
        ExportsCompanion(
          filters: Value<String>(jsonEncode(_filters(attempt))),
          updatedAt: Value<DateTime>(attempt.endedAt ?? clock.nowUtc()),
        ),
      );
      return const Success<void>(null);
    } on Object {
      return const FailureResult<void>(
        StorageFailure(
          message: 'The upload history could not be updated.',
          recoveryAction: 'The file on this device was not changed.',
        ),
      );
    }
  }

  /// The attempt [id], or null.
  Future<Result<UploadAttempt?>> readAttempt(String id) async {
    final ExportRow? row = await (database.select(
      database.exports,
    )..where(($ExportsTable table) => table.id.equals(id))).getSingleOrNull();
    if (row == null || row.formats != _uploadFormats) {
      return const Success<UploadAttempt?>(null);
    }
    return Success<UploadAttempt?>(_attempt(row));
  }

  /// Attempts newest first. [destinationId] limits the list when set.
  Future<Result<List<UploadAttempt>>> attempts({String? destinationId}) async {
    final List<ExportRow> rows =
        await (database.select(database.exports)
              ..where(
                ($ExportsTable table) => table.projectId.equals(_uploadProject),
              )
              ..orderBy(<OrderClauseGenerator<$ExportsTable>>[
                ($ExportsTable table) => OrderingTerm.desc(table.createdAt),
              ]))
            .get();
    final List<UploadAttempt> attempts = <UploadAttempt>[
      for (final ExportRow row in rows)
        if (row.formats == _uploadFormats) _attempt(row),
    ];
    if (destinationId == null || destinationId.isEmpty) {
      return Success<List<UploadAttempt>>(attempts);
    }
    return Success<List<UploadAttempt>>(<UploadAttempt>[
      for (final UploadAttempt attempt in attempts)
        if (attempt.destinationId == destinationId) attempt,
    ]);
  }

  /// History callbacks for [UploadRunner].
  UploadHistory get history =>
      (begin: beginAttempt, finish: finishAttempt, read: readAttempt);

  /// The row [id] while the list still shows it: saved and not tombstoned.
  Future<DestinationRow?> _listed(String id) async {
    final DestinationRow? row =
        await (database.select(database.destinations)
              ..where(($DestinationsTable table) => table.id.equals(id)))
            .getSingleOrNull();
    if (row == null) {
      return null;
    }
    final Tombstone? removed =
        await (database.select(database.tombstones)..where(
              ($TombstonesTable table) =>
                  table.entityType.equals(
                    database.destinations.actualTableName,
                  ) &
                  table.entityId.equals(id),
            ))
            .getSingleOrNull();
    return removed == null ? row : null;
  }

  Destination _destination(DestinationRow row) {
    return (
      id: row.id,
      kind: DestinationKind.values.byName(row.kind),
      label: row.label,
      folder: row.folder,
      credentialRef: row.credentialRef,
      lastCheck: row.lastCheck,
    );
  }

  Future<int> _nextVersion() async {
    final List<ExportRow> rows =
        await (database.select(database.exports)..where(
              ($ExportsTable table) => table.projectId.equals(_uploadProject),
            ))
            .get();
    var version = 0;
    for (final ExportRow row in rows) {
      if (row.version > version) {
        version = row.version;
      }
    }
    return version + 1;
  }

  Map<String, Object?> _filters(UploadAttempt attempt) {
    return <String, Object?>{
      'destinationId': attempt.destinationId,
      'destinationLabel': attempt.destinationLabel,
      'remoteName': attempt.remoteName,
      'folder': attempt.folder,
      'byteSize': attempt.byteSize,
      'outcome': attempt.outcome,
      'failureReason': attempt.failureReason,
      'offset': attempt.offset,
      'endedAt': attempt.endedAt?.toUtc().toIso8601String(),
      'startedAt': attempt.startedAt.toUtc().toIso8601String(),
    };
  }

  UploadAttempt _attempt(ExportRow row) {
    final Object? decoded = jsonDecode(row.filters);
    final Map<Object?, Object?> json = decoded is Map
        ? decoded
        : <Object?, Object?>{};
    final Object? ended = json['endedAt'];
    final Object? started = json['startedAt'];
    final Object? reason = json['failureReason'];
    final Object? size = json['byteSize'];
    final Object? offset = json['offset'];
    return (
      id: row.id,
      destinationId: '${json['destinationId'] ?? ''}',
      destinationLabel: '${json['destinationLabel'] ?? ''}',
      filePath: row.filePath,
      remoteName: '${json['remoteName'] ?? ''}',
      folder: '${json['folder'] ?? ''}',
      byteSize: size is int ? size : 0,
      startedAt: started is String ? DateTime.parse(started) : row.createdAt,
      endedAt: ended is String ? DateTime.parse(ended) : null,
      outcome: '${json['outcome'] ?? 'interrupted'}',
      failureReason: reason is String ? reason : null,
      offset: offset is int ? offset : 0,
    );
  }
}

/// The destination store. Tests override it.
final Provider<DestinationRepositoryImpl> destinationRepositoryProvider =
    Provider<DestinationRepositoryImpl>((Ref ref) {
      return DestinationRepositoryImpl(
        database: ref.watch(appDatabaseProvider),
        secrets: DestinationSecrets(SecureStorage()),
        clock: const SystemClock(),
        deviceId: '',
        ids: UuidV7Service(const SystemClock()),
      );
    });

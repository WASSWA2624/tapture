import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/destination_secrets.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/cloud/data/destination_repository_impl.dart';
import 'package:tapture/features/cloud/domain/upload_runner.dart';

void main() {
  test(
    'an attempt row exists before it ends, and a later finish does not replace it',
    () async {
      final DestinationRepositoryImpl repository = _repository();
      final Result<UploadAttempt> begun = await repository.beginAttempt((
        id: '',
        destinationId: 'dest',
        destinationLabel: 'Archive',
        filePath: 'pack.zip',
        remoteName: 'pack.zip',
        folder: 'inbox',
        byteSize: 12,
        startedAt: DateTime.utc(2026, 9, 28, 8),
        endedAt: null,
        outcome: 'succeeded',
        failureReason: null,
        offset: 0,
      ));
      final UploadAttempt started = (begun as Success<UploadAttempt>).value;
      expect(started.outcome, 'interrupted');
      expect(
        (await repository.readAttempt(started.id) as Success<UploadAttempt?>)
            .value
            ?.outcome,
        'interrupted',
      );
      expect(
        await repository.finishAttempt((
          id: started.id,
          destinationId: started.destinationId,
          destinationLabel: started.destinationLabel,
          filePath: started.filePath,
          remoteName: started.remoteName,
          folder: started.folder,
          byteSize: started.byteSize,
          startedAt: started.startedAt,
          endedAt: DateTime.utc(2026, 9, 28, 9),
          outcome: 'failed',
          failureReason: 'The destination did not finish the upload.',
          offset: 4,
        )),
        isA<Success<void>>(),
      );
      final List<UploadAttempt> rows =
          (await repository.attempts() as Success<List<UploadAttempt>>).value;
      expect(rows, hasLength(1));
      expect(rows.single.id, started.id);
      expect(rows.single.outcome, 'failed');
      expect(rows.single.failureReason, contains('did not finish'));
    },
  );

  test('a half-finished removal names the half that remains', () async {
    final Map<SecretKey, String> backing = <SecretKey, String>{};
    final AppDatabase database = AppDatabase.memory();
    addTearDown(database.close);
    final DestinationRepositoryImpl repository = DestinationRepositoryImpl(
      database: database,
      secrets: _FailingSecrets(
        DestinationSecrets(SecureStorage.fake(backing: backing)),
      ),
      clock: FixedClock(DateTime.utc(2026, 9, 28)),
      deviceId: 'device',
      ids: UuidV7Service.sequence(FixedClock(DateTime.utc(2026, 9, 28))),
    );
    expect(
      await repository.save((
        id: 'dest-1',
        kind: DestinationKind.webdav,
        label: 'Dav',
        folder: 'inbox',
        credentialRef: 'ref-1',
        lastCheck: null,
      )),
      isA<Success<void>>(),
    );
    final Result<void> removed = await repository.remove('dest-1');
    expect(removed, isA<FailureResult<void>>());
    expect(
      (removed as FailureResult<void>).failure.message,
      'The destination is still listed. The sign-in is still saved.',
    );
    expect(await repository.watchAll().first, hasLength(1));
  });
}

DestinationRepositoryImpl _repository() {
  final AppDatabase database = AppDatabase.memory();
  addTearDown(database.close);
  return DestinationRepositoryImpl(
    database: database,
    secrets: DestinationSecrets(
      SecureStorage.fake(backing: <SecretKey, String>{}),
    ),
    clock: FixedClock(DateTime.utc(2026, 9, 28)),
    deviceId: 'device',
    ids: UuidV7Service.sequence(FixedClock(DateTime.utc(2026, 9, 28))),
  );
}

final class _FailingSecrets implements DestinationSecrets {
  _FailingSecrets(this._inner);

  final DestinationSecrets _inner;

  @override
  Future<Result<void>> delete(String ref) async {
    return const FailureResult<void>(
      StorageFailure(
        message: 'The secret could not be removed from this device.',
        recoveryAction: 'Try again.',
      ),
    );
  }

  @override
  Future<Result<void>> put(String ref, String payload) =>
      _inner.put(ref, payload);

  @override
  Future<Result<String?>> read(String ref) => _inner.read(ref);

  @override
  Future<Result<void>> putRefresh(String ref, String token) =>
      _inner.putRefresh(ref, token);

  @override
  Future<Result<String?>> readRefresh(String ref) => _inner.readRefresh(ref);
}

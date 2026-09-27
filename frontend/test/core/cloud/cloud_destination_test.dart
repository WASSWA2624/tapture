import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/destination_secrets.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/cloud/data/destination_repository_impl.dart';

void main() {
  test('the registry resolves every kind and names a missing one', () {
    final Map<DestinationKind, CloudDestination> backends =
        <DestinationKind, CloudDestination>{
          for (final DestinationKind kind in DestinationKind.values)
            kind: _FakeDestination(kind),
        };
    for (final DestinationKind kind in DestinationKind.values) {
      final Result<CloudDestination> resolved = resolveDestination(
        kind,
        backends,
      );
      expect(resolved, isA<Success<CloudDestination>>());
      expect((resolved as Success<CloudDestination>).value.kind, kind);
    }
    final Result<CloudDestination> missing = resolveDestination(
      DestinationKind.s3,
      <DestinationKind, CloudDestination>{},
    );
    expect(missing, isA<FailureResult<CloudDestination>>());
    expect(
      (missing as FailureResult<CloudDestination>).failure.message,
      contains('s3'),
    );
  });

  test(
    'a saved row holds only the credential ref, and remove clears both',
    () async {
      const String secret = 'super-secret-value';
      final Map<SecretKey, String> backing = <SecretKey, String>{};
      final AppDatabase database = AppDatabase.memory();
      addTearDown(database.close);
      final DestinationSecrets secrets = DestinationSecrets(
        SecureStorage.fake(backing: backing, database: <String, String>{}),
      );
      final DestinationRepositoryImpl repository = DestinationRepositoryImpl(
        database: database,
        secrets: secrets,
        clock: FixedClock(DateTime.utc(2026, 9, 28)),
        deviceId: 'device',
        ids: UuidV7Service.sequence(FixedClock(DateTime.utc(2026, 9, 28))),
      );
      const Destination destination = (
        id: 'dest-1',
        kind: DestinationKind.s3,
        label: 'Archive',
        folder: 'inbox',
        credentialRef: 'ref-1',
        lastCheck: null,
      );
      expect(await secrets.put('ref-1', secret), isA<Success<void>>());
      expect(await repository.save(destination), isA<Success<void>>());
      final List<Destination> stored = await repository.watchAll().first;
      expect(stored.single.credentialRef, 'ref-1');
      expect(stored.single.label, 'Archive');
      final row = await database
          .customSelect('SELECT * FROM destinations')
          .getSingle();
      final String dump = <String>[
        row.read<String>('kind'),
        row.read<String>('label'),
        row.read<String>('folder'),
        row.read<String>('credential_ref'),
      ].join(' ');
      expect(dump.contains(secret), isFalse);
      expect(row.read<String>('credential_ref'), 'ref-1');
      expect((await secrets.read('ref-1') as Success<String?>).value, secret);

      expect(await repository.remove('dest-1'), isA<Success<void>>());
      expect(await repository.watchAll().first, isEmpty);
      expect((await secrets.read('ref-1') as Success<String?>).value, isNull);
      expect(backing.values.join(), isNot(contains(secret)));
    },
  );
}

final class _FakeDestination implements CloudDestination {
  _FakeDestination(this.kind);

  @override
  final DestinationKind kind;

  @override
  Future<Result<void>> check(Destination destination) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<Uri>> send(
    Destination destination,
    CloudBytes file, {
    required String remoteName,
    int offset = 0,
    void Function(int sent, int total)? onProgress,
    CancellationToken? cancel,
  }) async {
    return Success<Uri>(Uri.parse('https://example.test/$remoteName'));
  }
}

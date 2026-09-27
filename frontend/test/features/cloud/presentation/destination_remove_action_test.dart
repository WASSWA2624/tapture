import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/destination_secrets.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/cloud/data/destination_repository_impl.dart';
import 'package:tapture/features/cloud/presentation/destination_remove_action.dart';

void main() {
  test('removal clears the secure-storage entry', () async {
    const String secret = 'sign-in-secret';
    final Map<SecretKey, String> backing = <SecretKey, String>{};
    final AppDatabase database = AppDatabase.memory();
    addTearDown(database.close);
    final DestinationSecrets secrets = DestinationSecrets(
      SecureStorage.fake(backing: backing),
    );
    final DestinationRepositoryImpl repository = DestinationRepositoryImpl(
      database: database,
      secrets: secrets,
      clock: FixedClock(DateTime.utc(2026, 9, 28)),
      deviceId: 'device',
      ids: UuidV7Service.sequence(FixedClock(DateTime.utc(2026, 9, 28))),
    );
    expect(await secrets.put('ref-1', secret), isA<Success<void>>());
    expect(
      await repository.save((
        id: 'dest-1',
        kind: DestinationKind.s3,
        label: 'Archive',
        folder: 'inbox',
        credentialRef: 'ref-1',
        lastCheck: null,
      )),
      isA<Success<void>>(),
    );
    expect(
      await DestinationRemoveAction.apply(
        repository: repository,
        id: 'dest-1',
        confirmed: true,
      ),
      isA<Success<void>>(),
    );
    expect((await secrets.read('ref-1') as Success<String?>).value, isNull);
    expect(backing.values.join(), isNot(contains(secret)));
  });
}

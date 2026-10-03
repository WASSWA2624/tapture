import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/database_provider.dart';
import 'package:tapture/core/db/tables/device_profile.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/operator_profile.dart';
import '../domain/operator_profile_repository.dart';

/// [OperatorProfileRepository] on the device-profile row. The row is
/// stamped with the one device id the profile keeps (task 078), resolved
/// once per repository rather than minted here.
final class OperatorProfileRepositoryImpl implements OperatorProfileRepository {
  /// Creates the repository over [db]. [legacyId] replaces the read of a
  /// pre-078 id file, so a test never touches the OS temp folder.
  OperatorProfileRepositoryImpl(
    this._db, {
    Clock clock = const SystemClock(),
    IdService? ids,
    this._legacyId,
  }) : _clock = clock,
       _ids = ids ?? UuidV7Service(clock);

  final AppDatabase _db;
  final Clock _clock;
  final IdService _ids;
  final String? Function()? _legacyId;
  Future<String>? _deviceId;

  @override
  Future<Result<OperatorProfile>> load() {
    return Result.captureAsync(() async {
      final DeviceProfileIdentity identity = await readDeviceProfile(
        _db,
        deviceId: await _device(),
        clock: _clock,
      );
      return OperatorProfile.fromStored(
        name: identity.operatorName,
        preferences: identity.preferences,
        accountId: identity.accountId,
      );
    });
  }

  @override
  Future<Result<OperatorProfile>> save(OperatorProfile profile) {
    return Result.captureAsync(() async {
      final String deviceId = await _device();
      final DeviceProfileIdentity current = await readDeviceProfile(
        _db,
        deviceId: deviceId,
        clock: _clock,
      );
      await writeDeviceProfile(
        _db,
        deviceId: deviceId,
        operatorName: profile.name,
        preferences: profile.mergePreferences(current.preferences),
        clock: _clock,
      );
      return profile;
    });
  }

  Future<String> _device() {
    return _deviceId ??= resolveDeviceId(
      _db,
      clock: _clock,
      ids: _ids,
      legacyId: _legacyId,
    );
  }
}

/// The operator profile store on this device's database.
final Provider<OperatorProfileRepository> operatorProfileRepositoryProvider =
    Provider<OperatorProfileRepository>((Ref ref) {
      return OperatorProfileRepositoryImpl(ref.watch(appDatabaseProvider));
    });

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/database_provider.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/device_profile.dart';
import 'package:tapture/core/db/template_capture_origins.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/security/coordinate_policy.dart';
import 'package:tapture/core/security/coordinate_removal_events.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/coordinate_privacy_repository.dart';

part 'coordinate_privacy_fields.dart';
part 'coordinate_privacy_history.dart';
part 'coordinate_privacy_sessions.dart';

/// Clears coordinates and their captured fields/history in one transaction.
final class CoordinatePrivacyRepositoryImpl
    implements CoordinatePrivacyRepository {
  /// Uses the existing database and stable identity; tests can supply [identity].
  CoordinatePrivacyRepositoryImpl({
    required this._db,
    this._clock = const SystemClock(),
    this._identity,
    this._onRemoval,
  });

  final AppDatabase _db;
  final Clock _clock;
  final Future<({String device, String operator})> Function()? _identity;
  final void Function(CoordinateRemoval removal)? _onRemoval;

  @override
  Future<Result<int>> removeFromProject(String projectId) async {
    if (projectId.isEmpty) {
      return FailureResult<int>(
        ValidationFailure(
          message: 'Open a project before removing its location data.',
          localizedMessage: Copy.messages.privacyProjectRequired,
          recoveryAction: 'Choose a project, then try again.',
          localizedRecovery: Copy.messages.privacyProjectRequiredRecovery,
        ),
      );
    }
    try {
      final ({String device, String operator}) who = await _who();
      final DateTime now = _clock.nowUtc();
      late _CoordinateDefinitions definitions;
      final Map<String, Set<int>> priorVersions = <String, Set<int>>{};
      final int count = await _db.transaction(() async {
        final _CoordinateDefinitions fields = await _coordinateFields(
          projectId,
        );
        definitions = fields;
        int changed = 0;
        String after = '';
        while (true) {
          final List<QueryRow> page = await _db
              .customSelect(
                'SELECT id, template_id, template_version, (gps_lat IS NOT NULL OR gps_lon IS NOT NULL OR EXISTS '
                '(SELECT 1 FROM photos p WHERE p.record_id = records.id '
                'AND p.project_id = ? AND (p.gps_lat IS NOT NULL OR p.gps_lon IS NOT NULL))) AS has_coordinates '
                'FROM records WHERE project_id = ? AND id > ? ORDER BY id LIMIT 200',
                variables: <Variable<Object>>[
                  Variable<String>(projectId),
                  Variable<String>(projectId),
                  Variable<String>(after),
                ],
              )
              .get();
          if (page.isEmpty) break;
          final List<String> ids = <String>[
            for (final QueryRow row in page) row.read<String>('id'),
          ];
          priorVersions.addAll(
            await readTemplateCaptureOrigins(
              db: _db,
              projectId: projectId,
              recordIds: ids,
            ),
          );
          final Map<String, Set<String>> keys = <String, Set<String>>{
            for (final QueryRow row in page)
              row.read<String>('id'): fields.keys(
                row.read<String>('template_id'),
                capturedVersion: row.read<int>('template_version'),
                priorVersions:
                    priorVersions[row.read<String>('id')] ?? const <int>{},
              ),
          };
          final Set<String> affected = <String>{
            for (final QueryRow row in page)
              if (row.read<bool>('has_coordinates')) row.read<String>('id'),
            ...await _clearContexts(ids, keys),
            ...await _clearFields(ids, keys, who, now),
            ...(await _scrubHistory(
              projectId: projectId,
              records: ids,
              keys: keys,
              who: who,
              now: now,
            )).records,
          };
          after = ids.last;
          if (affected.isEmpty) continue;
          await (_db.update(
            _db.records,
          )..where(($RecordsTable row) => row.id.isIn(affected))).write(
            RecordsCompanion.custom(
              gpsLat: const Constant<double>(null),
              gpsLon: const Constant<double>(null),
              rev: _db.records.rev + const Constant<int>(1),
              updatedAt: Variable<DateTime>(now),
              updatedByDevice: Variable<String>(who.device),
            ),
          );
          for (final String id in affected) {
            await _audit('records', id, who);
          }
          changed += affected.length;
        }
        after = '';
        while (true) {
          final List<QueryRow> page = await _db
              .customSelect(
                'SELECT id, (gps_lat IS NOT NULL OR gps_lon IS NOT NULL) AS has_coordinates '
                'FROM photos WHERE project_id = ? AND id > ? ORDER BY id LIMIT 200',
                variables: <Variable<Object>>[
                  Variable<String>(projectId),
                  Variable<String>(after),
                ],
              )
              .get();
          if (page.isEmpty) break;
          final List<String> ids = <String>[
            for (final QueryRow row in page) row.read<String>('id'),
          ];
          final Set<String> affected = <String>{
            for (final QueryRow row in page)
              if (row.read<bool>('has_coordinates')) row.read<String>('id'),
            ...(await _scrubHistory(
              projectId: projectId,
              photos: ids,
              who: who,
              now: now,
            )).photos,
          };
          after = ids.last;
          if (affected.isEmpty) continue;
          await (_db.update(
            _db.photos,
          )..where(($PhotosTable row) => row.id.isIn(affected))).write(
            PhotosCompanion.custom(
              gpsLat: const Constant<double>(null),
              gpsLon: const Constant<double>(null),
              rev: _db.photos.rev + const Constant<int>(1),
              updatedAt: Variable<DateTime>(now),
              updatedByDevice: Variable<String>(who.device),
            ),
          );
          for (final String id in affected) {
            await _audit('photos', id, who);
          }
        }
        await _clearSessions(projectId, fields, who, now);
        return changed;
      });
      _onRemoval?.call((
        projectId: projectId,
        keysByTemplate: definitions.all,
        currentFields: definitions.current,
        fieldHistory: definitions.history,
        currentVersions: definitions.versions,
        recordPriorVersions: priorVersions,
      ));
      return Success<int>(count);
    } on Object catch (error) {
      return FailureResult<int>(
        error is Failure ? error : storageFailureFrom(error),
      );
    }
  }

  Future<void> _audit(
    String entity,
    String id,
    ({String device, String operator}) who,
  ) {
    return appendAudit(
      _db,
      entityType: entity,
      entityId: id,
      action: AuditAction.updated,
      fieldKey: 'location',
      newValue: 'Removed',
      reason: 'Location removed by the operator.',
      clock: _clock,
      device: who.device,
      operator: who.operator,
    );
  }

  Future<({String device, String operator})> _who() async {
    final Future<({String device, String operator})> Function()? identity =
        _identity;
    if (identity != null) return identity();
    final String device = await resolveDeviceId(
      _db,
      clock: _clock,
      ids: UuidV7Service(_clock),
    );
    final DeviceProfileIdentity profile = await readDeviceProfile(
      _db,
      deviceId: device,
      clock: _clock,
    );
    return (device: device, operator: profile.operatorName);
  }
}

/// Production location removal port, replaceable in widget tests.
final Provider<CoordinatePrivacyRepository>
coordinatePrivacyRepositoryProvider = Provider<CoordinatePrivacyRepository>(
  (Ref ref) => CoordinatePrivacyRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    onRemoval: ref
        .read(coordinateRemovalEventsProvider.notifier)
        .publishRemoval,
  ),
);

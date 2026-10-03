part of 'coordinate_privacy_repository_impl.dart';

extension _CoordinatePrivacySessions on CoordinatePrivacyRepositoryImpl {
  Future<void> _clearSessions(
    String projectId,
    _CoordinateDefinitions fields,
    ({String device, String operator}) who,
    DateTime now,
  ) async {
    String after = '';
    while (true) {
      final List<QueryRow> rows = await _db
          .customSelect(
            'SELECT id, payload_json FROM capture_sessions WHERE id > ? '
            'AND (project_id = ? OR CASE WHEN json_valid(payload_json) '
            "THEN json_extract(payload_json, '\$.projectId') END = ?) "
            'ORDER BY id LIMIT 200',
            variables: <Variable<Object>>[
              Variable<String>(after),
              Variable<String>(projectId),
              Variable<String>(projectId),
            ],
          )
          .get();
      if (rows.isEmpty) break;
      final Map<String, Map<String, Object?>> payloads =
          <String, Map<String, Object?>>{};
      for (final QueryRow row in rows) {
        final Object? decoded = jsonDecode(row.read<String>('payload_json'));
        if (decoded is! Map<String, Object?>) {
          throw StorageFailure(
            message: 'The saved capture could not be read.',
            localizedMessage: Copy.messages.privacyCaptureUnreadable,
            recoveryAction: 'Recover the capture and try again.',
            localizedRecovery: Copy.messages.privacyCaptureRecover,
          );
        }
        payloads[row.read<String>('id')] = decoded;
      }
      final Map<String, Set<int>> priorVersions =
          await readTemplateCaptureOrigins(
            db: _db,
            projectId: projectId,
            recordIds: <String>[
              for (final Map<String, Object?> payload in payloads.values)
                if (payload['recordId'] case final String id) id,
            ],
          );
      for (final QueryRow row in rows) {
        final Map<String, Object?> payload = payloads[row.read<String>('id')]!;
        final String? templateId = payload['templateId'] as String?;
        final Object? capturedVersion = payload['templateVersion'];
        final Set<String> keys = templateId == null
            ? const <String>{}
            : fields.keys(
                templateId,
                capturedVersion: capturedVersion is int
                    ? capturedVersion
                    : null,
                priorVersions:
                    priorVersions[payload['recordId']] ?? const <int>{},
              );
        bool changed = payload.remove('location') != null;
        for (final String mapKey in <String>[
          'contextSnapshot',
          'values',
          'valueSources',
          'lookupRows',
        ]) {
          final Object? values = payload[mapKey];
          if (values is! Map<String, Object?>) continue;
          final List<String> coordinateKeys = <String>[
            for (final String key in values.keys)
              if (CoordinatePolicy.isKey(key) || keys.contains(key)) key,
          ];
          for (final String key in coordinateKeys) {
            changed = true;
            values.remove(key);
          }
        }
        final Object? photos = payload['photos'];
        if (photos is List<Object?>) {
          for (final Object? photo in photos) {
            if (photo is! Map<String, Object?>) continue;
            final List<String> keys = <String>[
              for (final String key in photo.keys)
                if (CoordinatePolicy.isKey(key) && photo[key] != null) key,
            ];
            for (final String key in keys) {
              changed = true;
              photo.remove(key);
            }
          }
        }
        if (!changed) continue;
        final String id = row.read<String>('id');
        await (_db.update(
          _db.captureSessions,
        )..where(($CaptureSessionsTable row) => row.id.equals(id))).write(
          CaptureSessionsCompanion.custom(
            payloadJson: Variable<String>(jsonEncode(payload)),
            rev: _db.captureSessions.rev + const Constant<int>(1),
            updatedAt: Variable<DateTime>(now),
            updatedByDevice: Variable<String>(who.device),
          ),
        );
        await _audit('capture_sessions', id, who);
      }
      after = rows.last.read<String>('id');
    }
  }
}

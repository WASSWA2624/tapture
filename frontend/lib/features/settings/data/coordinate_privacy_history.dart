part of 'coordinate_privacy_repository_impl.dart';

extension _CoordinatePrivacyHistory on CoordinatePrivacyRepositoryImpl {
  Future<({Set<String> records, Set<String> photos})> _scrubHistory({
    required String projectId,
    List<String> records = const <String>[],
    List<String> photos = const <String>[],
    Map<String, Set<String>> keys = const <String, Set<String>>{},
    required ({String device, String operator}) who,
    required DateTime now,
  }) async {
    final Set<String> affectedRecords = <String>{};
    final Set<String> affectedPhotos = <String>{};
    String after = '';
    while (true) {
      final List<Variable<Object>> variables = <Variable<Object>>[
        Variable<String>(after),
      ];
      final String scope;
      if (records.isNotEmpty) {
        final String slots = _placeholders(records.length);
        scope =
            '(r.id IN ($slots) OR f.record_id IN ($slots) OR '
            '(p.record_id IN ($slots) AND p.project_id = ?))';
        for (int group = 0; group < 3; group++) {
          variables.addAll(<Variable<Object>>[
            for (final String id in records) Variable<String>(id),
          ]);
        }
        variables.add(Variable<String>(projectId));
      } else {
        scope =
            'p.id IN (${_placeholders(photos.length)}) AND p.project_id = ?';
        variables.addAll(<Variable<Object>>[
          for (final String id in photos) Variable<String>(id),
          Variable<String>(projectId),
        ]);
      }
      final List<QueryRow> rows = await _db
          .customSelect(
            'SELECT l.id, COALESCE(f.record_id, r.id, p.record_id) AS record_id, '
            'p.id AS photo_id, COALESCE(f.field_key, l.field_key) AS field_key '
            'FROM audit_log l '
            "LEFT JOIN records r ON l.entity_type = 'records' AND r.id = l.entity_id "
            "LEFT JOIN record_fields f ON l.entity_type = 'record_fields' AND f.id = l.entity_id "
            "LEFT JOIN photos p ON l.entity_type = 'photos' AND p.id = l.entity_id "
            'WHERE l.id > ? AND ($scope) '
            'AND (l.previous_value IS NOT NULL OR l.new_value IS NOT NULL) '
            "AND NOT (l.previous_value IS NULL AND l.new_value = 'Removed' "
            "AND l.reason = 'Location removed by the operator.') "
            'ORDER BY l.id LIMIT 200',
            variables: variables,
          )
          .get();
      if (rows.isEmpty) break;
      final List<String> ids = <String>[];
      for (final QueryRow row in rows) {
        final String? key = row.readNullable<String>('field_key');
        final String? recordId = row.readNullable<String>('record_id');
        if (key == null ||
            !(CoordinatePolicy.isKey(key) ||
                (keys[recordId]?.contains(key) ?? false))) {
          continue;
        }
        ids.add(row.read<String>('id'));
        if (recordId != null) affectedRecords.add(recordId);
        final String? photoId = row.readNullable<String>('photo_id');
        if (photoId != null) affectedPhotos.add(photoId);
      }
      if (ids.isNotEmpty) {
        // Coordinate history must not restore the removed values through
        // recovery, search or a bundle. Keep the original actor/time/action.
        await _db.customUpdate(
          'UPDATE audit_log SET previous_value = NULL, new_value = NULL, '
          'rev = rev + 1, updated_at = ?, updated_by_device = ? '
          'WHERE id IN (${_placeholders(ids.length)})',
          variables: <Variable<Object>>[
            Variable<DateTime>(now),
            Variable<String>(who.device),
            for (final String id in ids) Variable<String>(id),
          ],
          updates: <TableInfo<dynamic, dynamic>>{_db.auditLog},
        );
      }
      after = rows.last.read<String>('id');
    }
    return (records: affectedRecords, photos: affectedPhotos);
  }
}

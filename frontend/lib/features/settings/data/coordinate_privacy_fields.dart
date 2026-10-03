part of 'coordinate_privacy_repository_impl.dart';

extension _CoordinatePrivacyFields on CoordinatePrivacyRepositoryImpl {
  Future<Set<String>> _clearContexts(
    List<String> recordIds,
    Map<String, Set<String>> keys,
  ) async {
    final Set<String> affected = <String>{};
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT id, context_json FROM records WHERE id IN (${_placeholders(recordIds.length)})',
          variables: <Variable<Object>>[
            for (final String id in recordIds) Variable<String>(id),
          ],
        )
        .get();
    for (final QueryRow row in rows) {
      final Object? decoded = jsonDecode(row.read<String>('context_json'));
      if (decoded is! Map<String, Object?>) continue;
      final String id = row.read<String>('id');
      final List<String> removed = <String>[
        for (final String key in decoded.keys)
          if (CoordinatePolicy.isKey(key) || (keys[id]?.contains(key) ?? false))
            key,
      ];
      if (removed.isEmpty) continue;
      for (final String key in removed) {
        decoded.remove(key);
      }
      await _db.customUpdate(
        'UPDATE records SET context_json = ? WHERE id = ?',
        variables: <Variable<Object>>[
          Variable<String>(jsonEncode(decoded)),
          Variable<String>(id),
        ],
        updates: <TableInfo<dynamic, dynamic>>{_db.records},
      );
      affected.add(id);
    }
    return affected;
  }

  Future<_CoordinateDefinitions> _coordinateFields(String projectId) async {
    final Map<String, Set<String>> fields = <String, Set<String>>{};
    final Map<String, Set<String>> defined = <String, Set<String>>{};
    String after = '';
    while (true) {
      final List<QueryRow> rows = await _db
          .customSelect(
            'SELECT f.id, f.template_id, f.field_key, f.type, f.validation '
            'FROM template_fields f WHERE f.id > ? AND NOT EXISTS '
            "(SELECT 1 FROM tombstones d WHERE d.entity_type = 'template_fields' AND d.entity_id = f.id) "
            'AND (EXISTS '
            '(SELECT 1 FROM records r WHERE r.project_id = ? AND r.template_id = f.template_id) '
            'OR EXISTS (SELECT 1 FROM capture_sessions s WHERE '
            '(s.project_id = ? OR CASE WHEN json_valid(s.payload_json) '
            "THEN json_extract(s.payload_json, '\$.projectId') END = ?) "
            'AND CASE WHEN json_valid(s.payload_json) '
            "THEN json_extract(s.payload_json, '\$.templateId') END = f.template_id)) "
            'ORDER BY f.id LIMIT 200',
            variables: <Variable<Object>>[
              Variable<String>(after),
              Variable<String>(projectId),
              Variable<String>(projectId),
              Variable<String>(projectId),
            ],
          )
          .get();
      if (rows.isEmpty) break;
      for (final QueryRow row in rows) {
        final String key = row.read<String>('field_key');
        (defined[row.read<String>('template_id')] ??= <String>{}).add(key);
        if (CoordinatePolicy.isField(
          key: key,
          type: row.read<String>('type'),
          validation: row.read<String>('validation'),
        )) {
          (fields[row.read<String>('template_id')] ??= <String>{}).add(key);
        }
      }
      after = rows.last.read<String>('id');
    }
    final Map<String, Map<int, Set<String>>> history =
        <String, Map<int, Set<String>>>{};
    final Map<String, int> versions = <String, int>{};
    after = '';
    while (true) {
      final List<QueryRow> rows = await _db
          .customSelect(
            'SELECT t.id, t.version, t.detection FROM templates t WHERE t.id > ? '
            'AND (EXISTS (SELECT 1 FROM records r WHERE r.project_id = ? '
            'AND r.template_id = t.id) OR EXISTS (SELECT 1 FROM capture_sessions s '
            'WHERE (s.project_id = ? OR CASE WHEN json_valid(s.payload_json) '
            "THEN json_extract(s.payload_json, '\$.projectId') END = ?) "
            'AND CASE WHEN json_valid(s.payload_json) '
            "THEN json_extract(s.payload_json, '\$.templateId') END = t.id)) "
            'ORDER BY t.id LIMIT 200',
            variables: <Variable<Object>>[
              Variable<String>(after),
              Variable<String>(projectId),
              Variable<String>(projectId),
              Variable<String>(projectId),
            ],
          )
          .get();
      if (rows.isEmpty) break;
      for (final QueryRow row in rows) {
        final String id = row.read<String>('id');
        versions[id] = row.read<int>('version');
        history[id] = CoordinatePolicy.historicalFieldVersions(
          row.read<String>('detection'),
        );
        fields[id] = CoordinatePolicy.withRetiredFields(
          current: fields[id] ?? const <String>{},
          defined: defined[id] ?? const <String>{},
          history: history[id]!,
        );
      }
      after = rows.last.read<String>('id');
    }
    return _CoordinateDefinitions(fields, history, versions);
  }

  Future<Set<String>> _clearFields(
    List<String> recordIds,
    Map<String, Set<String>> keys,
    ({String device, String operator}) who,
    DateTime now,
  ) async {
    final Set<String> affected = <String>{};
    String after = '';
    while (true) {
      final List<QueryRow> rows = await _db
          .customSelect(
            'SELECT id, record_id, field_key FROM record_fields '
            'WHERE record_id IN (${_placeholders(recordIds.length)}) AND id > ? '
            'AND (value_raw IS NOT NULL OR value_refined IS NOT NULL OR value_final IS NOT NULL) '
            'ORDER BY id LIMIT 200',
            variables: <Variable<Object>>[
              for (final String id in recordIds) Variable<String>(id),
              Variable<String>(after),
            ],
          )
          .get();
      if (rows.isEmpty) break;
      final List<QueryRow> coordinates = <QueryRow>[
        for (final QueryRow row in rows)
          if (CoordinatePolicy.isKey(row.read<String>('field_key')) ||
              (keys[row.read<String>('record_id')]?.contains(
                    row.read<String>('field_key'),
                  ) ??
                  false))
            row,
      ];
      if (coordinates.isNotEmpty) {
        // Explicit location erasure is the privacy exception to raw evidence
        // retention. Only classified GPS fields are nulled; their rows remain.
        await _db.customUpdate(
          'UPDATE record_fields SET value_raw = NULL, value_refined = NULL, '
          'value_final = NULL, confidence = NULL, confidence_band = NULL, '
          'verified = 0, verified_by = NULL, verified_at = NULL, '
          'rev = rev + 1, updated_at = ?, updated_by_device = ? '
          'WHERE id IN (${_placeholders(coordinates.length)})',
          variables: <Variable<Object>>[
            Variable<DateTime>(now),
            Variable<String>(who.device),
            for (final QueryRow row in coordinates)
              Variable<String>(row.read<String>('id')),
          ],
          updates: <TableInfo<dynamic, dynamic>>{_db.recordFields},
        );
        for (final QueryRow row in coordinates) {
          affected.add(row.read<String>('record_id'));
          await _audit('record_fields', row.read<String>('id'), who);
        }
      }
      after = rows.last.read<String>('id');
    }
    return affected;
  }
}

String _placeholders(int count) => List<String>.filled(count, '?').join(',');

final class _CoordinateDefinitions {
  const _CoordinateDefinitions(this.current, this.history, this.versions);

  final Map<String, Set<String>> current;
  final Map<String, Map<int, Set<String>>> history;
  final Map<String, int> versions;

  Set<String> keys(
    String templateId, {
    int? capturedVersion,
    Iterable<int> priorVersions = const <int>[],
  }) => CoordinatePolicy.withMigrationHistory(
    current: CoordinatePolicy.forVersion(
      current: current[templateId] ?? const <String>{},
      history: history[templateId] ?? const <int, Set<String>>{},
      currentVersion: versions[templateId] ?? capturedVersion ?? 1,
      capturedVersion: capturedVersion,
    ),
    history: history[templateId] ?? const <int, Set<String>>{},
    currentVersion: versions[templateId] ?? capturedVersion ?? 1,
    previousVersions: priorVersions,
  );

  Map<String, Set<String>> get all => <String, Set<String>>{
    for (final String id in <String>{...current.keys, ...history.keys})
      id: keys(id),
  };
}

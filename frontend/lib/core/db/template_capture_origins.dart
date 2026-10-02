import 'package:drift/drift.dart';

import 'app_database.dart';

/// Reads only prior schema numbers, in bounded pages, for selected project rows.
/// Raw values survive migration, so privacy still follows their earlier shapes.
Future<Map<String, Set<int>>> readTemplateCaptureOrigins({
  required AppDatabase db,
  required String projectId,
  required List<String> recordIds,
}) async {
  final Map<String, Set<int>> origins = <String, Set<int>>{};
  for (int start = 0; start < recordIds.length; start += 200) {
    final List<String> ids = recordIds.sublist(
      start,
      start + 200 < recordIds.length ? start + 200 : recordIds.length,
    );
    String after = '';
    while (true) {
      final List<QueryRow> rows = await db
          .customSelect(
            'SELECT l.id, l.entity_id, l.previous_value FROM audit_log l '
            'JOIN records r ON r.id = l.entity_id '
            "WHERE l.entity_type = 'records' AND l.field_key = 'template_version' "
            'AND r.project_id = ? AND l.id > ? '
            'AND r.id IN (${List<String>.filled(ids.length, '?').join(',')}) '
            'ORDER BY l.id LIMIT 200',
            variables: <Variable<Object>>[
              Variable<String>(projectId),
              Variable<String>(after),
              for (final String id in ids) Variable<String>(id),
            ],
          )
          .get();
      if (rows.isEmpty) break;
      for (final QueryRow row in rows) {
        final int? version = int.tryParse(
          row.readNullable<String>('previous_value') ?? '',
        );
        if (version != null && version >= 0) {
          (origins[row.read<String>('entity_id')] ??= <int>{}).add(version);
        }
      }
      after = rows.last.read<String>('id');
    }
  }
  return origins;
}

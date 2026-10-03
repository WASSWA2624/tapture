import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/time/clock.dart';

/// The recent values a level's or pin's picker offers first, kept in the
/// project's own `context_state` rows so they survive a restart (spec §20.3:
/// a return visit is two taps).
///
/// Each field's list is one row at [recentsLevel], below the numbers values
/// (1 and up) and pins (0) use, so it is never read back as either. State
/// rows are device-local and never merged, like the values beside them.
final class ContextPersistence {
  /// Opens over [_db]; writes are stamped with [_clock] and [_deviceId].
  ContextPersistence({
    required this._db,
    required this._clock,
    required this._deviceId,
  });

  /// Level number of a recents row.
  static const int recentsLevel = -1;

  final sqlite.AppDatabase _db;
  final Clock _clock;
  final String _deviceId;

  static final int _cap = AppConstants.context.recentCap;

  /// Remembers [value] for [fieldKey] in [projectId], newest first, keeping
  /// at most `AppConstants.context.recentCap`. A blank value is ignored.
  Future<void> rememberRecent({
    required String projectId,
    required String fieldKey,
    required String value,
  }) async {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final sqlite.ContextStateRow? row = await _row(projectId, fieldKey);
    final List<String> list = row == null
        ? <String>[]
        : _decode(row.value).toList();
    list
      ..remove(trimmed)
      ..insert(0, trimmed);
    if (list.length > _cap) {
      list.removeRange(_cap, list.length);
    }
    final DateTime now = _clock.nowUtc();
    if (row == null) {
      await _db
          .into(_db.contextState)
          .insert(
            sqlite.ContextStateCompanion.insert(
              projectId: projectId,
              level: recentsLevel,
              fieldKey: Value<String>(_rowKey(fieldKey)),
              value: jsonEncode(list),
              setAt: now,
              createdAt: now,
              updatedAt: now,
              updatedByDevice: _deviceId,
            ),
          );
      return;
    }
    await (_db.update(
      _db.contextState,
    )..where((sqlite.$ContextStateTable tbl) => tbl.id.equals(row.id))).write(
      sqlite.ContextStateCompanion(
        value: Value<String>(jsonEncode(list)),
        setAt: Value<DateTime>(now),
        updatedAt: Value<DateTime>(now),
        updatedByDevice: Value<String>(_deviceId),
        rev: Value<int>(row.rev + 1),
      ),
    );
  }

  /// Recent values for [fieldKey] in [projectId], newest first.
  Future<List<String>> recents({
    required String projectId,
    required String fieldKey,
  }) async {
    final sqlite.ContextStateRow? row = await _row(projectId, fieldKey);
    return row == null ? <String>[] : _decode(row.value).toList();
  }

  Future<sqlite.ContextStateRow?> _row(String projectId, String fieldKey) {
    return (_db.select(_db.contextState)..where(
          (sqlite.$ContextStateTable tbl) =>
              tbl.projectId.equals(projectId) &
              tbl.level.equals(recentsLevel) &
              tbl.fieldKey.equals(_rowKey(fieldKey)),
        ))
        .getSingleOrNull();
  }

  /// The row's field key: prefixed, so it cannot meet a level's own row
  /// under the (project, field key) uniqueness.
  static String _rowKey(String fieldKey) => 'recent:$fieldKey';

  static Iterable<String> _decode(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is List) {
        return <String>[
          for (final Object? item in decoded)
            if (item is String && item.isNotEmpty) item,
        ];
      }
    } on FormatException {
      // A damaged row reads as no recents; the next choice rewrites it.
    }
    return const <String>[];
  }
}

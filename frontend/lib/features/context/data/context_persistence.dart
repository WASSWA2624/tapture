import 'package:tapture/core/constants/app_constants.dart';

/// Stores recent context values outside Drift so pickers stay fast.
abstract interface class ContextPersistence {
  /// Remembers [value] for [fieldKey] in [projectId], newest first.
  Future<void> rememberRecent({
    required String projectId,
    required String fieldKey,
    required String value,
  });

  /// Recent values for [fieldKey], newest first (capped).
  Future<List<String>> recents({
    required String projectId,
    required String fieldKey,
  });
}

/// In-memory recents for tests and the default repository wiring.
final class MemoryContextPersistence implements ContextPersistence {
  final Map<String, List<String>> _rows = <String, List<String>>{};

  static final int _cap = AppConstants.context.recentCap;

  @override
  Future<void> rememberRecent({
    required String projectId,
    required String fieldKey,
    required String value,
  }) async {
    final String key = '$projectId::$fieldKey';
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final List<String> list = List<String>.of(_rows[key] ?? const <String>[]);
    list.remove(trimmed);
    list.insert(0, trimmed);
    if (list.length > _cap) {
      list.removeRange(_cap, list.length);
    }
    _rows[key] = list;
  }

  @override
  Future<List<String>> recents({
    required String projectId,
    required String fieldKey,
  }) async {
    return List<String>.of(_rows['$projectId::$fieldKey'] ?? const <String>[]);
  }
}

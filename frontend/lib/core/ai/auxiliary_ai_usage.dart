import 'dart:convert';

/// Counts text-only AI requests outside record processing against the same cap.
final class AuxiliaryAiUsage {
  /// Reads the persisted UTC-day counts. Malformed storage fails closed.
  const AuxiliaryAiUsage(this.raw);

  /// Serialized counters only; never prompts, results or project content.
  final String raw;

  /// Requests reserved for [day], optionally limited to one project.
  int count(DateTime day, {String? projectId}) {
    final Map<String, Object?> rows = _read();
    if (rows['day'] != _day(day)) return 0;
    final Object? counts = rows['projects'];
    if (counts is! Map<String, Object?>) return 0;
    if (projectId != null) return counts[projectId] as int? ?? 0;
    return counts.values.whereType<int>().fold(
      0,
      (int total, int value) => total + value,
    );
  }

  /// Reserves before egress; failed calls remain counted to bound retries.
  String reserve(DateTime day, String projectId) {
    final Map<String, Object?> previous = _read();
    final Object? saved = previous['projects'];
    final Map<String, Object?> counts =
        previous['day'] == _day(day) && saved is Map<String, Object?>
        ? Map<String, Object?>.of(saved)
        : <String, Object?>{};
    counts[projectId] = count(day, projectId: projectId) + 1;
    return jsonEncode(<String, Object?>{'day': _day(day), 'projects': counts});
  }

  Map<String, Object?> _read() {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) throw const FormatException();
    return decoded;
  }

  static String _day(DateTime time) {
    final DateTime utc = time.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day).toIso8601String();
  }
}

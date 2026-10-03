import 'package:tapture/core/copy/copy.dart';

/// How a person recognises [recordId] in [tables]: its caption, else a
/// short form of its id (task 076, W21). Captions are data (FE-SEC-05).
String mergeRecordLabel(
  Map<String, List<Map<String, Object?>>> tables,
  String recordId, {
  LocalizedCopy? localizedCopy,
}) {
  for (final Map<String, Object?> caption
      in tables['captions'] ?? const <Map<String, Object?>>[]) {
    if (caption['owner_id'] != recordId) {
      continue;
    }
    final Object? refined = caption['text_refined'];
    final String text = refined is String && refined.trim().isNotEmpty
        ? refined
        : '${caption['text_raw'] ?? ''}';
    if (text.trim().isNotEmpty) {
      return text.trim();
    }
  }
  return (localizedCopy ?? Copy.english).mergeRecordUnnamed(recordId);
}

/// A stored instant, whole seconds since the epoch, as a time; null when it
/// is not one.
DateTime? mergeInstant(Object? at) {
  return at is int
      ? DateTime.fromMillisecondsSinceEpoch(at * 1000, isUtc: true)
      : null;
}

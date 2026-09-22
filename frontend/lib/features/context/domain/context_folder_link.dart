import 'package:tapture/core/files/path_sanitizer.dart';
import 'package:tapture/core/files/photo_path_builder.dart';

import 'context_state.dart';

/// Builds photo folder segments from a record's context snapshot.
abstract final class ContextFolderLink {
  /// Ordered, filesystem-safe level values from a snapshot or live state.
  static List<String> pathValues({
    Map<String, Object?>? snapshot,
    ContextState? state,
  }) {
    if (snapshot != null) {
      final Object? levels = snapshot['levels'];
      if (levels is List) {
        final List<({int order, String value})> rows =
            <({int order, String value})>[];
        for (final Object? item in levels) {
          if (item is! Map) {
            continue;
          }
          final Object? order = item['order'];
          final Object? value = item['value'];
          rows.add((
            order: order is int ? order : 0,
            value: value?.toString() ?? '',
          ));
        }
        rows.sort(
          (({int order, String value}) a, ({int order, String value}) b) =>
              a.order.compareTo(b.order),
        );
        return <String>[
          for (final ({int order, String value}) row in rows)
            _segment(row.value),
        ];
      }
      final Object? values = snapshot['values'];
      if (values is Map) {
        return <String>[
          for (final Object? value in values.values) _segment('${value ?? ''}'),
        ];
      }
    }
    if (state != null) {
      final List<ContextLevel> ordered = List<ContextLevel>.of(state.levels)
        ..sort((ContextLevel a, ContextLevel b) => a.order.compareTo(b.order));
      return <String>[
        for (final ContextLevel level in ordered)
          _segment(state.values[level.fieldKey] ?? ''),
      ];
    }
    return const <String>[];
  }

  static String _segment(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return sanitiseSegment(trimmed);
  }

  /// Relative photo folder from a record snapshot under [strategy].
  static String photoFolder({
    required PhotoFolderStrategy strategy,
    required Map<String, Object?> snapshot,
    DateTime? capturedAt,
    String? templateName,
  }) {
    return buildPhotoPath(
      strategy: strategy,
      contextValues: pathValues(snapshot: snapshot),
      capturedAt: capturedAt,
      templateName: templateName,
    );
  }
}

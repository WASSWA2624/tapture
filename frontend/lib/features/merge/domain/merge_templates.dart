import 'dart:convert';

/// Template versions merge without rewriting a record's captured version.
final class MergeTemplates {
  /// Canonical authored shape, excluding causal stamps and local history.
  static String content(
    Map<String, List<Map<String, Object?>>> tables,
    Map<String, Object?> header,
  ) {
    const Set<String> stamps = <String>{
      'id',
      'template_id',
      'project_id',
      'created_at',
      'updated_at',
      'updated_by_device',
      'rev',
    };
    Map<String, Object?> authored(Map<String, Object?> row) =>
        <String, Object?>{
          for (final MapEntry<String, Object?> entry in row.entries)
            if (!stamps.contains(entry.key))
              entry.key: entry.key == 'detection' && entry.value is String
                  ? _detectionContent(entry.value! as String)
                  : entry.value,
        };
    List<Map<String, Object?>> children(String table, String key) =>
        <Map<String, Object?>>[
          for (final Map<String, Object?> row in tables[table] ?? const [])
            if (row['template_id'] == header['id']) authored(row),
        ]..sort(
          (Map<String, Object?> a, Map<String, Object?> b) =>
              '${a[key]}'.compareTo('${b[key]}'),
        );
    return _canonicalJson(<String, Object?>{
      'header': authored(header),
      'fields': children('template_fields', 'field_key'),
      'rows': children('template_rows', 'identifier'),
    });
  }

  /// An unchanged incoming shape previously kept as a separate template.
  static Map<String, Object?>? copyFor(
    Map<String, Object?> incomingHeader,
    Map<String, List<Map<String, Object?>>> incoming,
    Map<String, List<Map<String, Object?>>> local,
  ) {
    final String shape = content(incoming, incomingHeader);
    for (final Map<String, Object?> header in local['templates'] ?? const []) {
      final Object? stored = header['detection'];
      if (stored is! String) continue;
      final Object? decoded = jsonDecode(stored);
      final Object? provenance = decoded is Map
          ? decoded['_tapture_merge_source']
          : null;
      if (provenance is Map &&
          provenance['id'] == incomingHeader['id'] &&
          provenance['shape'] == shape &&
          content(local, header) == shape) {
        return header;
      }
    }
    return null;
  }

  /// Whether an exact received shape has already been retained in history.
  static bool remembersVersion(
    Map<String, Object?> peer,
    Map<String, List<Map<String, Object?>>> incoming,
    Map<String, Object?> here,
  ) => _remembered(here)['${peer['version'] ?? 1}'] == content(incoming, peer);

  /// A version already names another captured shape and must remain separate.
  static bool hasVersionCollision(
    Map<String, Object?> peer,
    Map<String, List<Map<String, Object?>>> incoming,
    Map<String, Object?> here,
    Map<String, List<Map<String, Object?>>> local,
  ) {
    final Object? knownPeer = _remembered(here)['${peer['version'] ?? 1}'];
    final Object? knownLocal = _remembered(peer)['${here['version'] ?? 1}'];
    return (knownPeer != null && knownPeer != content(incoming, peer)) ||
        (knownLocal != null && knownLocal != content(local, here));
  }

  /// Same version is no action. Different versions offer choose one or keep
  /// both. [capturedVersion] is returned unchanged either way.
  static TemplateMerge resolve({
    required int localVersion,
    required int incomingVersion,
    required int capturedVersion,
    required bool keepBoth,
  }) {
    if (localVersion == incomingVersion) {
      return (action: TemplateAction.same, recordVersion: capturedVersion);
    }
    return (
      action: keepBoth ? TemplateAction.keepBoth : TemplateAction.chooseOne,
      recordVersion: capturedVersion,
    );
  }
}

/// What to do with two template versions.
enum TemplateAction { same, chooseOne, keepBoth }

/// The decision and the version the record keeps.
typedef TemplateMerge = ({TemplateAction action, int recordVersion});

Object? _detectionContent(String value) {
  final Object? decoded = jsonDecode(value);
  if (decoded is! Map) return decoded;
  return <String, Object?>{
    for (final MapEntry<Object?, Object?> entry in decoded.entries)
      if (entry.key != '_tapture_versions' &&
          entry.key != '_tapture_merge_shapes' &&
          entry.key != '_tapture_merge_source')
        '${entry.key}': entry.value,
  };
}

Map<String, Object?> _remembered(Map<String, Object?> header) {
  final Object? value = header['detection'];
  final Object? decoded = value is String ? jsonDecode(value) : value;
  final Object? shapes = decoded is Map
      ? decoded['_tapture_merge_shapes']
      : null;
  return shapes is Map
      ? shapes.cast<String, Object?>()
      : const <String, Object?>{};
}

String _canonicalJson(Object? value) {
  Object? ordered(Object? node) {
    if (node is Map) {
      final List<String> keys = node.keys.cast<String>().toList()..sort();
      return <String, Object?>{
        for (final String key in keys) key: ordered(node[key]),
      };
    }
    if (node is List) return node.map(ordered).toList();
    return node;
  }

  return jsonEncode(ordered(value));
}

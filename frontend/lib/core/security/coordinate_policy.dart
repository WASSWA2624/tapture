import 'dart:convert';

/// Recognizes coordinate fields consistently for removal and export privacy.
abstract final class CoordinatePolicy {
  /// Field keys, declared coordinate types and GPS automatic sources agree.
  static bool isField({
    required String key,
    String? type,
    String? autoFill,
    String? validation,
  }) =>
      isKey(key) ||
      _normalize(autoFill ?? '') == 'gps' ||
      _storedGps(validation) ||
      _types.contains(_normalize(type ?? ''));

  /// Known coordinate names are insensitive to case and punctuation.
  /// GPS metadata also belongs to the captured location being removed.
  static bool isKey(String key) {
    final String normalized = _normalize(key).replaceFirst(_numericSuffix, '');
    if (_keys.contains(normalized) || normalized == 'gps') return true;
    if (!normalized.startsWith('gps')) return false;
    final String suffix = normalized.substring(3);
    return _keys.contains(suffix) || _gpsMetadata.contains(suffix);
  }

  /// Reads canonical and earlier compact immutable template snapshots.
  static Map<int, Set<String>> historicalFieldVersions(Object? detection) {
    final Object? decoded = _decoded(detection);
    if (decoded is! Map) return const <int, Set<String>>{};
    final Object? versions = decoded['_tapture_versions'];
    if (versions is! Map) return const <int, Set<String>>{};
    return <int, Set<String>>{
      for (final MapEntry<Object?, Object?> entry in versions.entries)
        if (int.tryParse('${entry.key}') case final int version)
          if (entry.value case final Map<Object?, Object?> snapshot)
            version: snapshotFields(snapshot['fields']),
    };
  }

  /// Classifies only the captured shape when its version is known.
  /// Old recovery drafts without a version conservatively include GPS history.
  static Set<String> forVersion({
    required Set<String> current,
    required Map<int, Set<String>> history,
    required int currentVersion,
    int? capturedVersion,
  }) {
    if (capturedVersion != null && capturedVersion > 0) {
      if (capturedVersion == currentVersion) return current;
      if (history[capturedVersion] case final Set<String> keys) return keys;
    }
    return <String>{
      ...current,
      for (final Set<String> keys in history.values) ...keys,
    };
  }

  /// Shares saved field classification without importing feature model types.
  static Set<String> snapshotFields(Object? fields) {
    if (fields is! List) return const <String>{};
    return <String>{
      for (final Object? field in fields)
        if (field is Map)
          if ((field['field_key'] ?? field['fieldKey']) case final String key)
            if (isField(
              key: key,
              type: _text(field['type']),
              autoFill: _text(field['auto_fill'] ?? field['autoFill']),
              validation: field['validation'] is Map
                  ? jsonEncode(field['validation'])
                  : _text(field['validation']),
            ))
              key,
    };
  }

  /// Migration retains retired values; their absent GPS definitions stay private.
  /// A name retyped to ordinary data still exists and keeps its current meaning.
  static Set<String> withRetiredFields({
    required Set<String> current,
    required Set<String> defined,
    required Map<int, Set<String>> history,
  }) => <String>{
    ...current,
    for (final Set<String> keys in history.values)
      for (final String key in keys)
        if (!defined.contains(key)) key,
  };

  /// Migration keeps raw values and frozen context from their earlier shapes.
  static Set<String> withMigrationHistory({
    required Set<String> current,
    required Map<int, Set<String>> history,
    required int currentVersion,
    required Iterable<int> previousVersions,
  }) => <String>{
    ...current,
    for (final int version in previousVersions)
      ...forVersion(
        current: current,
        history: history,
        currentVersion: currentVersion,
        capturedVersion: version,
      ),
  };
}

String? _text(Object? value) => value is String ? value : null;

Object? _decoded(Object? value) {
  if (value is! String) return value;
  try {
    return jsonDecode(value);
  } on FormatException {
    return null;
  }
}

bool _storedGps(String? validation) {
  if (validation == null || validation.isEmpty) return false;
  try {
    final Object? decoded = jsonDecode(validation);
    if (decoded is! Map) return false;
    final Object? attributes = decoded['_tapture'];
    if (attributes is! Map) return false;
    final Object? source = attributes['autoFill'];
    return source is String && _normalize(source) == 'gps';
  } on FormatException {
    return false;
  }
}

String _normalize(String value) =>
    value.toLowerCase().replaceAll(_punctuation, '');

final RegExp _punctuation = RegExp('[^a-z0-9]');
final RegExp _numericSuffix = RegExp(r'\d+$');
const Set<String> _keys = <String>{
  'latitude',
  'longitude',
  'lat',
  'lon',
  'lng',
  'latlon',
  'latlng',
  'latitudelongitude',
  'coordinate',
  'coordinates',
  'geolocation',
  'geocoordinates',
};
const Set<String> _types = <String>{..._keys, 'gps', 'gpslocation', 'location'};
const Set<String> _gpsMetadata = <String>{
  'location',
  'accuracy',
  'accuracym',
  'accuracymetres',
  'accuracymeters',
  'altitude',
  'altitudem',
  'altitudemetres',
  'altitudemeters',
  'capturedat',
  'timestamp',
  'bearing',
  'speed',
  'fix',
  'metadata',
};

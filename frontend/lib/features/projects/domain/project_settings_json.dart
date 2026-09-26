part of 'project_settings.dart';

// The JSON keys and the readers that validate each one. A reader returns
// null for a value of the wrong shape, so a malformed key is unset rather
// than a throw.

const String _aiEnabled = 'aiEnabled';
const String _doNotSendImages = 'doNotSendImages';
const String _gpsEnabled = 'gpsEnabled';
const String _folderStrategy = 'folderStrategy';
const String _photoFolderStrategy = 'photoFolderStrategy';
const String _confidenceHigh = 'confidenceHigh';
const String _confidenceMedium = 'confidenceMedium';
const String _refineColumns = 'refineColumns';
const String _refinedColumns = 'refinedColumns';
const String _templateChoice = 'templateChoice';
const String _coverPhoto = 'coverPhoto';
const String _coverPath = 'path';
const String _coverSha256 = 'sha256';
const String _refineCaptions = 'refineCaptions';
const String _dailyRequestCap = 'dailyRequestCap';
const String _locale = 'locale';
const String _providerSelection = 'providerSelection';
const String _selectionProvider = 'provider';
const String _selectionModel = 'model';
const String _templatePins = 'templatePins';

const Set<String> _templateChoices = <String>{'auto', 'suggest', 'manual'};

const Set<String> _folderStrategies = <String>{
  'byContext',
  'byTemplate',
  'byCaptureDate',
  'flat',
};

bool? _bool(Object? raw) => raw is bool ? raw : null;

double? _number(Object? raw) {
  if (raw is double) {
    return raw;
  }
  if (raw is num) {
    return raw.toDouble();
  }
  return null;
}

/// A whole number that is not negative.
int? _count(Object? raw) => raw is int && raw >= 0 ? raw : null;

/// A string with something in it.
String? _text(Object? raw) =>
    raw is String && raw.trim().isNotEmpty ? raw : null;

String? _readTemplateChoice(Object? raw) {
  if (raw is String && _templateChoices.contains(raw)) {
    return raw;
  }
  return null;
}

ProjectCoverPhoto? _readCoverPhoto(Object? raw) {
  if (raw is! Map) {
    return null;
  }
  final Object? path = raw[_coverPath];
  final Object? sha256 = raw[_coverSha256];
  if (path is! String || path.isEmpty || sha256 is! String) {
    return null;
  }
  return (path: path, sha256: sha256);
}

String? _readFolderStrategy(Object? raw) {
  if (raw is String && _folderStrategies.contains(raw)) {
    return raw;
  }
  return null;
}

/// The per-operation choices in [raw]. An entry without a provider and a
/// model is skipped; a non-object is null.
Map<String, ({String provider, String model})>? _readProviderSelection(
  Object? raw,
) {
  if (raw is! Map) {
    return null;
  }
  final Map<String, ({String provider, String model})> selection =
      <String, ({String provider, String model})>{};
  for (final MapEntry<Object?, Object?> entry in raw.entries) {
    final Object? operation = entry.key;
    final Object? choice = entry.value;
    if (operation is! String || operation.isEmpty || choice is! Map) {
      continue;
    }
    final String? provider = _text(choice[_selectionProvider]);
    final String? model = _text(choice[_selectionModel]);
    if (provider == null || model == null) {
      continue;
    }
    selection[operation] = (provider: provider, model: model);
  }
  return Map<String, ({String provider, String model})>.unmodifiable(selection);
}

Map<String, Object?> _writeProviderSelection(
  Map<String, ({String provider, String model})> selection,
) {
  return <String, Object?>{
    for (final MapEntry<String, ({String provider, String model})> entry
        in selection.entries)
      entry.key: <String, Object?>{
        _selectionProvider: entry.value.provider,
        _selectionModel: entry.value.model,
      },
  };
}

/// The context pins in [raw]. A pin without a key or a template id is
/// skipped; a non-object is null.
Map<String, String>? _readTemplatePins(Object? raw) {
  if (raw is! Map) {
    return null;
  }
  return Map<String, String>.unmodifiable(<String, String>{
    for (final MapEntry<Object?, Object?> entry in raw.entries)
      if (_text(entry.key) case final String pin)
        if (_text(entry.value) case final String templateId) pin: templateId,
  });
}

bool _sameMap<K, V>(Map<K, V>? left, Map<K, V>? right) {
  if (identical(left, right)) {
    return true;
  }
  if (left == null || right == null || left.length != right.length) {
    return false;
  }
  for (final MapEntry<K, V> entry in left.entries) {
    if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int? _mapHash<K, V>(Map<K, V>? map) {
  if (map == null) {
    return null;
  }
  return Object.hashAllUnordered(<int>[
    for (final MapEntry<K, V> entry in map.entries)
      Object.hash(entry.key, entry.value),
  ]);
}

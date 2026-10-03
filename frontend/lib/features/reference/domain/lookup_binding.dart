import 'package:tapture/core/copy/domain_copy.g.dart';

/// How a template field binds to a [ReferenceDataset] (§12.2 / §16).
final class LookupBinding {
  /// Creates a binding. [matchColumns] are tried in order; [fillMapping]
  /// maps dataset column → template field key.
  const LookupBinding({
    required this.datasetId,
    required this.matchColumns,
    required this.fillMapping,
    this.fuzzyEnabled = false,
    this.fuzzyThreshold = 0.8,
    this.onNoMatch = NoMatchBehaviour.leaveEmpty,
  });

  /// Dataset this field looks up against.
  final String datasetId;

  /// Columns tried in order — key first, then name, then extras.
  final List<String> matchColumns;

  /// Dataset column → template field key.
  final Map<String, String> fillMapping;

  /// Whether a scored fuzzy fallback is allowed after exact matches fail.
  final bool fuzzyEnabled;

  /// Minimum fuzzy score (0–1) before a near miss is offered.
  final double fuzzyThreshold;

  /// What the capture screen does when nothing matches.
  final NoMatchBehaviour onNoMatch;

  /// Reads a binding from a [FieldDef.lookup] map, or null when empty.
  ///
  /// Reads the attribute [toMap] writes and the §16.2 wire form alike:
  /// `dataset`, `match_on`, `fuzzy`, `fills` (template field → dataset
  /// column) and `on_no_match`, so an imported template stays bound.
  static LookupBinding? fromMap(Map<String, Object?> raw) {
    if (raw.isEmpty) {
      return null;
    }
    final Object? datasetId = raw['datasetId'] ?? raw['dataset'];
    if (datasetId is! String || datasetId.isEmpty) {
      return null;
    }
    final Object? fills = raw['fills'];
    return LookupBinding(
      datasetId: datasetId,
      matchColumns: _stringList(raw['matchColumns'] ?? raw['match_on']),
      fillMapping: fills is Map && raw['fillMapping'] == null
          ? <String, String>{
              for (final MapEntry<String, String> fill in _stringMap(
                fills,
              ).entries)
                fill.value: fill.key,
            }
          : _stringMap(raw['fillMapping']),
      fuzzyEnabled: (raw['fuzzyEnabled'] ?? raw['fuzzy']) == true,
      fuzzyThreshold: _doubleOf(
        raw['fuzzyThreshold'] ?? raw['fuzzy_threshold'],
        0.8,
      ),
      onNoMatch: _behaviourOf(raw['onNoMatch'] ?? raw['on_no_match']),
    );
  }

  /// Writes this binding as a §12.2 `lookup` attribute map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'datasetId': datasetId,
      'matchColumns': matchColumns,
      'fillMapping': fillMapping,
      'fuzzyEnabled': fuzzyEnabled,
      'fuzzyThreshold': fuzzyThreshold,
      'onNoMatch': onNoMatch.name,
    };
  }

  /// Refuses an unknown fill target or two dataset columns into one field.
  static String? validate({
    required LookupBinding binding,
    required Set<String> templateFieldKeys,
  }) => validationMessage(
    binding: binding,
    templateFieldKeys: templateFieldKeys,
  )?.fallback;

  /// Retains the fill-rule explanation until the editor chooses its locale.
  static LocalizedMessage? validationMessage({
    required LookupBinding binding,
    required Set<String> templateFieldKeys,
  }) {
    final Set<String> seenTargets = <String>{};
    for (final MapEntry<String, String> entry in binding.fillMapping.entries) {
      final String target = entry.value;
      if (!templateFieldKeys.contains(target)) {
        return DomainCopy.messages.lookupUnknownTarget(target);
      }
      if (!seenTargets.add(target)) {
        return DomainCopy.messages.lookupTargetTwice(target);
      }
    }
    return null;
  }

  @override
  int get hashCode => Object.hash(
    datasetId,
    Object.hashAll(matchColumns),
    Object.hashAll(
      fillMapping.entries.map(
        (MapEntry<String, String> e) => Object.hash(e.key, e.value),
      ),
    ),
    fuzzyEnabled,
    fuzzyThreshold,
    onNoMatch,
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LookupBinding &&
            other.datasetId == datasetId &&
            _listEquals(other.matchColumns, matchColumns) &&
            _mapEquals(other.fillMapping, fillMapping) &&
            other.fuzzyEnabled == fuzzyEnabled &&
            other.fuzzyThreshold == fuzzyThreshold &&
            other.onNoMatch == onNoMatch);
  }
}

/// What happens when a lookup finds no row.
enum NoMatchBehaviour {
  /// Leave the bound fields empty.
  leaveEmpty,

  /// Offer the add-row sheet so the operator can create a match.
  promptAddRow,

  /// Warn without filling or prompting to add.
  warn,
}

List<String> _stringList(Object? raw) {
  if (raw is! List) {
    return const <String>[];
  }
  return <String>[
    for (final Object? item in raw)
      if (item is String) item,
  ];
}

Map<String, String> _stringMap(Object? raw) {
  if (raw is! Map) {
    return const <String, String>{};
  }
  final Map<String, String> out = <String, String>{};
  for (final MapEntry<Object?, Object?> entry in raw.entries) {
    final Object? key = entry.key;
    final Object? value = entry.value;
    if (key is String && value is String) {
      out[key] = value;
    }
  }
  return out;
}

double _doubleOf(Object? raw, double fallback) {
  if (raw is num) {
    return raw.toDouble();
  }
  return fallback;
}

NoMatchBehaviour _behaviourOf(Object? raw) {
  if (raw is String) {
    for (final NoMatchBehaviour value in NoMatchBehaviour.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return _wireBehaviours[raw] ?? NoMatchBehaviour.leaveEmpty;
  }
  return NoMatchBehaviour.leaveEmpty;
}

/// The §16.2 `on_no_match` spellings.
const Map<String, NoMatchBehaviour> _wireBehaviours =
    <String, NoMatchBehaviour>{
      'ALLOW_FREE_TEXT_AND_OFFER_ADD': NoMatchBehaviour.promptAddRow,
      'OFFER_ADD': NoMatchBehaviour.promptAddRow,
      'ALLOW_FREE_TEXT': NoMatchBehaviour.leaveEmpty,
      'LEAVE_EMPTY': NoMatchBehaviour.leaveEmpty,
      'WARN': NoMatchBehaviour.warn,
    };

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (int i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

bool _mapEquals(Map<String, String> left, Map<String, String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (final MapEntry<String, String> entry in left.entries) {
    if (right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

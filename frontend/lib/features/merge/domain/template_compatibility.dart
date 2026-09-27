import 'package:tapture/core/bundle/template_key.dart';

import 'compatibility_issue.dart';
import 'compatibility_report.dart';
import 'template_match.dart';

/// Decides whether a package's templates can take their records into a
/// project (task 076, W20, D15). Pure: rows in, a report out, nothing
/// written (FE-STR-05). Rows are keyed by SQL column name.
abstract final class TemplateCompatibility {
  /// Matches each incoming template a record uses against [local]'s
  /// templates: the same id first, otherwise the same stable key, the one
  /// sharing the most fields winning, then the higher version.
  ///
  /// A template with no match blocks, except in [sameProject], where it is
  /// a template the other device added and arrives whole. A filled incoming
  /// field missing locally blocks, and so does one whose local type cannot
  /// hold its values: identical types can, text and long text hold
  /// anything, and decimal holds number. Every other difference warns.
  static CompatibilityReport check({
    required Map<String, List<Map<String, Object?>>> incoming,
    required Map<String, List<Map<String, Object?>>> local,
    required bool sameProject,
  }) {
    final Map<String, String> templateOfRecord = <String, String>{
      for (final Map<String, Object?> record in _rows(incoming, 'records'))
        record['id']! as String: record['template_id']! as String,
    };
    final Map<String, Set<String>> filled = <String, Set<String>>{};
    for (final Map<String, Object?> value in _rows(incoming, 'record_fields')) {
      final String? template = templateOfRecord[value['record_id']];
      if (template != null && _effective(value).isNotEmpty) {
        filled
            .putIfAbsent(template, () => <String>{})
            .add(value['field_key']! as String);
      }
    }
    final Set<String> used = templateOfRecord.values.toSet();
    final List<Map<String, Object?>> localTemplates = _rows(local, 'templates');
    final Map<String, List<Map<String, Object?>>> localFields =
        _fieldsByTemplate(_rows(local, 'template_fields'));
    final Map<String, List<Map<String, Object?>>> incomingFields =
        _fieldsByTemplate(_rows(incoming, 'template_fields'));
    return CompatibilityReport(<TemplateMatch>[
      for (final Map<String, Object?> template in _rows(incoming, 'templates'))
        if (used.contains(template['id']))
          _match(
            template,
            fields: incomingFields[template['id']] ?? const [],
            filled: filled[template['id']] ?? const <String>{},
            localTemplates: localTemplates,
            localFields: localFields,
            sameProject: sameProject,
          ),
    ]);
  }

  static TemplateMatch _match(
    Map<String, Object?> template, {
    required List<Map<String, Object?>> fields,
    required Set<String> filled,
    required List<Map<String, Object?>> localTemplates,
    required Map<String, List<Map<String, Object?>>> localFields,
    required bool sameProject,
  }) {
    final String id = template['id']! as String;
    final String key = templateKeyOf(template);
    final String name = (template['name'] as String?) ?? key;
    Map<String, Object?>? chosen;
    for (final Map<String, Object?> candidate in localTemplates) {
      if (candidate['id'] == id) {
        chosen = candidate;
      }
    }
    if (chosen == null && key.isNotEmpty) {
      final Set<String> keys = <String>{
        for (final Map<String, Object?> field in fields)
          field['field_key']! as String,
      };
      var best = -1;
      for (final Map<String, Object?> candidate in localTemplates) {
        if (templateKeyOf(candidate) != key) {
          continue;
        }
        final int shared = <String>{
          for (final Map<String, Object?> field
              in localFields[candidate['id']] ?? const [])
            field['field_key']! as String,
        }.intersection(keys).length;
        final bool better =
            shared > best ||
            (shared == best &&
                _version(candidate) > _version(chosen ?? const {}));
        if (better) {
          best = shared;
          chosen = candidate;
        }
      }
    }
    if (chosen == null) {
      return TemplateMatch(
        incomingId: id,
        name: name,
        templateKey: key,
        issues: sameProject
            ? const <({CompatibilityIssue issue, String field})>[]
            : const <({CompatibilityIssue issue, String field})>[
                (issue: CompatibilityIssue.noMatch, field: ''),
              ],
      );
    }
    final String localId = chosen['id']! as String;
    final Map<String, Map<String, Object?>> mine =
        <String, Map<String, Object?>>{
          for (final Map<String, Object?> field
              in localFields[localId] ?? const [])
            field['field_key']! as String: field,
        };
    final List<({CompatibilityIssue issue, String field})> issues =
        <({CompatibilityIssue issue, String field})>[];
    if (_version(chosen) != _version(template)) {
      issues.add((issue: CompatibilityIssue.otherVersion, field: ''));
    }
    final Set<String> theirKeys = <String>{};
    for (final Map<String, Object?> field in fields) {
      final String fieldKey = field['field_key']! as String;
      theirKeys.add(fieldKey);
      final String label = _label(field);
      final Map<String, Object?>? here = mine[fieldKey];
      final bool holdsValues = filled.contains(fieldKey);
      if (here == null) {
        issues.add((
          issue: holdsValues
              ? CompatibilityIssue.missingField
              : CompatibilityIssue.unfilledMissing,
          field: label,
        ));
        continue;
      }
      final String theirType = field['type'] as String? ?? '';
      final String myType = here['type'] as String? ?? '';
      if (theirType != myType) {
        issues.add((
          issue: holdsValues && !_holds(myType, theirType)
              ? CompatibilityIssue.typeCannotHold
              : CompatibilityIssue.changedType,
          field: label,
        ));
      }
      if (_label(here) != label) {
        issues.add((issue: CompatibilityIssue.changedLabel, field: label));
      }
      if (field['required'] != here['required']) {
        issues.add((
          issue: CompatibilityIssue.changedRequiredness,
          field: label,
        ));
      }
    }
    final List<String> localOnly = <String>[
      for (final MapEntry<String, Map<String, Object?>> field in mine.entries)
        if (!theirKeys.contains(field.key)) _label(field.value),
    ];
    for (final String label in localOnly) {
      issues.add((issue: CompatibilityIssue.localOnlyFields, field: label));
    }
    return TemplateMatch(
      incomingId: id,
      name: name,
      templateKey: key,
      localId: localId,
      issues: issues,
    );
  }
}

/// Whether a local field of [local] type can hold values typed as
/// [incoming].
bool _holds(String local, String incoming) {
  if (local == incoming || _textual.contains(local)) {
    return true;
  }
  return local == 'decimal' && incoming == 'number';
}

const Set<String> _textual = <String>{'text', 'longText', 'long_text'};

int _version(Map<String, Object?> template) {
  final Object? version = template['version'];
  return version is int ? version : 1;
}

String _label(Map<String, Object?> field) {
  final Object? label = field['label'];
  return label is String && label.trim().isNotEmpty
      ? label.trim()
      : field['field_key']! as String;
}

/// A field row's value as a reader sees it: final, then refined, then raw.
String _effective(Map<String, Object?> value) {
  for (final String column in const <String>[
    'value_final',
    'value_refined',
    'value_raw',
  ]) {
    final Object? text = value[column];
    if (text is String && text.trim().isNotEmpty) {
      return text;
    }
  }
  return '';
}

List<Map<String, Object?>> _rows(
  Map<String, List<Map<String, Object?>>> tables,
  String table,
) {
  return tables[table] ?? const <Map<String, Object?>>[];
}

Map<String, List<Map<String, Object?>>> _fieldsByTemplate(
  List<Map<String, Object?>> fields,
) {
  final Map<String, List<Map<String, Object?>>> byTemplate =
      <String, List<Map<String, Object?>>>{};
  for (final Map<String, Object?> field in fields) {
    byTemplate
        .putIfAbsent(field['template_id']! as String, () => [])
        .add(field);
  }
  return byTemplate;
}

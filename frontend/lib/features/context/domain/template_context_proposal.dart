import 'package:tapture/features/templates/templates.dart';

/// Stable hierarchy suggestions and any ambiguity that requires attention.
final class TemplateContextProposal {
  /// Creates a proposal result.
  const TemplateContextProposal({
    required this.levels,
    required this.conflicts,
  });

  /// Builds proposals in level, template, then field order.
  factory TemplateContextProposal.fromTemplates(
    List<TemplateDef> templates, {
    String? projectId,
  }) {
    final List<({int template, int field, FieldDef value})> declared =
        <({int template, int field, FieldDef value})>[];
    for (
      int templateIndex = 0;
      templateIndex < templates.length;
      templateIndex++
    ) {
      final TemplateDef template = templates[templateIndex];
      if (projectId != null && template.projectId != projectId) {
        continue;
      }
      for (
        int fieldIndex = 0;
        fieldIndex < template.fields.length;
        fieldIndex++
      ) {
        final FieldDef field = template.fields[fieldIndex];
        if ((field.contextLevel ?? 0) > 0) {
          declared.add((
            template: templateIndex,
            field: fieldIndex,
            value: field,
          ));
        }
      }
    }
    declared.sort((a, b) {
      final int byLevel = a.value.contextLevel!.compareTo(
        b.value.contextLevel!,
      );
      if (byLevel != 0) return byLevel;
      final int byTemplate = a.template.compareTo(b.template);
      return byTemplate != 0 ? byTemplate : a.field.compareTo(b.field);
    });

    final Map<int, String> keyAtLevel = <int, String>{};
    final Map<String, int> levelForKey = <String, int>{};
    final Set<String> seen = <String>{};
    final List<String> conflicts = <String>[];
    final List<TemplateContextLevelProposal> levels =
        <TemplateContextLevelProposal>[];
    for (final row in declared) {
      final FieldDef field = row.value;
      final int level = field.contextLevel!;
      final String? existingKey = keyAtLevel[level];
      if (existingKey != null && existingKey != field.fieldKey) {
        conflicts.add('Level $level: $existingKey / ${field.fieldKey}');
        continue;
      }
      final int? existingLevel = levelForKey[field.fieldKey];
      if (existingLevel != null && existingLevel != level) {
        conflicts.add('${field.fieldKey}: Level $existingLevel / Level $level');
        continue;
      }
      keyAtLevel[level] = field.fieldKey;
      levelForKey[field.fieldKey] = level;
      if (seen.add(field.fieldKey)) {
        levels.add((level: level, field: field));
      }
    }
    return TemplateContextProposal(
      levels: List<TemplateContextLevelProposal>.unmodifiable(levels),
      conflicts: List<String>.unmodifiable(conflicts),
    );
  }

  /// Ordered proposals.
  final List<TemplateContextLevelProposal> levels;

  /// Duplicate levels or keys that were not guessed through.
  final List<String> conflicts;

  /// Whether template declarations need correction before bulk use.
  bool get hasConflicts => conflicts.isNotEmpty;
}

/// One template-declared hierarchy level: one-based level and source field.
typedef TemplateContextLevelProposal = ({int level, FieldDef field});

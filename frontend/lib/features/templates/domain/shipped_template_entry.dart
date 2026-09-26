import 'field_def.dart';
import 'shipped_catalogue_category.dart';
import 'shipped_record_type.dart';
import 'shipped_template_category.dart';
import 'template_def.dart';

export 'shipped_catalogue_category.dart';
export 'shipped_record_type.dart';

/// One shipped template as the library lists it: enough to show, search and
/// filter it without resolving its fields, which only a preview or a copy
/// needs.
final class ShippedTemplateEntry {
  /// Creates an entry.
  const ShippedTemplateEntry({
    required this.templateKey,
    required this.kind,
    required this.fieldCount,
    this.title,
    this.code,
    this.category,
    this.recordType,
    this.privacy = '',
    this.rollout = '',
    this.fieldKeys = const <String>[],
  });

  /// The entry for a starter template of §13.4, from its resolved fields.
  factory ShippedTemplateEntry.starter(TemplateDef template) {
    return ShippedTemplateEntry(
      templateKey: template.templateKey,
      kind: template.kind,
      fieldCount: template.fields.length,
      fieldKeys: <String>[
        for (final FieldDef field in template.fields)
          if (!_inheritedGroups.contains(field.group)) field.fieldKey,
      ],
    );
  }

  /// Stable key, for example `uni_general_observation`.
  final String templateKey;

  /// Kind of thing the template captures.
  final String kind;

  /// Columns once every inherited group is resolved.
  final int fieldCount;

  /// The catalogue's name for it. Null for a starter template, whose name
  /// the copy helper gives.
  final String? title;

  /// Catalogue code, for example `UNI-001`. Null for a starter template.
  final String? code;

  /// Catalogue category. Null for a starter template.
  final ShippedCatalogueCategory? category;

  /// Record type and its shared pack. Null for a starter template.
  final ShippedRecordType? recordType;

  /// Suggested privacy: `internal`, `confidential` or `restricted`.
  final String privacy;

  /// Suggested rollout tier: `p0`, `p1` or `p2`.
  final String rollout;

  /// The template's own field keys, beyond the inherited groups, for search.
  final List<String> fieldKeys;

  /// Whether this is one of the starter templates of §13.4.
  bool get isStarter => category == null;

  /// The starter group this template is listed under.
  ShippedTemplateCategory get starterCategory =>
      ShippedTemplateCategory.of(templateKey);
}

/// The groups every shipped template inherits (§13.3). They say nothing
/// about what a template is, so search skips them.
const Set<String> _inheritedGroups = <String>{
  'record_admin',
  'location_context',
  'evidence',
  'review',
};

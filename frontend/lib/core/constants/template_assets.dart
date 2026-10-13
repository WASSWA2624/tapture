/// Typed paths for the shipped template library (FE-STR-12).
///
/// The templates themselves sit in one asset per category, named in
/// [catalogueIndex]; `tool/build_template_catalogue.dart` generates them.
abstract final class TemplateAssets {
  /// JSON Schema every shipped template asset must satisfy.
  static const String schema = 'assets/templates/_schema.json';

  /// Shared field definitions for legacy composition; simple starters select
  /// only their explicit fields (§13.3).
  static const String groups = 'assets/templates/_groups.json';

  /// Index of the library: supergroups, categories, record types and the
  /// asset of each category.
  static const String catalogueIndex = 'assets/templates/_catalogue.json';

  /// Reusable category and record-type field definitions. New starters do not
  /// automatically inherit these groups.
  static const String catalogueGroups =
      'assets/templates/_catalogue_groups.json';
}

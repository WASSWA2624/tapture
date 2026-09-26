/// Typed paths for the shipped template library (FE-STR-12).
///
/// The templates themselves sit in one asset per category, named in
/// [catalogueIndex]; `tool/build_template_catalogue.dart` generates them.
abstract final class TemplateAssets {
  /// JSON Schema every shipped template asset must satisfy.
  static const String schema = 'assets/templates/_schema.json';

  /// The four inherited groups of specification §13.3.
  static const String groups = 'assets/templates/_groups.json';

  /// Index of the library: supergroups, categories, record types and the
  /// asset of each category.
  static const String catalogueIndex = 'assets/templates/_catalogue.json';

  /// The category context and record-type pack groups every template
  /// inherits beside the four of §13.3.
  static const String catalogueGroups =
      'assets/templates/_catalogue_groups.json';
}

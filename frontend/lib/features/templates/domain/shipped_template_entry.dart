import 'shipped_catalogue_category.dart';
import 'shipped_record_type.dart';

export 'shipped_catalogue_category.dart';
export 'shipped_record_type.dart';

/// One shipped template as the library lists it: enough to show, search and
/// filter it without resolving its fields, which only a preview or a copy
/// needs. Titles and codes are catalogue data (FE-L10N-07).
final class ShippedTemplateEntry {
  /// Creates an entry.
  const ShippedTemplateEntry({
    required this.templateKey,
    required this.kind,
    required this.fieldCount,
    required this.title,
    required this.code,
    required this.category,
    required this.recordType,
    this.privacy = '',
    this.rollout = '',
    this.fieldKeys = const <String>[],
  });

  /// Stable key, for example `uni_general_observation`.
  final String templateKey;

  /// Kind of thing the template captures.
  final String kind;

  /// Columns once every inherited group is resolved.
  final int fieldCount;

  /// The catalogue's name for it, for example `General observation`.
  final String title;

  /// Catalogue code, for example `UNI-001`.
  final String code;

  /// The category it is listed under.
  final ShippedCatalogueCategory category;

  /// Record type and its shared pack.
  final ShippedRecordType recordType;

  /// Suggested privacy: `internal`, `confidential` or `restricted`.
  final String privacy;

  /// Suggested rollout tier: `p0`, `p1` or `p2`.
  final String rollout;

  /// The template's own field keys, beyond the inherited groups, for search.
  final List<String> fieldKeys;
}

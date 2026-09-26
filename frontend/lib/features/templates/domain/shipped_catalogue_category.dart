/// One category of the full catalogue, and the supergroup it sits in.
final class ShippedCatalogueCategory {
  /// Creates a category.
  const ShippedCatalogueCategory({
    required this.code,
    required this.title,
    required this.supergroupCode,
    required this.supergroupTitle,
  });

  /// Category code, for example `UNI`.
  final String code;

  /// Category name, for example `Universal capture and records`.
  final String title;

  /// Supergroup number, for example `01`.
  final String supergroupCode;

  /// Supergroup name, for example `Cross-sector foundations`.
  final String supergroupTitle;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/templates/domain/shipped_catalogue_category.dart';

void main() {
  test('a category keeps its code, title and supergroup', () {
    const ShippedCatalogueCategory category = ShippedCatalogueCategory(
      code: 'WAT',
      title: 'Water sanitation and irrigation',
      supergroupCode: '09',
      supergroupTitle: 'Energy utilities and environment',
    );

    expect(category.code, 'WAT');
    expect(category.title, 'Water sanitation and irrigation');
    expect(category.supergroupCode, '09');
    expect(category.supergroupTitle, 'Energy utilities and environment');
  });
}

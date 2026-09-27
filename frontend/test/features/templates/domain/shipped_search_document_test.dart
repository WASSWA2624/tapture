import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/templates/domain/shipped_search_document.dart';
import 'package:tapture/features/templates/domain/shipped_template_entry.dart';

void main() {
  const ShippedTemplateEntry entry = ShippedTemplateEntry(
    templateKey: 'ict_hardware',
    kind: 'asset',
    fieldCount: 2,
    title: 'IT hardware inventory',
    code: 'ICT-001',
    category: ShippedCatalogueCategory(
      code: 'ICT',
      title: 'IT service management',
      supergroupCode: '01',
      supergroupTitle: 'Cross-sector foundations',
    ),
    recordType: ShippedRecordType(
      code: 'ASSET',
      title: 'Register / master data',
      kind: 'asset',
      capture: 'Label photos; barcode or QR',
    ),
  );

  test('the code is folded and kept whole for an exact match', () {
    final ShippedSearchDocument document = ShippedSearchDocument.of(
      entry,
      fieldLabels: const <String>['Device type'],
    );
    expect(document.templateKey, 'ict_hardware');
    expect(document.code, 'ict-001');
  });

  test('a title outweighs the category, a field and the area', () {
    final ShippedSearchDocument document = ShippedSearchDocument.of(
      entry,
      fieldLabels: const <String>['Laptop or desktop computer'],
    );
    int weightOf(String word) {
      var best = 0;
      for (final ({int weight, List<String> words}) field in document.fields) {
        if (field.words.contains(word) && field.weight > best) {
          best = field.weight;
        }
      }
      return best;
    }

    expect(weightOf('hardware'), ShippedSearchDocument.titleWeight);
    expect(weightOf('service'), ShippedSearchDocument.typeWeight);
    expect(weightOf('laptop'), ShippedSearchDocument.fieldWeight);
    expect(weightOf('foundations'), ShippedSearchDocument.areaWeight);
    expect(
      ShippedSearchDocument.codeWeight,
      greaterThan(ShippedSearchDocument.titleWeight),
    );
    expect(weightOf('or'), 0, reason: 'short words mean nothing alone');
  });
}

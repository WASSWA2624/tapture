import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/templates/data/shipped_template_loader.dart';
import 'package:tapture/features/templates/domain/shipped_search_document.dart';
import 'package:tapture/features/templates/domain/shipped_template_entry.dart';
import 'package:tapture/features/templates/domain/shipped_template_ranking.dart';

import '../fakes/fake_template_repository.dart';

void main() {
  group('ranking', () {
    test('a code ranks its template first', () {
      final List<String> ranked = ShippedTemplateRanking.rank(
        'ICT-001',
        _documents,
      );
      expect(ranked.first, 'ict_hardware');
    });

    test('a title word outranks the same word in a field label', () {
      final List<String> ranked = ShippedTemplateRanking.rank(
        'inventory',
        _documents,
      );
      expect(
        ranked.indexOf('ast_master'),
        lessThan(ranked.indexOf('fin_ledger')),
      );
      expect(
        ranked.indexOf('ict_hardware'),
        lessThan(ranked.indexOf('fin_ledger')),
      );
      expect(ranked, contains('fin_ledger'));
    });

    test('a description ranks the fitting templates above the rest', () {
      final List<String> ranked = ShippedTemplateRanking.rank(
        'count laptops and computers in the district offices',
        _documents,
      );
      expect(ranked.first, 'ict_hardware');
      expect(ranked, isNot(contains('mtg_minutes')));
    });

    test('plural and verb endings still match', () {
      expect(
        ShippedTemplateRanking.rank('invoices', _documents).first,
        'fin_invoice',
      );
      expect(
        ShippedTemplateRanking.rank('meetings', _documents).first,
        'mtg_minutes',
      );
    });

    test('templates scoring nothing drop out', () {
      expect(ShippedTemplateRanking.rank('zzqqxx', _documents), isEmpty);
    });

    test('a query with no usable words keeps catalogue order', () {
      expect(ShippedTemplateRanking.rank(' - ', _documents), <String>[
        for (final ShippedSearchDocument document in _documents)
          document.templateKey,
      ]);
    });

    test('ties keep catalogue order', () {
      final List<String> ranked = ShippedTemplateRanking.rank(
        'barcode',
        _documents,
      );
      expect(ranked, <String>['ast_master', 'ict_hardware']);
    });
  });

  test('ranking the whole catalogue stays inside the search budget', () async {
    final ShippedTemplateLoader loader = ShippedTemplateLoader(
      templates: FakeTemplateRepository(),
      readAsset: (String path) => File(path).readAsString(),
    );
    final List<ShippedTemplateEntry> entries =
        (await loader.entries() as Success<List<ShippedTemplateEntry>>).value;
    expect(entries.length, greaterThan(2000));
    final List<ShippedSearchDocument> documents = <ShippedSearchDocument>[
      for (final ShippedTemplateEntry entry in entries)
        ShippedSearchDocument.of(
          entry,
          fieldLabels: <String>[
            for (final String key in entry.fieldKeys)
              Copy.shippedLabel('templates.$key'),
          ],
        ),
    ];

    for (final String query in <String>[
      'count laptops and computers in the district offices',
      'AST-001',
      'verify school enrolment registers',
    ]) {
      final Stopwatch watch = Stopwatch()..start();
      final List<String> ranked = ShippedTemplateRanking.rank(query, documents);
      watch.stop();
      expect(ranked, isNotEmpty, reason: query);
      // FE-PERF-01: search answers inside 300 ms (FE-TEST-09).
      expect(watch.elapsedMilliseconds, lessThan(300), reason: query);
    }
    expect(ShippedTemplateRanking.rank('AST-001', documents).first, isNotEmpty);
  });
}

final List<ShippedSearchDocument> _documents = <ShippedSearchDocument>[
  _document(
    key: 'ast_master',
    code: 'AST-001',
    title: 'Equipment master inventory',
    category: 'Assets and equipment',
    type: 'Register / master data',
    kind: 'asset',
    fields: <String>['Equipment name', 'Manufacturer'],
    capture: 'Label photos; barcode or QR',
  ),
  _document(
    key: 'ict_hardware',
    code: 'ICT-001',
    title: 'IT hardware inventory',
    category: 'IT service management',
    type: 'Register / master data',
    kind: 'asset',
    fields: <String>['Device type', 'Laptop or desktop computer'],
    capture: 'Label photos; barcode or QR',
  ),
  _document(
    key: 'fin_ledger',
    code: 'FIN-010',
    title: 'Ledger register',
    category: 'Finance accounting',
    type: 'Register / master data',
    kind: 'register',
    fields: <String>['Inventory account'],
    capture: 'Documents',
  ),
  _document(
    key: 'fin_invoice',
    code: 'FIN-001',
    title: 'Invoice intake',
    category: 'Finance accounting',
    type: 'Transaction',
    kind: 'transaction',
    fields: <String>['Supplier'],
    capture: 'Documents',
  ),
  _document(
    key: 'mtg_minutes',
    code: 'MTG-001',
    title: 'Meeting minutes',
    category: 'Meetings and events',
    type: 'Meeting',
    kind: 'meeting',
    fields: <String>['Chair', 'Agenda'],
    capture: 'Audio; notes',
  ),
];

ShippedSearchDocument _document({
  required String key,
  required String code,
  required String title,
  required String category,
  required String type,
  required String kind,
  required List<String> fields,
  required String capture,
}) {
  return ShippedSearchDocument.of(
    ShippedTemplateEntry(
      templateKey: key,
      kind: kind,
      fieldCount: fields.length,
      title: title,
      code: code,
      category: ShippedCatalogueCategory(
        code: code.substring(0, 3),
        title: category,
        supergroupCode: '01',
        supergroupTitle: 'Cross-sector foundations',
      ),
      recordType: ShippedRecordType(
        code: kind.toUpperCase(),
        title: type,
        kind: kind,
        capture: capture,
      ),
    ),
    fieldLabels: fields,
  );
}

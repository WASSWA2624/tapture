import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/domain/record_facets.dart';

void main() {
  const RecordFacets facets = RecordFacets(
    templates: <({String id, String name})>[(id: 'template-1', name: 'Assets')],
    contextLevels: <({String key, String label, List<String> values})>[
      (key: 'site', label: 'Site', values: <String>['East', 'North']),
    ],
    operators: <({String id, String label})>[(id: 'device-1', label: 'Ada')],
    conditions: <String>['good', 'poor'],
    statuses: <RecordStatus>{RecordStatus.captured, RecordStatus.approved},
  );

  test('empty offers nothing to choose', () {
    expect(RecordFacets.empty.isEmpty, isTrue);
    expect(facets.isEmpty, isFalse);
    expect(const RecordFacets(conditions: <String>['good']).isEmpty, isFalse);
  });

  test('facets with the same contents are equal, lists compared by value', () {
    // Fresh collections, so equality cannot lean on const identity.
    final RecordFacets same = facets.copyWith(
      templates: List<({String id, String name})>.of(facets.templates),
      contextLevels: <({String key, String label, List<String> values})>[
        (
          key: 'site',
          label: 'Site',
          values: List<String>.of(<String>['East', 'North']),
        ),
      ],
      operators: List<({String id, String label})>.of(facets.operators),
      conditions: List<String>.of(facets.conditions),
      statuses: <RecordStatus>{RecordStatus.approved, RecordStatus.captured},
    );
    expect(identical(same.conditions, facets.conditions), isFalse);
    expect(same, facets);
    expect(same.hashCode, facets.hashCode);
  });

  test('a different context value makes the facets differ', () {
    final RecordFacets other = facets.copyWith(
      contextLevels: <({String key, String label, List<String> values})>[
        (key: 'site', label: 'Site', values: <String>['East']),
      ],
    );
    expect(other, isNot(facets));
    expect(facets.copyWith(conditions: <String>['good']), isNot(facets));
  });

  test('copyWith replaces only what it is given', () {
    expect(facets.copyWith(), facets);
    final RecordFacets narrowed = facets.copyWith(
      statuses: <RecordStatus>{RecordStatus.approved},
    );
    expect(narrowed.statuses, <RecordStatus>{RecordStatus.approved});
    expect(narrowed.templates, facets.templates);
  });

  test('toString counts and never prints a value', () {
    expect(facets.toString(), isNot(contains('North')));
    expect(facets.toString(), contains('1 templates'));
  });
}

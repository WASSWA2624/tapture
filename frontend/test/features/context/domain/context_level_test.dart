import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/context/domain/context_state.dart';

void main() {
  const ContextLevel facility = ContextLevel(
    fieldKey: 'facility',
    order: 1,
    datasetId: 'ds-facilities',
    label: 'Facility',
  );

  group('copyWith', () {
    test('clearDatasetId drops the dataset binding', () {
      final ContextLevel freeText = facility.copyWith(clearDatasetId: true);
      expect(freeText.datasetId, isNull);
      expect(freeText.fieldKey, 'facility');
      expect(freeText.order, 1);
      expect(freeText.label, 'Facility');
    });

    test('clearDatasetId wins over a datasetId passed in the same call', () {
      final ContextLevel cleared = facility.copyWith(
        datasetId: 'ds-other',
        clearDatasetId: true,
      );
      expect(cleared.datasetId, isNull);
    });

    test('a new datasetId replaces the old one', () {
      expect(facility.copyWith(datasetId: 'ds-other').datasetId, 'ds-other');
    });

    test('a new order moves the level without changing its binding', () {
      final ContextLevel moved = facility.copyWith(order: 0);
      expect(moved.order, 0);
      expect(moved.fieldKey, facility.fieldKey);
      expect(moved.datasetId, facility.datasetId);
    });

    test('with nothing named yields an equal level', () {
      expect(facility.copyWith(), equals(facility));
    });
  });

  group('equality', () {
    test('levels with the same key, order, dataset and label are equal', () {
      const ContextLevel same = ContextLevel(
        fieldKey: 'facility',
        order: 1,
        datasetId: 'ds-facilities',
        label: 'Facility',
      );
      expect(same, equals(facility));
      expect(same.hashCode, facility.hashCode);
    });

    test('a different order breaks equality', () {
      expect(facility.copyWith(order: 2), isNot(equals(facility)));
    });

    test('a different dataset breaks equality', () {
      expect(facility.copyWith(clearDatasetId: true), isNot(equals(facility)));
    });

    test('a different label breaks equality', () {
      expect(facility.copyWith(label: 'Site'), isNot(equals(facility)));
    });

    test('a different field key breaks equality', () {
      expect(facility.copyWith(fieldKey: 'site'), isNot(equals(facility)));
    });
  });

  test('the label defaults to empty so callers can fall back to the key', () {
    const ContextLevel bare = ContextLevel(fieldKey: 'district', order: 0);
    expect(bare.label, isEmpty);
    expect(bare.datasetId, isNull);
  });
}

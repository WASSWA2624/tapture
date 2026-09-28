import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/context/domain/context_state.dart';

void main() {
  const ContextLevel district = ContextLevel(
    fieldKey: 'district',
    order: 0,
    label: 'District',
  );
  const ContextLevel facility = ContextLevel(
    fieldKey: 'facility',
    order: 1,
    label: 'Facility',
  );
  const ContextState room = ContextState(
    levels: <ContextLevel>[district, facility],
    values: <String, String>{'district': 'Kampala', 'facility': 'Kasubi HC IV'},
    pinned: <String, String>{'surveyor': 'Sam'},
  );

  group('a context is dormant when', () {
    test('it has no levels and no pins', () {
      expect(const ContextState().isEmpty, isTrue);
    });

    test('it holds stray values but no level and no pin', () {
      const ContextState strays = ContextState(
        values: <String, String>{'district': 'Kampala'},
      );
      expect(strays.isEmpty, isTrue);
    });
  });

  group('a context is live when', () {
    test('a level is defined even before any value is set', () {
      const ContextState defined = ContextState(
        levels: <ContextLevel>[district],
      );
      expect(defined.isEmpty, isFalse);
    });

    test('a field is pinned without any hierarchy', () {
      const ContextState pinned = ContextState(
        pinned: <String, String>{'surveyor': 'Sam'},
      );
      expect(pinned.isEmpty, isFalse);
    });
  });

  group('equality', () {
    test('states with the same levels, values and pins are equal', () {
      const ContextState same = ContextState(
        levels: <ContextLevel>[district, facility],
        values: <String, String>{
          'district': 'Kampala',
          'facility': 'Kasubi HC IV',
        },
        pinned: <String, String>{'surveyor': 'Sam'},
      );
      expect(same, equals(room));
      expect(same.hashCode, room.hashCode);
    });

    test('map insertion order changes neither equality nor the hash code', () {
      const ContextState reordered = ContextState(
        levels: <ContextLevel>[district, facility],
        values: <String, String>{
          'facility': 'Kasubi HC IV',
          'district': 'Kampala',
        },
        pinned: <String, String>{'surveyor': 'Sam'},
      );
      expect(reordered, equals(room));
      expect(reordered.hashCode, room.hashCode);
    });

    test('a different value at one level breaks equality', () {
      final ContextState moved = room.copyWith(
        values: <String, String>{'district': 'Kampala', 'facility': 'Mulago'},
      );
      expect(moved, isNot(equals(room)));
    });

    test('a different pin breaks equality', () {
      final ContextState other = room.copyWith(
        pinned: <String, String>{'surveyor': 'Ada'},
      );
      expect(other, isNot(equals(room)));
    });

    test('a missing level breaks equality', () {
      final ContextState shorter = room.copyWith(
        levels: <ContextLevel>[district],
      );
      expect(shorter, isNot(equals(room)));
    });

    test('levels in a different list order are a different hierarchy', () {
      final ContextState swapped = room.copyWith(
        levels: <ContextLevel>[facility, district],
      );
      expect(swapped, isNot(equals(room)));
    });
  });

  group('copyWith', () {
    test('replaces only the named collection', () {
      final ContextState next = room.copyWith(
        values: <String, String>{'district': 'Wakiso'},
      );
      expect(next.values, <String, String>{'district': 'Wakiso'});
      expect(next.levels, room.levels);
      expect(next.pinned, room.pinned);
    });

    test('with nothing named yields an equal state', () {
      expect(room.copyWith(), equals(room));
    });

    test('leaves the original untouched', () {
      room.copyWith(pinned: const <String, String>{});
      expect(room.pinned, <String, String>{'surveyor': 'Sam'});
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/context/domain/context_state.dart';

void main() {
  final DateTime monday = DateTime.utc(2026, 9, 21, 8);
  final DateTime tuesday = DateTime.utc(2026, 9, 22, 8);
  final ContextPreset theatre = ContextPreset(
    id: 'preset-1',
    name: 'Theatre',
    values: const <String, String>{
      'district': 'Kampala',
      'facility': 'Kasubi HC IV',
    },
    pinned: const <String, String>{'surveyor': 'Sam'},
    lastUsedAt: monday,
  );

  group('equality', () {
    test('presets with the same id, name, values and pins are equal', () {
      final ContextPreset same = ContextPreset(
        id: 'preset-1',
        name: 'Theatre',
        values: const <String, String>{
          'district': 'Kampala',
          'facility': 'Kasubi HC IV',
        },
        pinned: const <String, String>{'surveyor': 'Sam'},
        lastUsedAt: monday,
      );
      expect(same, equals(theatre));
      expect(same.hashCode, theatre.hashCode);
    });

    test('last used at orders the list and never breaks equality', () {
      final ContextPreset reused = theatre.copyWith(lastUsedAt: tuesday);
      expect(reused, equals(theatre));
      expect(reused.hashCode, theatre.hashCode);
    });

    test('map insertion order changes neither equality nor the hash code', () {
      final ContextPreset reordered = theatre.copyWith(
        values: const <String, String>{
          'facility': 'Kasubi HC IV',
          'district': 'Kampala',
        },
      );
      expect(reordered, equals(theatre));
      expect(reordered.hashCode, theatre.hashCode);
    });

    test('a different value breaks equality', () {
      final ContextPreset other = theatre.copyWith(
        values: const <String, String>{'district': 'Kampala'},
      );
      expect(other, isNot(equals(theatre)));
    });

    test('a different pin breaks equality', () {
      final ContextPreset other = theatre.copyWith(
        pinned: const <String, String>{'surveyor': 'Ada'},
      );
      expect(other, isNot(equals(theatre)));
    });

    test('a different name breaks equality', () {
      expect(theatre.copyWith(name: 'Ward'), isNot(equals(theatre)));
    });

    test('a different id breaks equality', () {
      expect(theatre.copyWith(id: 'preset-2'), isNot(equals(theatre)));
    });
  });

  group('copyWith', () {
    test('replaces only the named fields', () {
      final ContextPreset renamed = theatre.copyWith(name: 'Ward');
      expect(renamed.name, 'Ward');
      expect(renamed.id, theatre.id);
      expect(renamed.values, theatre.values);
      expect(renamed.pinned, theatre.pinned);
      expect(renamed.lastUsedAt, monday);
    });

    test('a later use moves last used at forward', () {
      expect(theatre.copyWith(lastUsedAt: tuesday).lastUsedAt, tuesday);
    });

    test('leaves the original untouched', () {
      theatre.copyWith(values: const <String, String>{});
      expect(theatre.values['district'], 'Kampala');
    });
  });
}

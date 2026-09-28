import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/context/domain/context_auto_clear.dart';
import 'package:tapture/features/context/domain/context_state.dart';

/// What [ContextAutoClear.clearLowest] hands back.
typedef _Cleared = ({ContextState next, String? fieldKey, String? value});

void main() {
  const Duration idle = Duration(minutes: 5);
  final DateTime lastActivity = DateTime.utc(2026, 9, 22, 8);
  final Clock beforeIdle = FixedClock(
    lastActivity.add(idle - const Duration(seconds: 1)),
  );
  final Clock atIdle = FixedClock(lastActivity.add(idle));
  final Clock longAfter = FixedClock(lastActivity.add(idle * 3));

  const ContextState three = ContextState(
    levels: <ContextLevel>[
      ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
      ContextLevel(fieldKey: 'facility', order: 1, label: 'Facility'),
      ContextLevel(fieldKey: 'dept', order: 2, label: 'Department'),
    ],
    values: <String, String>{
      'district': 'Kampala',
      'facility': 'Kasubi HC IV',
      'dept': 'Theatre',
    },
    pinned: <String, String>{'surveyor': 'Sam'},
  );

  bool due({
    required Clock clock,
    bool enabled = true,
    Duration interval = idle,
    bool alreadyFired = false,
  }) {
    return ContextAutoClear.shouldClear(
      enabled: enabled,
      idleInterval: interval,
      lastActivity: lastActivity,
      now: clock.nowUtc(),
      alreadyFiredThisPeriod: alreadyFired,
    );
  }

  group('off', () {
    test('never fires however long the context sits idle', () {
      expect(due(clock: longAfter, enabled: false), isFalse);
    });

    test('a zero or negative interval never fires', () {
      expect(due(clock: longAfter, interval: Duration.zero), isFalse);
      expect(
        due(clock: longAfter, interval: const Duration(minutes: -1)),
        isFalse,
      );
    });
  });

  group('fired', () {
    test('not a second before the idle interval has passed', () {
      expect(due(clock: beforeIdle), isFalse);
    });

    test('exactly when the idle interval has passed', () {
      expect(due(clock: atIdle), isTrue);
      expect(due(clock: longAfter), isTrue);
    });

    test('at most once per idle period', () {
      expect(due(clock: longAfter, alreadyFired: true), isFalse);
    });

    test('clearing removes only the lowest level', () {
      final _Cleared cleared = ContextAutoClear.clearLowest(three);
      expect(cleared.fieldKey, 'dept');
      expect(cleared.value, 'Theatre');
      expect(cleared.next.values, <String, String>{
        'district': 'Kampala',
        'facility': 'Kasubi HC IV',
      });
      expect(cleared.next.pinned, three.pinned);
      expect(cleared.next.levels, three.levels);
    });

    test('the lowest level is chosen by order, not list position', () {
      expect(
        ContextAutoClear.lowestFieldKey(<({String fieldKey, int order})>[
          (fieldKey: 'dept', order: 2),
          (fieldKey: 'district', order: 0),
          (fieldKey: 'facility', order: 1),
        ]),
        'dept',
      );
      final ContextState shuffled = three.copyWith(
        levels: <ContextLevel>[three.levels[2], three.levels[0], three.levels[1]],
      );
      expect(ContextAutoClear.clearLowest(shuffled).fieldKey, 'dept');
    });
  });

  group('undone', () {
    test('restores the cleared value exactly', () {
      final _Cleared cleared = ContextAutoClear.clearLowest(three);
      final ContextState restored = ContextAutoClear.restore(
        state: cleared.next,
        fieldKey: cleared.fieldKey!,
        value: cleared.value!,
      );
      expect(restored, equals(three));
    });

    test('touches nothing but the cleared level', () {
      final ContextState restored = ContextAutoClear.restore(
        state: three.copyWith(
          values: <String, String>{'district': 'Kampala'},
        ),
        fieldKey: 'dept',
        value: 'Theatre',
      );
      expect(restored.values, <String, String>{
        'district': 'Kampala',
        'dept': 'Theatre',
      });
      expect(restored.pinned, three.pinned);
    });
  });

  group('nothing to clear', () {
    test('a hierarchy with no levels has no lowest level', () {
      expect(
        ContextAutoClear.lowestFieldKey(const <({String fieldKey, int order})>[]),
        isNull,
      );
      final _Cleared cleared = ContextAutoClear.clearLowest(
        const ContextState(pinned: <String, String>{'surveyor': 'Sam'}),
      );
      expect(cleared.fieldKey, isNull);
      expect(cleared.value, isNull);
      expect(cleared.next.pinned, <String, String>{'surveyor': 'Sam'});
    });

    test('an already empty lowest level offers nothing to undo', () {
      final ContextState partial = three.copyWith(
        values: <String, String>{
          'district': 'Kampala',
          'facility': 'Kasubi HC IV',
        },
      );
      final _Cleared cleared = ContextAutoClear.clearLowest(partial);
      expect(cleared.fieldKey, 'dept');
      expect(cleared.value, isNull);
      expect(cleared.next, equals(partial));
    });
  });
}

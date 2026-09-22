import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/files/photo_path_builder.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/context/domain/context_application.dart';
import 'package:tapture/features/context/domain/context_auto_clear.dart';
import 'package:tapture/features/context/domain/context_cascade.dart';
import 'package:tapture/features/context/domain/context_folder_link.dart';
import 'package:tapture/features/context/domain/context_movement_prompt.dart';
import 'package:tapture/features/context/domain/context_override.dart';
import 'package:tapture/features/context/domain/context_state.dart';

void main() {
  const ContextState three = ContextState(
    levels: <ContextLevel>[
      ContextLevel(fieldKey: 'district', order: 0, label: 'district'),
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

  group('cascade clearing', () {
    test('a hierarchy with no levels clears nothing', () {
      expect(
        ContextCascade.affected(
          state: const ContextState(),
          changedFieldKey: 'district',
        ),
        isEmpty,
      );
    });

    test('a one-level hierarchy has nothing beneath the change', () {
      const ContextState one = ContextState(
        levels: <ContextLevel>[
          ContextLevel(fieldKey: 'site', order: 0, label: 'Site'),
        ],
        values: <String, String>{'site': 'A'},
      );
      expect(
        ContextCascade.affected(state: one, changedFieldKey: 'site'),
        isEmpty,
      );
      final ContextState next = ContextCascade.apply(
        state: one,
        changedFieldKey: 'site',
        newValue: 'B',
      );
      expect(next.values['site'], 'B');
    });

    test('changing the root names facility and department and clears them', () {
      final List<({ContextLevel level, String value})> affected =
          ContextCascade.affected(state: three, changedFieldKey: 'district');
      expect(ContextCascade.named(affected), <String>[
        'Facility (Kasubi HC IV)',
        'Department (Theatre)',
      ]);
      final ContextState next = ContextCascade.apply(
        state: three,
        changedFieldKey: 'district',
        newValue: 'Wakiso',
      );
      expect(next.values['district'], 'Wakiso');
      expect(next.values.containsKey('facility'), isFalse);
      expect(next.values.containsKey('dept'), isFalse);
      expect(next.pinned['surveyor'], 'Sam');
    });

    test('changing the lowest level clears nothing', () {
      expect(
        ContextCascade.affected(state: three, changedFieldKey: 'dept'),
        isEmpty,
      );
      final ContextState next = ContextCascade.apply(
        state: three,
        changedFieldKey: 'dept',
        newValue: 'Laboratory',
      );
      expect(next.values['facility'], 'Kasubi HC IV');
      expect(next.values['dept'], 'Laboratory');
    });
  });

  test('a new record carries each value with source CONTEXT', () {
    final ({
      List<({String fieldKey, String value, String source})> fields,
      Map<String, Object?> snapshot,
    })
    result = ContextApplication.apply(three);
    expect(
      result.fields.map(
        (({String fieldKey, String value, String source}) field) =>
            field.source,
      ),
      everyElement(ContextApplication.source),
    );
    expect(
      result.fields.map(
        (({String fieldKey, String value, String source}) field) =>
            (field.fieldKey, field.value),
      ),
      containsAll(<(String, String)>[
        ('district', 'Kampala'),
        ('facility', 'Kasubi HC IV'),
        ('dept', 'Theatre'),
        ('surveyor', 'Sam'),
      ]),
    );
    expect(result.snapshot['values'], three.values);
  });

  test(
    'an override keeps the raw value and writes the correction beside it',
    () {
      final ({
        String fieldKey,
        String rawValue,
        String refinedValue,
        bool overridden,
      })
      planned = ContextOverride.plan(
        fieldKey: 'dept',
        rawValue: 'Theatre',
        newValue: 'Laboratory',
      );
      expect(planned.rawValue, 'Theatre');
      expect(planned.refinedValue, 'Laboratory');
      expect(
        ContextOverride.isOverridden(
          rawValue: planned.rawValue,
          refinedValue: planned.refinedValue,
        ),
        isTrue,
      );
    },
  );

  test('the photo folder follows the record snapshot for three levels', () {
    final ({
      List<({String fieldKey, String value, String source})> fields,
      Map<String, Object?> snapshot,
    })
    applied = ContextApplication.apply(three);
    expect(
      ContextFolderLink.photoFolder(
        strategy: PhotoFolderStrategy.byContext,
        snapshot: applied.snapshot,
      ),
      'photos/Kampala/Kasubi-HC-IV/Theatre',
    );
  });

  group('auto-clear with a fake clock', () {
    final DateTime start = DateTime.utc(2026, 9, 22, 8);
    final FixedClock early = FixedClock(start.add(const Duration(minutes: 4)));
    final FixedClock due = FixedClock(start.add(const Duration(minutes: 5)));

    test('stays off when the setting is off', () {
      expect(
        ContextAutoClear.shouldClear(
          enabled: false,
          idleInterval: const Duration(minutes: 5),
          lastActivity: start,
          now: due.nowUtc(),
          alreadyFiredThisPeriod: false,
        ),
        isFalse,
      );
    });

    test('fires once the idle interval has passed', () {
      expect(
        ContextAutoClear.shouldClear(
          enabled: true,
          idleInterval: const Duration(minutes: 5),
          lastActivity: start,
          now: early.nowUtc(),
          alreadyFiredThisPeriod: false,
        ),
        isFalse,
      );
      expect(
        ContextAutoClear.shouldClear(
          enabled: true,
          idleInterval: const Duration(minutes: 5),
          lastActivity: start,
          now: due.nowUtc(),
          alreadyFiredThisPeriod: false,
        ),
        isTrue,
      );
    });

    test('does not fire again in the same idle period', () {
      expect(
        ContextAutoClear.shouldClear(
          enabled: true,
          idleInterval: const Duration(minutes: 5),
          lastActivity: start,
          now: due.nowUtc(),
          alreadyFiredThisPeriod: true,
        ),
        isFalse,
      );
    });

    test('undo restores the cleared lowest value exactly', () {
      final ({ContextState next, String? fieldKey, String? value}) cleared =
          ContextAutoClear.clearLowest(three);
      expect(cleared.fieldKey, 'dept');
      expect(cleared.value, 'Theatre');
      expect(cleared.next.values.containsKey('facility'), isTrue);
      expect(cleared.next.values.containsKey('dept'), isFalse);
      final ContextState restored = ContextAutoClear.restore(
        state: cleared.next,
        fieldKey: cleared.fieldKey!,
        value: cleared.value!,
      );
      expect(restored.values['dept'], 'Theatre');
      expect(restored.values['district'], 'Kampala');
    });
  });

  group('movement prompt with a fake location source', () {
    int reads = 0;
    ({double latitude, double longitude})? fix;

    ({double latitude, double longitude})? read() {
      reads += 1;
      return fix;
    }

    setUp(() {
      reads = 0;
      fix = (latitude: 0.002, longitude: 0);
    });

    test('off never reads a fix', () {
      final ({bool prompt, bool readFix}) decision =
          ContextMovementPrompt.evaluate(
            enabled: false,
            gpsEnabled: true,
            locationGranted: true,
            thresholdMetres: 100,
            readFix: read,
            origin: (latitude: 0, longitude: 0),
          );
      expect(decision.readFix, isFalse);
      expect(decision.prompt, isFalse);
      expect(reads, 0);
    });

    test('permission denied never reads a fix', () {
      final ({bool prompt, bool readFix}) decision =
          ContextMovementPrompt.evaluate(
            enabled: true,
            gpsEnabled: true,
            locationGranted: false,
            thresholdMetres: 100,
            readFix: read,
            origin: (latitude: 0, longitude: 0),
          );
      expect(decision.prompt, isFalse);
      expect(reads, 0);
    });

    test('a fix past the threshold asks and does not describe a write', () {
      final ({bool prompt, bool readFix}) decision =
          ContextMovementPrompt.evaluate(
            enabled: true,
            gpsEnabled: true,
            locationGranted: true,
            thresholdMetres: 100,
            readFix: read,
            origin: (latitude: 0, longitude: 0),
          );
      expect(reads, 1);
      expect(decision.readFix, isTrue);
      expect(decision.prompt, isTrue);
    });
  });
}

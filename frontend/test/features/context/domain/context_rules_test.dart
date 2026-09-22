import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/files/photo_path_builder.dart';
import 'package:tapture/features/context/domain/context_application.dart';
import 'package:tapture/features/context/domain/context_auto_clear.dart';
import 'package:tapture/features/context/domain/context_cascade.dart';
import 'package:tapture/features/context/domain/context_folder_link.dart';
import 'package:tapture/features/context/domain/context_movement_prompt.dart';
import 'package:tapture/features/context/domain/context_override.dart';
import 'package:tapture/features/context/domain/context_state.dart';

void main() {
  group('cascade', () {
    const ContextState three = ContextState(
      levels: <ContextLevel>[
        ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
        ContextLevel(fieldKey: 'facility', order: 1, label: 'Facility'),
        ContextLevel(fieldKey: 'dept', order: 2, label: 'Department'),
      ],
      values: <String, String>{
        'district': 'North',
        'facility': 'Clinic',
        'dept': 'Pharmacy',
      },
    );

    test('changing root clears lower filled levels', () {
      final List<({ContextLevel level, String value})> affected =
          ContextCascade.affected(state: three, changedFieldKey: 'district');
      expect(affected.length, 2);
      final ContextState next = ContextCascade.apply(
        state: three,
        changedFieldKey: 'district',
        newValue: 'South',
      );
      expect(next.values['district'], 'South');
      expect(next.values.containsKey('facility'), isFalse);
      expect(next.values.containsKey('dept'), isFalse);
    });
  });

  test('application writes CONTEXT fields and snapshot', () {
    const ContextState state = ContextState(
      levels: <ContextLevel>[
        ContextLevel(fieldKey: 'site', order: 0, label: 'Site'),
      ],
      values: <String, String>{'site': 'A'},
      pinned: <String, String>{'surveyor': 'Sam'},
    );
    final ({Map<String, String> fields, Map<String, Object?> snapshot}) result =
        ContextApplication.apply(state);
    expect(result.fields['site'], 'A');
    expect(result.fields['surveyor'], 'Sam');
    expect(result.snapshot['values'], isA<Map<String, String>>());
  });

  test('override leaves project context untouched', () {
    final Map<String, Object?> record = ContextOverride.mark(
      recordFields: <String, Object?>{'dept': 'Pharmacy'},
      fieldKey: 'dept',
      newValue: 'Lab',
      previousValue: 'Pharmacy',
    );
    expect(ContextOverride.isOverridden(record['dept']), isTrue);
    expect((record['dept']! as Map<String, Object?>)['value'], 'Lab');
  });

  test('folder link builds photo path from snapshot', () {
    final String path = ContextFolderLink.photoFolder(
      strategy: PhotoFolderStrategy.byContext,
      snapshot: const <String, Object?>{
        'levels': <Object>[
          <String, Object?>{'fieldKey': 'site', 'order': 0, 'value': 'A'},
          <String, Object?>{'fieldKey': 'room', 'order': 1, 'value': '1'},
        ],
      },
    );
    expect(path, contains('A'));
    expect(path, contains('1'));
  });

  test('movement prompt distance gate', () {
    expect(
      ContextMovementPrompt.shouldPrompt(
        enabled: true,
        gpsEnabled: true,
        locationGranted: true,
        distanceMetres: 50,
        thresholdMetres: 100,
      ),
      isFalse,
    );
    expect(
      ContextMovementPrompt.shouldPrompt(
        enabled: true,
        gpsEnabled: true,
        locationGranted: true,
        distanceMetres: 120,
        thresholdMetres: 100,
      ),
      isTrue,
    );
    expect(
      ContextMovementPrompt.shouldPrompt(
        enabled: false,
        gpsEnabled: true,
        locationGranted: true,
        distanceMetres: 500,
        thresholdMetres: 100,
      ),
      isFalse,
    );
  });

  test('auto-clear picks lowest filled level', () {
    expect(
      ContextAutoClear.lowestFieldKey(const <({String fieldKey, int order})>[
        (fieldKey: 'a', order: 0),
        (fieldKey: 'b', order: 1),
      ]),
      'b',
    );
  });
}

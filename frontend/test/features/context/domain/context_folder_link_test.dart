import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/files/photo_path_builder.dart';
import 'package:tapture/features/context/domain/context_application.dart';
import 'package:tapture/features/context/domain/context_folder_link.dart';
import 'package:tapture/features/context/domain/context_state.dart';

void main() {
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

  Map<String, Object?> snapshotOf(ContextState state) {
    return ContextApplication.apply(state).snapshot;
  }

  test('the photo folder follows the record snapshot for three levels', () {
    expect(
      ContextFolderLink.photoFolder(
        strategy: PhotoFolderStrategy.byContext,
        snapshot: snapshotOf(three),
      ),
      'photos/Kampala/Kasubi-HC-IV/Theatre',
    );
  });

  test('a live state yields the same segments as its snapshot', () {
    expect(ContextFolderLink.pathValues(state: three), <String>[
      'Kampala',
      'Kasubi-HC-IV',
      'Theatre',
    ]);
    expect(
      ContextFolderLink.pathValues(snapshot: snapshotOf(three)),
      ContextFolderLink.pathValues(state: three),
    );
  });

  test('snapshot levels are ordered by hierarchy order, not list position', () {
    final Map<String, Object?> shuffled = <String, Object?>{
      'levels': <Map<String, Object?>>[
        <String, Object?>{'fieldKey': 'dept', 'order': 2, 'value': 'Theatre'},
        <String, Object?>{
          'fieldKey': 'district',
          'order': 0,
          'value': 'Kampala',
        },
        <String, Object?>{
          'fieldKey': 'facility',
          'order': 1,
          'value': 'Kasubi HC IV',
        },
      ],
    };
    expect(ContextFolderLink.pathValues(snapshot: shuffled), <String>[
      'Kampala',
      'Kasubi-HC-IV',
      'Theatre',
    ]);
  });

  test('an unset lowest level lands the photo in the unfiled folder', () {
    final ContextState twoOfThree = three.copyWith(
      values: <String, String>{
        'district': 'Kampala',
        'facility': 'Kasubi HC IV',
      },
    );
    expect(ContextFolderLink.pathValues(state: twoOfThree), <String>[
      'Kampala',
      'Kasubi-HC-IV',
      '',
    ]);
    expect(
      ContextFolderLink.photoFolder(
        strategy: PhotoFolderStrategy.byContext,
        snapshot: snapshotOf(twoOfThree),
      ),
      'photos/Kampala/Kasubi-HC-IV/_unfiled',
    );
  });

  test('a project with no hierarchy files every photo as unfiled', () {
    expect(
      ContextFolderLink.pathValues(snapshot: snapshotOf(const ContextState())),
      isEmpty,
    );
    expect(
      ContextFolderLink.photoFolder(
        strategy: PhotoFolderStrategy.byContext,
        snapshot: snapshotOf(const ContextState()),
      ),
      'photos/_unfiled',
    );
  });

  test('a snapshot with values but no level list still yields segments', () {
    final Map<String, Object?> legacy = <String, Object?>{
      'values': <String, String>{'district': 'Kampala', 'facility': 'Mulago'},
    };
    expect(ContextFolderLink.pathValues(snapshot: legacy), <String>[
      'Kampala',
      'Mulago',
    ]);
  });

  test('nothing to read yields no segments', () {
    expect(ContextFolderLink.pathValues(), isEmpty);
    expect(
      ContextFolderLink.pathValues(snapshot: const <String, Object?>{}),
      isEmpty,
    );
  });

  test('accented and spaced values become ASCII hyphenated segments', () {
    final ContextState accented = three.copyWith(
      values: <String, String>{
        'district': ' Région Nord ',
        'facility': 'St. Mary\'s / Ward 3',
        'dept': 'Théâtre',
      },
    );
    expect(ContextFolderLink.pathValues(state: accented), <String>[
      'Region-Nord',
      'St-Marys-Ward-3',
      'Theatre',
    ]);
  });

  test('a value that would escape the photos folder is refused', () {
    final ContextState hostile = three.copyWith(
      values: <String, String>{'district': '../../etc'},
    );
    expect(
      () => ContextFolderLink.pathValues(state: hostile),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('the strategy in force decides whether context is used at all', () {
    expect(
      ContextFolderLink.photoFolder(
        strategy: PhotoFolderStrategy.byTemplate,
        snapshot: snapshotOf(three),
        templateName: 'Equipment',
      ),
      'photos/Equipment',
    );
    expect(
      ContextFolderLink.photoFolder(
        strategy: PhotoFolderStrategy.flat,
        snapshot: snapshotOf(three),
      ),
      'photos',
    );
  });
}

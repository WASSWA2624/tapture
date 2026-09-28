import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart' show AppDatabase;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/context/data/context_repository_impl.dart';
import 'package:tapture/features/context/domain/context_repository.dart';
import 'package:tapture/features/context/domain/context_state.dart';

import '../../../support/fakes/fake_context_repository.dart';
import '../../../support/matchers.dart';

/// One open repository and the way to release it.
typedef _Opened = ({ContextRepository repo, Future<void> Function() close});

/// An implementation the contract below runs against.
typedef _Subject = ({String name, Future<_Opened> Function() open});

/// The [ContextRepository] contract, run over the hand-written fake the
/// widget tests rely on and over the Drift implementation, so the two can
/// never drift apart.
void main() {
  final DateTime t0 = DateTime.utc(2026, 9, 22, 8);
  const List<ContextLevel> hierarchy = <ContextLevel>[
    ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
    ContextLevel(fieldKey: 'facility', order: 1, label: 'Facility'),
    ContextLevel(fieldKey: 'dept', order: 2, label: 'Department'),
  ];

  final List<_Subject> subjects = <_Subject>[
    (
      name: 'the fake repository',
      open: () async {
        final FakeContextRepository fake = FakeContextRepository();
        return (repo: fake, close: () async => fake.dispose());
      },
    ),
    (
      name: 'the Drift repository over an in-memory database',
      open: () async {
        final AppDatabase db = AppDatabase.memory();
        final ContextRepositoryImpl impl = ContextRepositoryImpl(
          db: db,
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: UuidV7Service.sequence(FixedClock(t0)),
        );
        return (repo: impl, close: db.close);
      },
    ),
  ];

  for (final _Subject subject in subjects) {
    group('${subject.name} honours the contract:', () {
      late ContextRepository repo;
      late Future<void> Function() close;

      setUp(() async {
        final _Opened opened = await subject.open();
        repo = opened.repo;
        close = opened.close;
      });

      tearDown(() => close());

      Future<void> fillRoom() async {
        valueOf(await repo.saveHierarchy('p1', hierarchy));
        valueOf(
          await repo.setLevelValue(
            projectId: 'p1',
            fieldKey: 'district',
            value: 'Kampala',
          ),
        );
        valueOf(
          await repo.setLevelValue(
            projectId: 'p1',
            fieldKey: 'facility',
            value: 'Kasubi HC IV',
          ),
        );
        valueOf(
          await repo.setLevelValue(
            projectId: 'p1',
            fieldKey: 'dept',
            value: 'Theatre',
          ),
        );
      }

      test('a project nobody has configured loads an empty context', () async {
        final ContextState state = valueOf(await repo.load('p1'));
        expect(state.isEmpty, isTrue);
        expect(state.levels, isEmpty);
        expect(state.values, isEmpty);
      });

      test('a saved hierarchy is what load and watch hand back', () async {
        valueOf(await repo.saveHierarchy('p1', hierarchy));
        final ContextState loaded = valueOf(await repo.load('p1'));
        expect(loaded.levels, hierarchy);
        final ContextState watched = await repo.watch('p1').first;
        expect(watched.levels, hierarchy);
      });

      test('setting a higher level clears every level below it', () async {
        await fillRoom();
        final ContextState next = valueOf(
          await repo.setLevelValue(
            projectId: 'p1',
            fieldKey: 'district',
            value: 'Wakiso',
          ),
        );
        expect(next.values, <String, String>{'district': 'Wakiso'});
        expect(valueOf(await repo.load('p1')).values, next.values);
      });

      test('setting the lowest level leaves the levels above it', () async {
        await fillRoom();
        final ContextState next = valueOf(
          await repo.setLevelValue(
            projectId: 'p1',
            fieldKey: 'dept',
            value: 'Laboratory',
          ),
        );
        expect(next.values, <String, String>{
          'district': 'Kampala',
          'facility': 'Kasubi HC IV',
          'dept': 'Laboratory',
        });
      });

      test(
        'setting a level without the cascade keeps the levels below',
        () async {
          await fillRoom();
          final ContextState next = valueOf(
            await repo.setLevelValue(
              projectId: 'p1',
              fieldKey: 'district',
              value: 'Wakiso',
              clearBelow: false,
            ),
          );
          expect(next.values['district'], 'Wakiso');
          expect(next.values['facility'], 'Kasubi HC IV');
          expect(next.values['dept'], 'Theatre');
        },
      );

      test(
        'saving pins replaces the pins and leaves level values alone',
        () async {
          await fillRoom();
          valueOf(
            await repo.savePinned('p1', const <String, String>{
              'surveyor': 'Sam',
            }),
          );
          final ContextState next = valueOf(
            await repo.savePinned('p1', const <String, String>{
              'survey_date': '2026-09-22',
            }),
          );
          expect(next.pinned, <String, String>{'survey_date': '2026-09-22'});
          expect(next.values['dept'], 'Theatre');
        },
      );

      test('applying a preset sets its values, clears the levels it omits and '
          'replaces the pins in one write', () async {
        await fillRoom();
        valueOf(
          await repo.savePinned('p1', const <String, String>{
            'surveyor': 'Sam',
          }),
        );
        final ContextPreset preset = valueOf(
          await repo.savePreset(
            projectId: 'p1',
            name: 'Ward B',
            values: const <String, String>{
              'district': 'Kampala',
              'facility': 'Mulago',
            },
            pinned: const <String, String>{'surveyor': 'Ada'},
          ),
        );
        final ContextState applied = valueOf(
          await repo.applyPreset('p1', preset),
        );
        expect(applied.values, <String, String>{
          'district': 'Kampala',
          'facility': 'Mulago',
        });
        expect(applied.pinned, <String, String>{'surveyor': 'Ada'});
        expect(valueOf(await repo.load('p1')), equals(applied));
      });

      test(
        'a preset name in use fails validation until overwrite is confirmed',
        () async {
          valueOf(await repo.saveHierarchy('p1', hierarchy));
          valueOf(
            await repo.savePreset(
              projectId: 'p1',
              name: 'Room A',
              values: const <String, String>{'district': 'Kampala'},
              pinned: const <String, String>{},
            ),
          );
          expect(
            await repo.savePreset(
              projectId: 'p1',
              name: 'Room A',
              values: const <String, String>{'district': 'Wakiso'},
              pinned: const <String, String>{},
            ),
            isFailure<ContextPreset, ValidationFailure>(),
          );
          final List<ContextPreset> kept = await repo.watchPresets('p1').first;
          expect(kept.single.values, <String, String>{'district': 'Kampala'});

          final ContextPreset replaced = valueOf(
            await repo.savePreset(
              projectId: 'p1',
              name: 'Room A',
              values: const <String, String>{'district': 'Wakiso'},
              pinned: const <String, String>{},
              overwrite: true,
            ),
          );
          expect(replaced.id, kept.single.id);
          final List<ContextPreset> after = await repo.watchPresets('p1').first;
          expect(after.single.values, <String, String>{'district': 'Wakiso'});
        },
      );

      test('deleting a preset removes it from the preset stream', () async {
        valueOf(await repo.saveHierarchy('p1', hierarchy));
        final ContextPreset preset = valueOf(
          await repo.savePreset(
            projectId: 'p1',
            name: 'Room A',
            values: const <String, String>{'district': 'Kampala'},
            pinned: const <String, String>{},
          ),
        );
        valueOf(
          await repo.deletePreset(preset.id, reason: 'Operator removed it.'),
        );
        expect(await repo.watchPresets('p1').first, isEmpty);
      });

      test('recent values come back newest first without duplicates', () async {
        valueOf(await repo.saveHierarchy('p1', hierarchy));
        for (final String value in <String>[
          'Kasubi HC IV',
          'Mulago',
          'Kasubi HC IV',
        ]) {
          valueOf(
            await repo.setLevelValue(
              projectId: 'p1',
              fieldKey: 'facility',
              value: value,
            ),
          );
        }
        expect(
          valueOf(
            await repo.recentValues(projectId: 'p1', fieldKey: 'facility'),
          ),
          <String>['Kasubi HC IV', 'Mulago'],
        );
        expect(
          valueOf(await repo.recentValues(projectId: 'p1', fieldKey: 'dept')),
          isEmpty,
        );
      });
    });
  }
}

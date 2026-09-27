import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/fields/field_editor.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/presentation/record_edit_controller.dart';
import 'package:tapture/features/records/presentation/record_field_input.dart';
import 'package:tapture/features/records/records.dart'
    show recordRepositoryProvider;
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../templates/fakes/fake_template_repository.dart';
import '../fakes/fake_record_repository.dart';

const List<FieldDef> _fields = <FieldDef>[
  FieldDef(fieldKey: 'asset_tag', label: 'Asset tag', type: FieldType.text),
  FieldDef(
    fieldKey: 'quantity',
    label: 'Quantity',
    type: FieldType.number,
    sortOrder: 1,
  ),
  FieldDef(
    fieldKey: 'serial',
    label: 'Serial',
    type: FieldType.text,
    validation: <String, Object?>{'maxLength': 6},
    sortOrder: 2,
  ),
  FieldDef(
    fieldKey: 'condition',
    label: 'Condition',
    type: FieldType.choice,
    options: <Object>['Good', 'Faulty'],
    sortOrder: 3,
  ),
];

final TemplateDef _template = aTemplate(fields: _fields);

const StorageFailure _full = StorageFailure(
  message: 'The device storage is full.',
  recoveryAction: 'Free some space and try again.',
);

/// A store whose edits wait for [release], or throw when [throws] is set.
/// Only editValues is ever called on it.
final class _SlowRecords implements RecordRepository {
  _SlowRecords(this._inner);

  final FakeRecordRepository _inner;
  final Completer<void> release = Completer<void>();
  bool throws = false;
  int calls = 0;

  @override
  Future<Result<void>> editValues(String id, List<RecordValueEdit> edits) {
    calls++;
    if (throws) {
      throw StateError('The disk went away.');
    }
    return release.future.then((void _) => _inner.editValues(id, edits));
  }

  @override
  Object? noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

/// A template store that cannot read.
final class _BrokenTemplates implements TemplateRepository {
  @override
  Future<Result<TemplateDef?>> byId(String id) async {
    return const FailureResult<TemplateDef?>(_full);
  }

  @override
  Object? noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  late FakeRecordRepository records;
  late ProviderContainer container;

  ProviderContainer open(
    RecordRepository store, {
    List<Override> overrides = const <Override>[],
  }) {
    return ProviderContainer(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        recordRepositoryProvider.overrideWith((Ref _) => store),
        fieldEditorBindingsProvider.overrideWithValue(
          templateFieldEditorBindings,
        ),
        ...overrides,
      ],
    );
  }

  RecordEntry seed({RecordStatus status = RecordStatus.captured}) {
    final RecordEntry record = aRecordEntry(
      id: 'r1',
      status: status,
      fields: const <String, String>{'asset_tag': 'A-17', 'quantity': '2'},
    );
    records.seedEntry(record);
    return record;
  }

  RecordFieldChange change(RecordEntry record, String fieldKey, String text) {
    final RecordEditEntry entry = recordEditEntries(
      template: _template,
      record: record,
    ).firstWhere((RecordEditEntry entry) => entry.fieldKey == fieldKey);
    return (entry: entry, text: text);
  }

  setUp(() {
    records = FakeRecordRepository();
    container = open(records);
  });

  tearDown(() {
    container.dispose();
    records.dispose();
  });

  RecordEditController controller([ProviderContainer? on]) {
    final ProviderContainer target = on ?? container;
    // Keep the auto-dispose controller alive for the whole test.
    target.listen(recordEditControllerProvider('r1'), (_, _) {});
    return target.read(recordEditControllerProvider('r1').notifier);
  }

  RecordEditState stateOf([ProviderContainer? on]) {
    return (on ?? container).read(recordEditControllerProvider('r1'));
  }

  test('it starts idle', () {
    controller();

    expect(stateOf().saving, isFalse);
    expect(stateOf().failure, isNull);
    expect(stateOf().problems, isEmpty);
  });

  test('nothing changed is a success that writes nothing', () async {
    seed();

    final Result<void> saved = await controller().save(
      const <RecordFieldChange>[],
    );

    expect(saved, isA<Success<void>>());
    expect(records.writes, isEmpty);
    expect(stateOf().saving, isFalse);
  });

  test('every change goes to the store in one write', () async {
    final RecordEntry record = seed();

    final Result<void> saved = await controller().save(<RecordFieldChange>[
      change(record, 'asset_tag', 'A-18'),
      change(record, 'condition', 'Good'),
    ]);

    expect(saved, isA<Success<void>>());
    expect(records.writes, <({String method, String id})>[
      (method: 'editValues', id: 'r1'),
    ]);
    final RecordEntry edited = records.entryOf('r1')!;
    expect(edited.valueOf('asset_tag')!.display, 'A-18');
    expect(edited.valueOf('asset_tag')!.raw, 'A-17');
    expect(edited.valueOf('condition')!.display, 'Good');
    expect(edited.valueOf('quantity')!.refined, isNull);
    expect(stateOf().failure, isNull);
    expect(stateOf().problems, isEmpty);
  });

  test(
    'an approved record goes back to review, with the edit audited',
    () async {
      final RecordEntry record = seed(status: RecordStatus.approved);

      await controller().save(<RecordFieldChange>[
        change(record, 'asset_tag', 'A-18'),
      ]);

      expect(records.entryOf('r1')!.status, RecordStatus.needsReview);
      final List<RecordHistoryEvent> history = records.historyOf('r1');
      final RecordHistoryEvent edit = history.firstWhere(
        (RecordHistoryEvent event) =>
            event.kind == RecordHistoryKind.valueChanged,
      );
      expect(
        (edit.fieldKey, edit.previous, edit.next),
        ('asset_tag', 'A-17', 'A-18'),
      );
      expect(
        history.any(
          (RecordHistoryEvent event) =>
              event.kind == RecordHistoryKind.statusChanged &&
              event.next == RecordStatus.needsReview.stored,
        ),
        isTrue,
      );
    },
  );

  test('a value its type refuses writes nothing and names the field', () async {
    final RecordEntry record = seed();

    final Result<void> saved = await controller().save(<RecordFieldChange>[
      change(record, 'asset_tag', 'A-18'),
      change(record, 'serial', 'SERIAL-0042'),
      change(record, 'quantity', 'many'),
    ]);

    expect(saved, isA<FailureResult<void>>());
    final Failure failure = (saved as FailureResult<void>).failure;
    expect(failure, isA<ValidationFailure>());
    expect(stateOf().problems, hasLength(2));
    expect(
      stateOf().problems.first,
      Copy.fieldError('Serial', 'That value is longer than this field allows.'),
    );
    expect(stateOf().problems.last, startsWith('Quantity: '));
    expect(failure.message, stateOf().problems.first);
    expect(stateOf().failure, isNull);
    expect(records.writes, isEmpty);
    expect(records.entryOf('r1')!.valueOf('asset_tag')!.display, 'A-17');
  });

  test('emptying a saved value is refused', () async {
    final RecordEntry record = seed();

    await controller().save(<RecordFieldChange>[
      change(record, 'asset_tag', '  '),
    ]);

    expect(stateOf().problems, <String>[
      Copy.fieldError('Asset tag', Copy.recordValueCannotEmpty),
    ]);
    expect(records.writes, isEmpty);
  });

  test('a store failure is kept, and the next save clears it', () async {
    final RecordEntry record = seed();
    records.writeFailure = _full;

    final Result<void> failed = await controller().save(<RecordFieldChange>[
      change(record, 'asset_tag', 'A-18'),
    ]);

    expect(failed, isA<FailureResult<void>>());
    expect(stateOf().failure, _full);
    expect(stateOf().saving, isFalse);
    expect(stateOf().problems, isEmpty);

    records.writeFailure = null;
    final Result<void> saved = await controller().save(<RecordFieldChange>[
      change(record, 'asset_tag', 'A-18'),
    ]);

    expect(saved, isA<Success<void>>());
    expect(stateOf().failure, isNull);
    expect(records.entryOf('r1')!.valueOf('asset_tag')!.display, 'A-18');
  });

  test('a store that throws is a failure, not a crash', () async {
    final RecordEntry record = seed();
    final _SlowRecords slow = _SlowRecords(records)..throws = true;
    final ProviderContainer throwing = open(slow);
    addTearDown(throwing.dispose);

    final Result<void> saved = await controller(
      throwing,
    ).save(<RecordFieldChange>[change(record, 'asset_tag', 'A-18')]);

    expect(saved, isA<FailureResult<void>>());
    expect(stateOf(throwing).failure, isNotNull);
    expect(stateOf(throwing).saving, isFalse);
  });

  test('saving shows while the write runs, and a second Save meanwhile '
      'writes nothing', () async {
    final RecordEntry record = seed();
    final _SlowRecords slow = _SlowRecords(records);
    final ProviderContainer waiting = open(slow);
    addTearDown(waiting.dispose);
    final RecordEditController edit = controller(waiting);

    final Future<Result<void>> first = edit.save(<RecordFieldChange>[
      change(record, 'asset_tag', 'A-18'),
    ]);
    expect(stateOf(waiting).saving, isTrue);
    final Result<void> second = await edit.save(<RecordFieldChange>[
      change(record, 'asset_tag', 'A-19'),
    ]);
    expect(second, isA<Success<void>>());

    slow.release.complete();
    expect(await first, isA<Success<void>>());
    expect(slow.calls, 1);
    expect(stateOf(waiting).saving, isFalse);
    expect(records.entryOf('r1')!.valueOf('asset_tag')!.display, 'A-18');
  });

  test(
    'a controller no page reads any more still finishes its write',
    () async {
      final RecordEntry record = seed();
      final _SlowRecords slow = _SlowRecords(records);
      final ProviderContainer waiting = open(slow);
      addTearDown(waiting.dispose);
      final ProviderSubscription<RecordEditState> page = waiting.listen(
        recordEditControllerProvider('r1'),
        (_, _) {},
      );
      final RecordEditController edit = waiting.read(
        recordEditControllerProvider('r1').notifier,
      );

      final Future<Result<void>> saving = edit.save(<RecordFieldChange>[
        change(record, 'asset_tag', 'A-18'),
      ]);
      page.close();
      await waiting.pump();
      slow.release.complete();

      expect(await saving, isA<Success<void>>());
      expect(records.entryOf('r1')!.valueOf('asset_tag')!.display, 'A-18');
    },
  );

  test(
    'an edit forgets the refused lines, and keeps a store failure',
    () async {
      final RecordEntry record = seed();
      final RecordEditController edit = controller();

      await edit.save(<RecordFieldChange>[
        change(record, 'serial', 'SERIAL-0042'),
      ]);
      expect(stateOf().problems, isNotEmpty);
      edit.clearProblems();
      expect(stateOf().problems, isEmpty);

      records.writeFailure = _full;
      await edit.save(<RecordFieldChange>[change(record, 'asset_tag', 'A-18')]);
      edit.clearProblems();
      expect(stateOf().failure, _full);
    },
  );

  group('the template values are edited against', () {
    test('is read by id', () async {
      final FakeTemplateRepository templates = FakeTemplateRepository();
      addTearDown(templates.dispose);
      await templates.save(_template);
      final ProviderContainer scope = open(
        records,
        overrides: <Override>[
          templateRepositoryProvider.overrideWith((Ref _) => templates),
        ],
      );
      addTearDown(scope.dispose);

      final TemplateDef? loaded = await scope.read(
        recordEditTemplateProvider('template-1').future,
      );

      expect(loaded?.fields.map((FieldDef field) => field.fieldKey), <String>[
        'asset_tag',
        'quantity',
        'serial',
        'condition',
      ]);
    });

    test('is null once it is gone from this device', () async {
      final FakeTemplateRepository templates = FakeTemplateRepository();
      addTearDown(templates.dispose);
      final ProviderContainer scope = open(
        records,
        overrides: <Override>[
          templateRepositoryProvider.overrideWith((Ref _) => templates),
        ],
      );
      addTearDown(scope.dispose);

      expect(
        await scope.read(recordEditTemplateProvider('removed').future),
        isNull,
      );
    });

    test('surfaces a store that cannot read it', () async {
      final ProviderContainer scope = open(
        records,
        overrides: <Override>[
          templateRepositoryProvider.overrideWith(
            (Ref _) => _BrokenTemplates(),
          ),
        ],
      );
      addTearDown(scope.dispose);

      await expectLater(
        scope.read(recordEditTemplateProvider('template-1').future),
        throwsA(_full),
      );
    });
  });
}

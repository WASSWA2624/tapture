import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override, ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/presentation/record_history_providers.dart';
import 'package:tapture/features/records/records.dart'
    show recordRepositoryProvider;
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../templates/fakes/fake_template_repository.dart';
import '../fakes/fake_record_repository.dart';

void main() {
  late FakeRecordRepository records;
  late FakeTemplateRepository templates;
  late ProviderContainer container;

  ProviderContainer open({TemplateRepository? templateStore}) {
    return ProviderContainer(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        recordRepositoryProvider.overrideWith((Ref _) => records),
        templateRepositoryProvider.overrideWith(
          (Ref _) => templateStore ?? templates,
        ),
      ],
    );
  }

  /// Keeps [provider] alive the way the open history page does.
  ProviderSubscription<Object?> watch(ProviderListenable<Object?> provider) {
    final ProviderSubscription<Object?> watching = container.listen<Object?>(
      provider,
      (Object? _, Object? _) {},
    );
    addTearDown(watching.close);
    return watching;
  }

  setUp(() {
    records = FakeRecordRepository();
    templates = FakeTemplateRepository();
    container = open();
  });

  tearDown(() {
    container.dispose();
    records.dispose();
    templates.dispose();
  });

  RecordHistoryEvent line(String id, int minute) {
    return RecordHistoryEvent(
      id: id,
      at: DateTime.utc(2026, 9, 14, 12, minute),
      kind: RecordHistoryKind.valueChanged,
      operator: 'Ann',
      device: 'device-a',
      fieldKey: 'serial',
      next: 'SN-$minute',
    );
  }

  group('recordHistoryProvider', () {
    test('reads the history oldest first and follows every new line', () async {
      final String id = records.seedEntry(aRecordEntry(id: 'record-1'));
      records.seedHistory(id, <RecordHistoryEvent>[line('b', 5), line('a', 1)]);
      final Completer<List<RecordHistoryEvent>> grown =
          Completer<List<RecordHistoryEvent>>();
      final ProviderSubscription<AsyncValue<List<RecordHistoryEvent>>>
      watching = container.listen<AsyncValue<List<RecordHistoryEvent>>>(
        recordHistoryProvider(id),
        (
          AsyncValue<List<RecordHistoryEvent>>? _,
          AsyncValue<List<RecordHistoryEvent>> next,
        ) {
          final List<RecordHistoryEvent>? lines = next.value;
          if (lines != null && lines.length == 3 && !grown.isCompleted) {
            grown.complete(lines);
          }
        },
      );
      addTearDown(watching.close);

      final List<RecordHistoryEvent> first = await container.read(
        recordHistoryProvider(id).future,
      );
      expect(first.map((RecordHistoryEvent event) => event.id), <String>[
        'a',
        'b',
      ]);

      records.seedHistory(id, <RecordHistoryEvent>[line('c', 9)]);
      final List<RecordHistoryEvent> after = await grown.future;
      expect(after.map((RecordHistoryEvent event) => event.id), <String>[
        'a',
        'b',
        'c',
      ]);
    });

    test('a record with no history reads as an empty list', () async {
      final String id = records.seedEntry(aRecordEntry(id: 'record-1'));
      watch(recordHistoryProvider(id));

      expect(await container.read(recordHistoryProvider(id).future), isEmpty);
    });

    test('a read failure surfaces at once, without a retry', () async {
      const StorageFailure failure = StorageFailure(
        message: 'The history could not be read.',
      );
      records.readFailure = failure;
      watch(recordHistoryProvider('record-1'));

      await expectLater(
        container.read(recordHistoryProvider('record-1').future),
        throwsA(same(failure)),
      );
      expect(
        container.read(recordHistoryProvider('record-1')).error,
        same(failure),
      );
    });

    test('the history is dropped once no page reads it', () async {
      final String id = records.seedEntry(aRecordEntry(id: 'record-1'));
      final ProviderSubscription<Object?> watching = watch(
        recordHistoryProvider(id),
      );
      await container.read(recordHistoryProvider(id).future);
      expect(container.exists(recordHistoryProvider(id)), isTrue);

      watching.close();
      await container.pump();
      expect(container.exists(recordHistoryProvider(id)), isFalse);
    });
  });

  group('recordHistoryTemplateProvider', () {
    test('reads a template on this device', () async {
      await templates.save(aTemplate(id: 't1', name: 'Boiler'));
      watch(recordHistoryTemplateProvider('t1'));

      final TemplateDef? found = await container.read(
        recordHistoryTemplateProvider('t1').future,
      );
      expect(found?.name, 'Boiler');
    });

    test('a template not on this device reads as null', () async {
      watch(recordHistoryTemplateProvider('gone'));

      expect(
        await container.read(recordHistoryTemplateProvider('gone').future),
        isNull,
      );
    });

    test('a template store that fails reads as null, so labels fall back '
        'to keys instead of hiding the history', () async {
      container.dispose();
      container = open(templateStore: _FailingTemplates());
      watch(recordHistoryTemplateProvider('t1'));

      expect(
        await container.read(recordHistoryTemplateProvider('t1').future),
        isNull,
      );
      expect(
        container.read(recordHistoryTemplateProvider('t1')).hasError,
        isFalse,
      );
    });
  });
}

/// A template store whose every read fails.
final class _FailingTemplates implements TemplateRepository {
  static const StorageFailure _failure = StorageFailure(
    message: 'Templates could not be read.',
  );

  @override
  Future<Result<TemplateDef?>> byId(String id) async {
    return const FailureResult<TemplateDef?>(_failure);
  }

  @override
  Stream<List<TemplateDef>> watchByProject(String projectId) {
    return Stream<List<TemplateDef>>.error(_failure);
  }

  @override
  Future<Result<TemplateDef>> save(TemplateDef template) async {
    return const FailureResult<TemplateDef>(_failure);
  }

  @override
  Future<Result<void>> delete(String id, {required String reason}) async {
    return const FailureResult<void>(_failure);
  }
}

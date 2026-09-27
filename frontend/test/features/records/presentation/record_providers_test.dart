import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override, ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/projects/projects.dart'
    show projectSettingsStoreProvider;
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/presentation/record_providers.dart';
import 'package:tapture/features/records/records.dart'
    show recordRepositoryProvider;
import 'package:tapture/features/settings/settings.dart';

import '../../../support/factories.dart';
import '../fakes/fake_record_repository.dart';

void main() {
  late FakeRecordRepository records;
  late SettingsStore settings;
  late ProviderContainer container;

  ProviderContainer open({List<Override> extra = const <Override>[]}) {
    return ProviderContainer(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        recordRepositoryProvider.overrideWith((Ref _) => records),
        projectSettingsStoreProvider.overrideWith((Ref _) => settings),
        ...extra,
      ],
    );
  }

  /// Keeps [provider] alive the way a watching screen does.
  void watch(ProviderListenable<Object?> provider) {
    final ProviderSubscription<Object?> watching = container.listen<Object?>(
      provider,
      (Object? _, Object? _) {},
    );
    addTearDown(watching.close);
  }

  setUp(() {
    records = FakeRecordRepository();
    settings = SettingsStore.fake();
    container = open();
  });

  tearDown(() {
    container.dispose();
    records.dispose();
  });

  group('recordEntryProvider', () {
    test('reads a record whole and follows every change to it', () async {
      final String id = records.seedEntry(
        aRecordEntry(id: 'record-1', status: RecordStatus.needsReview),
      );
      final Completer<RecordEntry?> approved = Completer<RecordEntry?>();
      final ProviderSubscription<AsyncValue<RecordEntry?>> watching = container
          .listen<AsyncValue<RecordEntry?>>(recordEntryProvider(id), (
            AsyncValue<RecordEntry?>? _,
            AsyncValue<RecordEntry?> next,
          ) {
            final RecordEntry? entry = next.value;
            if (entry?.status == RecordStatus.approved &&
                !approved.isCompleted) {
              approved.complete(entry);
            }
          });
      addTearDown(watching.close);

      final RecordEntry? first = await container.read(
        recordEntryProvider(id).future,
      );
      expect(first?.id, 'record-1');
      expect(first?.status, RecordStatus.needsReview);

      await records.transition(id, RecordStatus.approved);
      final RecordEntry? after = await approved.future;

      expect(after?.status, RecordStatus.approved);
      expect(after?.approvedBy, records.operator);
    });

    test('is null for a record that is not on this device', () async {
      watch(recordEntryProvider('missing'));

      expect(
        await container.read(recordEntryProvider('missing').future),
        isNull,
      );
    });

    test('keeps a deleted record, whose status says so', () async {
      final String id = records.seedDeleted(aRecordEntry(id: 'record-1'));
      watch(recordEntryProvider(id));

      final RecordEntry? entry = await container.read(
        recordEntryProvider(id).future,
      );
      expect(entry?.status, RecordStatus.deleted);
      expect(entry?.isDeleted, isTrue);
    });

    test('surfaces a read failure without retrying it', () async {
      records.readFailure = const StorageFailure(
        message: 'The records could not be read.',
        recoveryAction: 'Try again.',
      );
      watch(recordEntryProvider('record-1'));

      await expectLater(
        container.read(recordEntryProvider('record-1').future),
        throwsA(isA<StorageFailure>()),
      );
      expect(container.read(recordEntryProvider('record-1')).hasError, isTrue);
    });
  });

  group('recordPurgeJobProvider', () {
    test('is null until main supplies a job, so suites never purge', () {
      expect(container.read(recordPurgeJobProvider), isNull);
    });
  });

  group('recordRetentionDaysProvider', () {
    test('is the default window when nothing is stored', () {
      expect(
        container.read(recordRetentionDaysProvider),
        AppConstants.retention.days,
      );
    });

    test('reads the operator setting', () {
      settings = SettingsStore.fake(
        stored: <String, Object?>{SettingKeys.retentionDays.name: 7},
      );
      final ProviderContainer scoped = open();
      addTearDown(scoped.dispose);

      expect(scoped.read(recordRetentionDaysProvider), 7);
    });

    test('follows a change to the setting while it is watched', () async {
      final ProviderSubscription<int> watching = container.listen<int>(
        recordRetentionDaysProvider,
        (int? _, int _) {},
      );
      addTearDown(watching.close);
      expect(watching.read(), AppConstants.retention.days);

      await settings.write(SettingKeys.retentionDays, 7);
      await container.pump();

      expect(watching.read(), 7);
    });
  });

  group('recordClockProvider', () {
    test('is the system clock unless a test fixes the time', () {
      expect(container.read(recordClockProvider), isA<SystemClock>());

      final FixedClock fixed = FixedClock(DateTime.utc(2026, 9, 27));
      final ProviderContainer scoped = open(
        extra: <Override>[recordClockProvider.overrideWith((Ref _) => fixed)],
      );
      addTearDown(scoped.dispose);
      expect(scoped.read(recordClockProvider).nowUtc(), fixed.nowUtc());
    });
  });
}

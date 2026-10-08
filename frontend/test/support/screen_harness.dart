import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/cloud/destination_secrets.dart';
import 'package:tapture/core/constants/template_assets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/database_provider.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/network/network.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/fields/dictation_scope.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/cloud/data/destination_repository_impl.dart';
import 'package:tapture/features/cloud/presentation/destination_list_controller.dart';
import 'package:tapture/features/context/context.dart';
import 'package:tapture/features/exports/exports.dart';
import 'package:tapture/features/processing/processing.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/quality/quality.dart';
import 'package:tapture/features/records/records.dart';
import 'package:tapture/features/reference/reference.dart';
import 'package:tapture/features/review/review.dart';
import 'package:tapture/features/settings/presentation/settings_screen.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/templates.dart';

import '../features/reference/reference_fixtures.dart' show aDataset;
import '../features/review/fakes/fake_review_repository.dart';
import 'empty_state_matchers.dart';
import 'factories.dart';
import 'fakes/fake_context_repository.dart';
import 'fakes/fake_deliverable_repository.dart';
import 'fakes/fake_export_repository.dart';
import 'fakes/fake_photo_repository.dart';
import 'fakes/fake_processing_repository.dart';
import 'fakes/fake_project_repository.dart';
import 'fakes/fake_quality_repository.dart';
import 'fakes/fake_record_repository.dart';
import 'fakes/fake_reference_repository.dart';
import 'fakes/fake_stt_service.dart';
import 'fakes/fake_template_repository.dart';
import 'pump_app.dart';
import 'pump_external_work.dart';
import 'screen_database.dart';
import 'screen_fixture.dart';
import 'screen_fixtures.dart';
import 'screen_fonts.dart';

/// The production router and shell with isolated, empty repository sources.
/// The destination provider currently requires its concrete store; only that
/// store and template-migration reads use an isolated in-memory database.
final class ScreenHarness {
  ScreenHarness._(this.container, this.router, this._database, this._release);

  final ProviderContainer container;
  final GoRouter router;
  final AppDatabase _database;
  final List<void Function()> _release;
  bool _closed = false;

  static Future<ScreenHarness> pump(
    WidgetTester tester,
    ScreenFixture fixture, {
    Brightness brightness = Brightness.light,
    bool outdoor = false,
    double textScale = 1,
    String? expectedLocation,
    Locale? locale,
  }) async {
    final FakeProjectRepository projects = FakeProjectRepository();
    final FakeRecordRepository records = FakeRecordRepository();
    final FakeTemplateRepository templates = FakeTemplateRepository();
    final FakeReferenceRepository reference = FakeReferenceRepository();
    final FakeContextRepository context = FakeContextRepository();
    final FakeProcessingRepository processing = FakeProcessingRepository();
    final FakeExportRepository exports = FakeExportRepository();
    final FakePhotoRepository photos = FakePhotoRepository();
    final AppDatabase database = createScreenDatabase();
    if (fixture.project) {
      (await projects.createReady(name: 'Test project')).getOrThrow();
    }
    if (fixture.template) {
      (await templates.save(
        aTemplate(projectId: ScreenFixtures.project),
      )).getOrThrow();
    }
    if (fixture.record) {
      records.seedEntry(aRecordEntry(projectId: ScreenFixtures.project));
      exports.summary = (
        projectName: 'Test project',
        records: 1,
        photos: 0,
        audioClips: 0,
        unprocessed: 1,
        needsReview: 0,
        approved: 0,
        templates: const <ExportTemplateCount>[],
        firstCapturedAt: null,
        lastCapturedAt: null,
      );
    }
    if (fixture.dataset) {
      (await reference.importDataset(
        dataset: aDataset(id: 'ds', projectId: ScreenFixtures.project),
        rows: const <ReferenceRow>[],
      )).getOrThrow();
    }
    if (fixture.screen == 'LicencesScreen') LicenseRegistry.reset();
    final SettingsStore settings = SettingsStore.fake();
    final ProviderContainer container = ProviderContainer(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(database),
        downloadServiceProvider.overrideWithValue(
          DownloadService.fake(
            destination: Copy.downloadsTaptureFolder,
            canOpenFolder: true,
            canChooseLocation: true,
            canOpenExternally: true,
            canDownloadCopy: true,
            canShareToApps: true,
          ),
        ),
        destinationRepositoryProvider.overrideWithValue(
          DestinationRepositoryImpl(
            database: database,
            secrets: DestinationSecrets(
              SecureStorage.fake(backing: <SecretKey, String>{}),
            ),
            clock: FixedClock(DateTime.utc(2026, 9, 28)),
            deviceId: 'test-device',
            ids: UuidV7Service(FixedClock(DateTime.utc(2026, 9, 28))),
          ),
        ),
        projectSettingsStoreProvider.overrideWithValue(settings),
        projectRepositoryProvider.overrideWithValue(projects),
        recordRepositoryProvider.overrideWithValue(records),
        templateRepositoryProvider.overrideWithValue(templates),
        referenceRepositoryProvider.overrideWithValue(reference),
        contextRepositoryProvider.overrideWithValue(context),
        processingRepositoryProvider.overrideWithValue(processing),
        qualityRepositoryProvider.overrideWithValue(FakeQualityRepository()),
        reviewRepositoryProvider.overrideWithValue(
          FakeReviewRepository(records),
        ),
        exportRepositoryProvider.overrideWithValue(exports),
        deliverableRepositoryProvider.overrideWithValue(
          FakeDeliverableRepository(),
        ),
        photoRepositoryProvider.overrideWithValue(photos),
        recordClockProvider.overrideWithValue(
          FixedClock(DateTime.utc(2026, 9, 28)),
        ),
        networkStateProvider.overrideWith(
          (Ref _) => Stream<NetworkState>.value(NetworkState.offline),
        ),
        destinationKindsProvider.overrideWith(
          (Ref _) async => const <DestinationKind>[DestinationKind.localFolder],
        ),
        shippedTemplateLoaderProvider.overrideWithValue(
          ShippedTemplateLoader(
            templates: templates,
            readAsset: (String path) async => switch (path) {
              TemplateAssets.catalogueIndex =>
                '{"categories":[],"packs":[],"supergroups":[]}',
              TemplateAssets.groups ||
              TemplateAssets.catalogueGroups => '{"base":{"fields":[]}}',
              _ => throw TestFailure('Unexpected shipped asset: $path'),
            },
          ),
        ),
        if (fixture.screen == 'SettingsScreen')
          settingsScreenOverride(load: () async => []),
        if (fixture.screen == 'AboutScreen')
          aboutOverride(load: () async => (version: '', build: '')),
      ],
    );
    if (fixture.project) {
      container
          .read(currentProjectProvider.notifier)
          .open(ScreenFixtures.project);
    }
    final GoRouter router = container.read(routerProvider);
    final ScreenHarness harness =
        ScreenHarness._(container, router, database, <void Function()>[
          projects.dispose,
          records.dispose,
          templates.dispose,
          reference.dispose,
          context.dispose,
          processing.dispose,
          exports.dispose,
          photos.dispose,
        ]);
    addTearDown(() => harness.close(tester));
    await tester.runAsync(() async {
      await ScreenFonts.load();
      await database.customSelect('SELECT 1').get();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: ScreenFonts.theme(
            buildTheme(brightness: brightness, outdoor: outdoor),
          ),
          routerConfig: router,
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: DictationScope(
              service: FakeSttService(),
              languageTag: 'en-UG',
              onDeviceOnly: true,
              child: child!,
            ),
          ),
        ),
      ),
    );
    router.go(fixture.location);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      Uri.parse(expectedLocation ?? fixture.location).path,
      reason: '${fixture.screen} was redirected',
    );
    final Finder screen = find.byWidgetPredicate(
      (Widget widget) => widget.runtimeType.toString() == fixture.screen,
    );
    await revealScrollableBody(tester, screen);
    await pumpExternalWork(tester, () => screen.evaluate().isNotEmpty);
    expect(screen, findsOneWidget);
    await pumpExternalWork(
      tester,
      () => find
          .descendant(of: screen, matching: find.byType(AppSkeleton))
          .evaluate()
          .isEmpty,
    );
    final Finder errors = find.byType(AppErrorState);
    final String failures = tester
        .widgetList<AppErrorState>(errors)
        .map((AppErrorState state) => state.failure.message)
        .join('; ');
    expect(
      errors,
      findsNothing,
      reason: '${fixture.screen} must load its real empty state: $failures',
    );
    expect(tester.takeException(), isNull);
    return harness;
  }

  /// Navigates through the actual router after an empty-state action.
  Future<void> expectLocation(WidgetTester tester, String location) async {
    await pumpUntil(
      tester,
      () =>
          router.routeInformationProvider.value.uri.path ==
          Uri.parse(location).path,
    );
    expect(
      router.routeInformationProvider.value.uri.path,
      Uri.parse(location).path,
    );
  }

  /// Releases streams and the database before the next matrix cell is pumped.
  Future<void> close(WidgetTester tester) async {
    if (_closed) return;
    _closed = true;
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    for (final void Function() release in _release) {
      release();
    }
    await tester.runAsync(_database.close);
  }
}

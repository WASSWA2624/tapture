import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_thumbnails.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/projects/projects.dart'
    show projectSettingsStoreProvider;
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/presentation/record_providers.dart';
import 'package:tapture/features/records/presentation/records_list_screen.dart';
import 'package:tapture/features/records/records.dart'
    show recordRepositoryProvider;
import 'package:tapture/features/settings/settings.dart';

import '../fakes/fake_record_repository.dart';

/// Test harness shared by the records list, filter sheet and sort menu
/// tests: a repository that counts what the list reads, and a router that
/// hosts the list and stands in for the pages it opens.

/// The instant the harness's clock reads.
final DateTime harnessNow = DateTime.utc(2026, 9, 17, 8);

/// Wraps [inner] and records every page and count the list reads, how many
/// page reads are open at once, and lets a test hold or fail a page.
final class CountingRecords implements RecordRepository {
  /// Wraps [inner].
  CountingRecords(this.inner);

  /// The repository every read and write goes to.
  final FakeRecordRepository inner;

  /// Every page read, in order.
  final List<({int offset, int limit})> pageReads =
      <({int offset, int limit})>[];

  /// How many count reads the list opened.
  int countReads = 0;

  /// Page reads open now.
  int livePages = 0;

  /// The most page reads that were ever open at once.
  int mostLivePages = 0;

  /// Pages, by offset, whose read never answers.
  final Set<int> heldOffsets = <int>{};

  /// Pages, by offset, whose read fails with the mapped failure.
  final Map<int, Failure> failedOffsets = <int, Failure>{};

  /// When true, the count never answers, so the list stays loading.
  bool holdCount = false;

  @override
  Stream<List<RecordSummary>> watchPage(
    String projectId, {
    required RecordFilter filter,
    required RecordSort sort,
    required int offset,
    required int limit,
  }) {
    pageReads.add((offset: offset, limit: limit));
    final Failure? failure = failedOffsets[offset];
    final Stream<List<RecordSummary>> source = failure != null
        ? Stream<List<RecordSummary>>.error(failure)
        : heldOffsets.contains(offset)
        ? Stream<List<RecordSummary>>.multi((_) {})
        : inner.watchPage(
            projectId,
            filter: filter,
            sort: sort,
            offset: offset,
            limit: limit,
          );
    return Stream<List<RecordSummary>>.multi((
      MultiStreamController<List<RecordSummary>> listener,
    ) {
      livePages++;
      if (livePages > mostLivePages) {
        mostLivePages = livePages;
      }
      final StreamSubscription<List<RecordSummary>> read = source.listen(
        listener.add,
        onError: listener.addError,
      );
      listener.onCancel = () {
        livePages--;
        unawaited(read.cancel());
      };
    });
  }

  @override
  Stream<int> watchCount(String projectId, RecordFilter filter) {
    countReads++;
    if (holdCount) {
      return Stream<int>.multi((_) {});
    }
    return inner.watchCount(projectId, filter);
  }

  @override
  Stream<RecordEntry?> watchEntry(String id) => inner.watchEntry(id);

  @override
  Future<Result<RecordEntry?>> byId(String id) => inner.byId(id);

  @override
  Future<Result<RecordFacets>> facets(String projectId) =>
      inner.facets(projectId);

  @override
  Stream<List<RecordHistoryEvent>> watchHistory(String id) =>
      inner.watchHistory(id);

  @override
  Stream<List<DeletedRecord>> watchBin() => inner.watchBin();

  @override
  Future<Result<RecordEntry>> save(RecordDraft draft) => inner.save(draft);

  @override
  Future<Result<void>> transition(
    String id,
    RecordStatus to, {
    String? reason,
  }) => inner.transition(id, to, reason: reason);

  @override
  Future<Result<void>> editValues(String id, List<RecordValueEdit> edits) =>
      inner.editValues(id, edits);

  @override
  Future<Result<TemplateChangePlan>> planTemplateChange(
    String id,
    String templateId,
  ) => inner.planTemplateChange(id, templateId);

  @override
  Future<Result<void>> changeTemplate(String id, String templateId) =>
      inner.changeTemplate(id, templateId);

  @override
  Future<Result<void>> delete(String id, {required String reason}) =>
      inner.delete(id, reason: reason);

  @override
  Future<Result<void>> restore(String id) => inner.restore(id);
}

/// The text a stand-in page shows for [location].
String openedText(String location) => 'opened $location';

/// Pumps the records list inside a router at [location], over [records],
/// remembering criteria in [settings]. Every page the list opens is a
/// stand-in that names its location.
Future<GoRouter> pumpRecordsList(
  WidgetTester tester, {
  required RecordRepository records,
  SettingsStore? settings,
  String? location,
  List<Override> overrides = const <Override>[],
}) async {
  final GoRouter router = GoRouter(
    initialLocation: location ?? RoutePaths.projectRecords('project-1'),
    routes: <RouteBase>[
      GoRoute(
        path: '/projects/:projectId/records',
        builder: (BuildContext _, GoRouterState state) => RecordsListScreen(
          projectId: state.pathParameters['projectId'],
          initialStatus: _statusOf(state),
        ),
      ),
      GoRoute(
        path: RoutePaths.records,
        builder: (BuildContext _, GoRouterState state) =>
            RecordsListScreen(initialStatus: _statusOf(state)),
      ),
      for (final String path in <String>[
        '/projects/:projectId/records/:recordId',
        '/projects/:projectId/records/:recordId/edit',
        '/projects/:projectId/capture',
        '/records/:recordId',
        RoutePaths.projects,
      ])
        GoRoute(
          path: path,
          builder: (BuildContext _, GoRouterState state) =>
              Scaffold(body: Text(openedText(state.uri.path))),
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        recordRepositoryProvider.overrideWith((Ref _) => records),
        projectSettingsStoreProvider.overrideWith(
          (Ref _) => settings ?? SettingsStore.fake(),
        ),
        photoThumbnailsProvider.overrideWith(
          (Ref _) => PhotoThumbnails.fake(const <String, String>{}),
        ),
        recordClockProvider.overrideWith((Ref _) => FixedClock(harnessNow)),
        ...overrides,
      ],
      child: MaterialApp.router(
        theme: buildTheme(brightness: Brightness.light),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

RecordStatus? _statusOf(GoRouterState state) {
  final String? raw = state.uri.queryParameters[RoutePaths.filterQuery];
  return raw == null ? null : RecordStatus.fromStored(raw);
}

/// The container the pumped list reads from.
ProviderContainer listContainer(WidgetTester tester) {
  return ProviderScope.containerOf(
    tester.element(find.byType(RecordsListScreen)),
  );
}

/// The titles of the rows on screen, top to bottom.
List<String> visibleTitles(WidgetTester tester) {
  final List<Element> rows = find
      .byWidgetPredicate(
        (Widget widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith('record-row-'),
      )
      .evaluate()
      .toList();
  rows.sort(
    (Element a, Element b) => tester
        .getTopLeft(find.byWidget(a.widget))
        .dy
        .compareTo(tester.getTopLeft(find.byWidget(b.widget)).dy),
  );
  return <String>[
    for (final Element row in rows) (row.widget as AppListTile).title,
  ];
}

/// Finds the list row of record [id].
Finder rowOf(String id) => find.byKey(ValueKey<String>('record-row-$id'));

/// Sets a [size] window at [scale] text for the rest of the test.
void setSurface(WidgetTester tester, Size size, {double scale = 1}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

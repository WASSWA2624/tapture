import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_thumbnails.dart';
import 'package:tapture/core/lifecycle/deleted_entity.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_list_viewport.dart';
import 'package:tapture/core/widgets/app_photo_thumb.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/core/widgets/record_thumb.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/capture/capture.dart'
    show
        photoRepositoryProvider,
        captureDocumentRepositoryProvider,
        CaptureDocumentRepository,
        DocumentDraft;
import 'package:tapture/features/projects/projects.dart'
    show projectSettingsStoreProvider, projectRepositoryProvider;
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/presentation/record_providers.dart';
import 'package:tapture/features/records/presentation/recycle_bin_screen.dart';
import 'package:tapture/features/records/records.dart'
    show recordRepositoryProvider;
import 'package:tapture/features/settings/settings.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/browser_text_contrast_guideline.dart';
import '../../../support/factories.dart';
import '../../../support/fakes/fake_photo_repository.dart';
import '../../../support/screen_fonts.dart';
import '../../../support/screen_matrix.dart';
import '../../projects/fakes/fake_project_repository.dart';
import '../fakes/fake_purge_store.dart';
import '../fakes/fake_record_repository.dart';

const StorageFailure _locked = StorageFailure(
  message: 'That record is locked by a merge.',
  recoveryAction: 'Finish the merge, then try again.',
);

const StorageFailure _unreadable = StorageFailure(
  message: 'The recycle bin could not be read.',
  recoveryAction: 'Try again in a moment.',
);

/// Fixed local display time across host time zones, stored as a UTC instant.
final DateTime _now = DateTime(2026, 9, 20, 11).toUtc();

final class _DeletedAttachments implements CaptureDocumentRepository {
  @override
  Stream<List<DeletedEntity>> watchDeleted() =>
      Stream<List<DeletedEntity>>.value(<DeletedEntity>[
        for (final DeletedEntityKind kind in <DeletedEntityKind>[
          DeletedEntityKind.audio,
          DeletedEntityKind.document,
        ])
          DeletedEntity(
            id: kind.name,
            kind: kind,
            name: '${kind.name}.bin',
            projectId: 'project-1',
            projectName: 'North wing',
            deletedAt: _now,
          ),
      ]);
  @override
  Future<Result<void>> restore(String id) async => const Success<void>(null);
  @override
  Future<Result<DocumentDraft>> import({
    required Uint8List bytes,
    required String filename,
    required String projectId,
    required String folder,
  }) async => const FailureResult<DocumentDraft>(CancelledFailure());
}

void main() {
  late FakeRecordRepository records;

  setUp(() {
    records = FakeRecordRepository(clock: FixedClock(_now));
  });

  tearDown(() {
    records.dispose();
  });

  /// Deletes record [id] of project-1 [daysAgo] whole days before [_now],
  /// from [previous].
  String binned(
    String id, {
    int daysAgo = 1,
    RecordStatus previous = RecordStatus.needsReview,
    String? name,
    int? number,
    int photos = 0,
    Map<String, String>? fields,
  }) {
    return records.seedDeleted(
      aRecordEntry(
        id: id,
        name: name,
        number: number,
        photos: photos,
        fields: fields,
      ),
      deletedAt: _now.subtract(Duration(days: daysAgo)),
      previous: previous,
    );
  }

  Future<void> pump(
    WidgetTester tester, {
    RecordRepository? repository,
    PurgeJob? job,
    int? retentionDays,
    bool settle = true,
    FakeProjectRepository? projects,
    FakePhotoRepository? photos,
    CaptureDocumentRepository? attachments,
    ScreenMatrix? cell,
    Locale locale = const Locale('en'),
  }) async {
    await tester.runAsync(ScreenFonts.load);
    if (cell != null) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = cell.size;
      tester.platformDispatcher.textScaleFactorTestValue = cell.textScale;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
    }
    await tester.pumpWidget(
      ProviderScope(
        retry: (int _, Object _) => null,
        overrides: <Override>[
          if (projects != null)
            projectRepositoryProvider.overrideWithValue(projects),
          if (photos != null) photoRepositoryProvider.overrideWithValue(photos),
          if (attachments != null)
            captureDocumentRepositoryProvider.overrideWithValue(attachments),
          recordRepositoryProvider.overrideWith(
            (Ref _) => repository ?? records,
          ),
          projectSettingsStoreProvider.overrideWith(
            (Ref _) => SettingsStore.fake(
              stored: <String, Object?>{
                SettingKeys.retentionDays.name: ?retentionDays,
              },
            ),
          ),
          recordClockProvider.overrideWith((Ref _) => FixedClock(_now)),
          recordPurgeJobProvider.overrideWith((Ref _) => job),
          photoThumbnailsProvider.overrideWith(
            (Ref _) => PhotoThumbnails.fake(const <String, String>{}),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ScreenFonts.theme(
            buildTheme(
              brightness: cell?.brightness ?? Brightness.light,
              outdoor: cell?.outdoor ?? false,
            ),
          ),
          home: const RecycleBinScreen(),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    }
  }

  PurgeJob jobOver(PurgeStore store) {
    return PurgeJob(store: store, clock: FixedClock(_now), retentionDays: 30);
  }

  PurgeCandidate candidate(String id, {bool mergeNeeded = false}) {
    return PurgeCandidate(
      recordId: id,
      projectId: 'project-1',
      deletedAt: _now.subtract(const Duration(days: 1)),
      mergeNeeded: mergeNeeded,
    );
  }

  Finder rowOf(String id) =>
      find.byKey(ValueKey<String>('recycle-bin-row-$id'));

  testWidgets(
    'a deleted project is shown once and restores through its owner',
    (WidgetTester tester) async {
      final FakeProjectRepository projects = FakeProjectRepository();
      addTearDown(projects.dispose);
      (await projects.create(aProject(name: 'Parent project'))).getOrThrow();
      (await projects.delete('project-1')).getOrThrow();
      binned('record-1');
      await pump(tester, projects: projects);
      expect(find.text('Parent project'), findsOneWidget);
      expect(rowOf('record-1'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('recycle-bin-empty')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(
          const ValueKey<String>('recycle-bin-restore-project:project-1'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('recycle-bin-row-project:project-1')),
        findsNothing,
      );
      expect(rowOf('record-1'), findsOneWidget);
      expect(find.text(Copy.recycleEmptyRecords(1)), findsOneWidget);
    },
  );

  Future<void> pumpMixed(
    WidgetTester tester,
    ScreenMatrix cell, {
    Locale locale = const Locale('en'),
  }) async {
    final FakeProjectRepository projects = FakeProjectRepository();
    final FakePhotoRepository photos = FakePhotoRepository(
      clock: FixedClock(_now),
    );
    addTearDown(projects.dispose);
    addTearDown(photos.dispose);
    (await projects.create(
      aProject(
        id: 'deleted-project',
        name: 'Deleted project',
        updatedAt: DateTime(2026, 9, 17, 11).toUtc(),
      ),
    )).getOrThrow();
    (await projects.delete('deleted-project')).getOrThrow();
    (await photos.save((
      id: 'photo',
      projectId: 'project-1',
      recordId: null,
      relativePath: 'photos/evidence.jpg',
      sha256: 'photo-hash',
    ))).getOrThrow();
    (await photos.delete('photo', reason: 'operator-delete')).getOrThrow();
    binned('record-1');
    await pump(
      tester,
      projects: projects,
      photos: photos,
      attachments: _DeletedAttachments(),
      cell: cell,
      locale: locale,
    );
  }

  Future<void> reachPhotoRestore(WidgetTester tester) async {
    final Finder restore = find.byKey(
      const ValueKey<String>('recycle-bin-restore-photo:photo'),
    );
    final Finder viewport = find.byType(AppListViewport).first;
    if (tester.getRect(viewport).height < 300) {
      await tester.drag(viewport, const Offset(0, -160));
      await tester.pumpAndSettle();
    }
    Rect visible = Rect.zero;
    for (int attempt = 0; attempt < 30; attempt++) {
      final Rect bounds = tester.getRect(viewport);
      double delta = -48;
      if (restore.evaluate().isNotEmpty) {
        final Rect control = tester.getRect(restore);
        visible = control.intersect(bounds);
        if (visible.height >= 48) break;
        delta = (bounds.center.dy - control.center.dy).clamp(-80, 80);
      }
      await tester.drag(viewport, Offset(0, delta));
      await tester.pumpAndSettle();
    }
    expect(restore, findsOneWidget);
    expect(visible.height, greaterThanOrEqualTo(48));
    expect(visible.width, greaterThanOrEqualTo(48));
    await tester.tapAt(visible.center);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('recycle-bin-row-photo:photo')),
      findsNothing,
    );
    final Finder empty = find.byKey(
      const ValueKey<String>('recycle-bin-empty'),
    );
    // Let the successful-restore feedback clear before reaching the footer.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.ensureVisible(empty);
    expect(empty.hitTestable(), findsOneWidget);
  }

  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets(
      'mixed recycle bin fits ${cell.description}',
      (WidgetTester tester) async {
        await pumpMixed(tester, cell);
        expect(tester.takeException(), isNull);
        expect(find.text(Copy.recycleEmptyRecords(1)), findsOneWidget);
        await reachPhotoRestore(tester);
        expect(tester.takeException(), isNull);
      },
      variant: kIsWeb
          ? TargetPlatformVariant.only(defaultTargetPlatform)
          : TargetPlatformVariant.all(),
    );
  }

  for (final ({String name, ScreenMatrix cell}) corner
      in ScreenMatrix.corners) {
    testWidgets('mixed recycle bin golden ${corner.name}', (
      WidgetTester tester,
    ) async {
      await pumpMixed(tester, corner.cell);
      if (corner.cell.size.height == 320) {
        await tester.drag(
          find.byType(AppListViewport).first,
          const Offset(0, -160),
        );
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/recycle_bin_${corner.name}.png'),
      );
    }, skip: kIsWeb);
  }

  testWidgets(
    'mixed recycling remains reachable with expanded pseudo-locale copy',
    (WidgetTester tester) async {
      await pumpMixed(
        tester,
        const ScreenMatrix(Size(393, 320), 2, Brightness.light, false),
        locale: const Locale('en', 'XA'),
      );
      final LocalizedCopy copy = Copy.of(
        tester.element(find.byType(RecycleBinScreen)),
      );
      expect(find.text(copy.recycleEmptyRecords(1)), findsOneWidget);
      expect(copy.recycleEmptyRecords(1), isNot(Copy.recycleEmptyRecords(1)));
      await reachPhotoRestore(tester);
      expect(tester.takeException(), isNull);
    },
  );

  Finder emptyButton() =>
      find.byKey(const ValueKey<String>('recycle-bin-empty'));

  Finder inDialog(String text) {
    return find.descendant(
      of: find.byType(AppDialog),
      matching: find.text(text),
    );
  }

  group('its states', () {
    testWidgets('shows a skeleton while the bin loads', (
      WidgetTester tester,
    ) async {
      await pump(tester, repository: _SilentBin(), settle: false);
      await tester.pump();

      expect(find.byType(AppSkeleton), findsOneWidget);
      expect(emptyButton(), findsNothing);
    });

    testWidgets('an empty bin says what it is for and offers no emptying', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text(Copy.recycleBinEmptyHeadline), findsOneWidget);
      expect(
        find.text(Copy.recycleBinEmptyMessage(AppConstants.retention.days)),
        findsOneWidget,
      );
      expect(emptyButton(), findsNothing);
    });

    testWidgets('a bin that cannot be read says why and reads again on retry', (
      WidgetTester tester,
    ) async {
      final String id = binned('record-1');
      records.readFailure = _unreadable;
      await pump(tester);

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text(_unreadable.message), findsOneWidget);
      expect(emptyButton(), findsNothing);

      records.readFailure = null;
      await tester.tap(find.text(Copy.tryAgain));
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsNothing);
      expect(rowOf(id), findsOneWidget);
    });
  });

  group('each row', () {
    testWidgets('names the record, its project and when it was deleted', (
      WidgetTester tester,
    ) async {
      records.seedProjectName('project-1', 'North wing');
      final String named = binned('record-1', name: 'Autoclave', number: 12);
      final String untitled = binned(
        'record-2',
        number: 7,
        fields: const <String, String>{},
      );
      await pump(tester);

      final DateTime deletedAt = _now.subtract(const Duration(days: 1));
      expect(
        find.descendant(of: rowOf(named), matching: find.text('Autoclave')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: rowOf(named),
          matching: find.text(
            Copy.recycleEntitySubtitle(
              Copy.recycleTypeRecord,
              Copy.recycleBinRowSubtitle(
                number: 12,
                projectName: 'North wing',
                deletedAt: deletedAt,
              ),
            ),
          ),
        ),
        findsOneWidget,
      );
      // A record with no name is titled by its number, which the second
      // line then leaves out.
      expect(
        find.descendant(
          of: rowOf(untitled),
          matching: find.text(Copy.recordsUntitled(7)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: rowOf(untitled),
          matching: find.text(
            Copy.recycleEntitySubtitle(
              Copy.recycleTypeRecord,
              Copy.recycleBinRowSubtitle(
                projectName: 'North wing',
                deletedAt: deletedAt,
              ),
            ),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the first photo as its cached thumbnail', (
      WidgetTester tester,
    ) async {
      final String id = binned('record-1', photos: 2);
      await pump(tester);

      final RecordThumb thumb = tester.widget<RecordThumb>(
        find.descendant(of: rowOf(id), matching: find.byType(RecordThumb)),
      );
      expect(thumb.sha256, '$id-sha-0');
      expect(thumb.storagePath, 'photos/$id/img-0.jpg');
      expect(
        find.descendant(of: rowOf(id), matching: find.byType(AppPhotoThumb)),
        findsOneWidget,
      );
    });

    testWidgets('counts down the default 30 days from the deletion', (
      WidgetTester tester,
    ) async {
      final String today = binned('today', daysAgo: 0);
      final String recent = binned('recent', daysAgo: 2);
      final String older = binned('older', daysAgo: 10);
      await pump(tester, retentionDays: 30);

      expect(find.text(Copy.recycleBinKeptFor(30)), findsOneWidget);
      expect(
        find.descendant(
          of: rowOf(today),
          matching: find.text(Copy.recycleBinDaysLeft(30)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: rowOf(recent),
          matching: find.text(Copy.recycleBinDaysLeft(28)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: rowOf(older),
          matching: find.text(Copy.recycleBinDaysLeft(20)),
        ),
        findsOneWidget,
      );
      expect(Copy.recycleBinDaysLeft(28), 'Deletes in 28 days');
    });

    testWidgets('counts down a stored 7 days, down to today once run out', (
      WidgetTester tester,
    ) async {
      final String recent = binned('recent', daysAgo: 2);
      final String last = binned('last', daysAgo: 6);
      final String expired = binned('expired', daysAgo: 10);
      await pump(tester, retentionDays: 7);

      expect(find.text(Copy.recycleBinKeptFor(7)), findsOneWidget);
      expect(
        find.descendant(
          of: rowOf(recent),
          matching: find.text(Copy.recycleBinDaysLeft(5)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: rowOf(last),
          matching: find.text(Copy.recycleBinDaysLeft(1)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: rowOf(expired),
          matching: find.text(Copy.recycleBinDaysLeft(0)),
        ),
        findsOneWidget,
      );
      expect(Copy.recycleBinDaysLeft(1), 'Deletes in 1 day');
      expect(Copy.recycleBinDaysLeft(0), 'Deletes today');
    });
  });

  group('restore', () {
    testWidgets(
      'one press returns the record to its previous status and out of the bin',
      (WidgetTester tester) async {
        final String id = binned('record-1', previous: RecordStatus.approved);
        final String other = binned('record-2');
        await pump(tester);

        await tester.tap(
          find.byKey(ValueKey<String>('recycle-bin-restore-$id')),
        );
        await tester.pumpAndSettle();

        expect(records.entryOf(id)!.status, RecordStatus.approved);
        expect(records.isTombstoned(id), isFalse);
        expect(rowOf(id), findsNothing);
        expect(rowOf(other), findsOneWidget);
        expect(find.text(Copy.recordsRestored(1)), findsOneWidget);
        expect(find.byType(AppDialog), findsNothing);
      },
    );

    testWidgets('restoring the last record leaves the empty bin', (
      WidgetTester tester,
    ) async {
      final String id = binned('record-1');
      await pump(tester);

      await tester.tap(find.byKey(ValueKey<String>('recycle-bin-restore-$id')));
      await tester.pumpAndSettle();

      expect(find.text(Copy.recycleBinEmptyHeadline), findsOneWidget);
      expect(emptyButton(), findsNothing);
      expect(records.entryOf(id)!.status, RecordStatus.needsReview);
    });

    testWidgets('a failed restore says why and keeps the record in the bin', (
      WidgetTester tester,
    ) async {
      final String id = binned('record-1');
      records.failuresById[id] = _locked;
      await pump(tester);

      await tester.tap(find.byKey(ValueKey<String>('recycle-bin-restore-$id')));
      await tester.pumpAndSettle();

      expect(find.text(_locked.message), findsOneWidget);
      expect(rowOf(id), findsOneWidget);
      expect(records.entryOf(id)!.status, RecordStatus.deleted);
      expect(records.isTombstoned(id), isTrue);
    });
  });

  group('empty now', () {
    testWidgets('names the count and cannot be confirmed until it is typed', (
      WidgetTester tester,
    ) async {
      binned('record-1');
      binned('record-2');
      binned('record-3');
      final FakePurgeStore store = FakePurgeStore(<PurgeCandidate>[
        candidate('record-1'),
        candidate('record-2'),
        candidate('record-3'),
      ]);
      await pump(tester, job: jobOver(store));

      await tester.tap(emptyButton());
      await tester.pumpAndSettle();

      expect(inDialog(Copy.recycleBinEmptyTitle(3)), findsOneWidget);
      expect(inDialog(Copy.recycleBinEmptyWarning(3)), findsOneWidget);
      expect(
        inDialog(Copy.fieldLabelRequired(Copy.recycleBinEmptyTypeCount(3))),
        findsOneWidget,
      );
      expect(Copy.recycleBinEmptyTitle(3), contains('3'));
      final Finder confirm = inDialog(Copy.recycleBinEmptyConfirm);
      expect(
        tester
            .widget<AppButton>(
              find
                  .ancestor(of: confirm, matching: find.byType(AppButton))
                  .first,
            )
            .onPressed,
        isNull,
      );

      await tester.enterText(
        find.descendant(
          of: find.byType(AppDialog),
          matching: find.byType(TextField),
        ),
        '2',
      );
      await tester.pump();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(store.attempted, isEmpty);
      expect(find.byType(AppDialog), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byType(AppDialog),
          matching: find.byType(TextField),
        ),
        '3',
      );
      await tester.pump();
      expect(
        tester
            .widget<AppButton>(
              find
                  .ancestor(of: confirm, matching: find.byType(AppButton))
                  .first,
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets(
      'runs the purge, window ignored, and reports what went and what a merge kept',
      (WidgetTester tester) async {
        binned('record-1');
        binned('record-2');
        binned('record-3');
        final FakePurgeStore store = FakePurgeStore(<PurgeCandidate>[
          candidate('record-1'),
          candidate('record-2'),
          candidate('record-3', mergeNeeded: true),
        ]);
        await pump(tester, job: jobOver(store));

        await tester.tap(emptyButton());
        await tester.pumpAndSettle();
        await tester.enterText(
          find.descendant(
            of: find.byType(AppDialog),
            matching: find.byType(TextField),
          ),
          '3',
        );
        await tester.pump();
        await tester.tap(inDialog(Copy.recycleBinEmptyConfirm));
        await tester.pumpAndSettle();

        // Deleted a day ago, well inside the 30-day window, and still purged.
        expect(store.purged, <String>['record-1', 'record-2']);
        expect(store.remaining.single.recordId, 'record-3');
        expect(
          find.text(Copy.recycleBinEmptied(purged: 2, kept: 1, failed: 0)),
          findsOneWidget,
        );
        expect(
          Copy.recycleBinEmptied(purged: 2, kept: 1, failed: 0),
          '2 records removed for good. 1 kept because a merge still needs it',
        );
      },
    );

    testWidgets('reports a record that could not be removed', (
      WidgetTester tester,
    ) async {
      binned('record-1');
      binned('record-2');
      final FakePurgeStore store = FakePurgeStore(<PurgeCandidate>[
        candidate('record-1'),
        candidate('record-2'),
      ])..failuresById['record-2'] = _locked;
      await pump(tester, job: jobOver(store));

      await tester.tap(emptyButton());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AppDialog),
          matching: find.byType(TextField),
        ),
        '2',
      );
      await tester.pump();
      await tester.tap(inDialog(Copy.recycleBinEmptyConfirm));
      await tester.pumpAndSettle();

      expect(store.purged, <String>['record-1']);
      expect(
        find.text(Copy.recycleBinEmptied(purged: 1, kept: 0, failed: 1)),
        findsOneWidget,
      );
    });

    testWidgets('a purge that cannot list the bin says why', (
      WidgetTester tester,
    ) async {
      binned('record-1');
      final FakePurgeStore store = FakePurgeStore()..listFailure = _unreadable;
      await pump(tester, job: jobOver(store));

      await tester.tap(emptyButton());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AppDialog),
          matching: find.byType(TextField),
        ),
        '1',
      );
      await tester.pump();
      await tester.tap(inDialog(Copy.recycleBinEmptyConfirm));
      await tester.pumpAndSettle();

      expect(find.text(_unreadable.message), findsOneWidget);
    });

    testWidgets('cancel removes nothing', (WidgetTester tester) async {
      binned('record-1');
      final FakePurgeStore store = FakePurgeStore(<PurgeCandidate>[
        candidate('record-1'),
      ]);
      await pump(tester, job: jobOver(store));

      await tester.tap(emptyButton());
      await tester.pumpAndSettle();
      await tester.tap(inDialog(Copy.cancel));
      await tester.pumpAndSettle();

      expect(find.byType(AppDialog), findsNothing);
      expect(store.attempted, isEmpty);
    });

    testWidgets('is off, and says why, where no purge runs', (
      WidgetTester tester,
    ) async {
      binned('record-1');
      await pump(tester);

      expect(emptyButton(), findsOneWidget);
      expect(tester.widget<AppButton>(emptyButton()).onPressed, isNull);
      expect(
        find.byKey(const ValueKey<String>('recycle-bin-empty-unavailable')),
        findsOneWidget,
      );
      expect(find.text(Copy.recycleBinEmptyUnavailable), findsOneWidget);

      await tester.tap(emptyButton(), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(AppDialog), findsNothing);
    });

    testWidgets('holds every control while the bin is being emptied', (
      WidgetTester tester,
    ) async {
      final String id = binned('record-1');
      final _HeldPurgeStore store = _HeldPurgeStore();
      await pump(tester, job: jobOver(store));

      await tester.tap(emptyButton());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AppDialog),
          matching: find.byType(TextField),
        ),
        '1',
      );
      await tester.pump();
      await tester.tap(inDialog(Copy.recycleBinEmptyConfirm));
      await tester.pump();
      await tester.pump();

      expect(tester.widget<AppButton>(emptyButton()).busy, isTrue);
      expect(tester.widget<AppButton>(emptyButton()).onPressed, isNull);
      expect(
        tester
            .widget<AppIconButton>(
              find.byKey(ValueKey<String>('recycle-bin-restore-$id')),
            )
            .onPressed,
        isNull,
      );

      store.release.complete(
        const Success<List<PurgeCandidate>>(<PurgeCandidate>[]),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<AppButton>(emptyButton()).busy, isFalse);
      expect(
        find.text(Copy.recycleBinEmptied(purged: 0, kept: 0, failed: 0)),
        findsOneWidget,
      );
    });
  });

  group('its layout', () {
    testWidgets('every restore control is a labelled 48dp target', (
      WidgetTester tester,
    ) async {
      final String id = binned('record-1', name: 'Autoclave');
      await pump(tester);
      final SemanticsHandle handle = tester.ensureSemantics();

      final Finder restore = find.byKey(
        ValueKey<String>('recycle-bin-restore-$id'),
      );
      expect(restore, meetsTapTarget());
      expect(
        restore,
        hasSemanticLabel(Copy.recycleBinRestoreLabel('Autoclave')),
      );
      expect(emptyButton(), meetsTapTarget());
      handle.dispose();
    });

    testWidgets(
      'meets the accessibility guidelines and reflows at 200 percent text',
      (WidgetTester tester) async {
        binned('record-1', name: 'Autoclave with a long descriptive name');
        binned('record-2', daysAgo: 12);
        records.seedProjectName('project-1', 'North wing main plant room');
        // Match the native logical viewport instead of Chrome's synthetic DPR 3.
        await pump(
          tester,
          cell: const ScreenMatrix(Size(800, 600), 1, Brightness.light, false),
        );

        if (kIsWeb) {
          await _expectBrowserAccessibility(tester);
        } else {
          await expectNoA11yIssues(tester);
        }
      },
    );

    for (final Size size in const <Size>[
      Size(360, 740),
      Size(840, 600),
      Size(1280, 800),
    ]) {
      testWidgets('lays out without overflow at ${size.width.toInt()} wide', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = size * tester.view.devicePixelRatio;
        addTearDown(tester.view.resetPhysicalSize);
        for (int n = 1; n <= 12; n++) {
          binned('record-$n', daysAgo: n, name: 'Record named $n');
        }
        await pump(tester);

        expect(tester.takeException(), isNull);
        expect(rowOf('record-1'), findsOneWidget);
        expect(emptyButton(), findsOneWidget);
      });
    }
  });
}

/// Keeps the same guideline and 200-percent checks with a live CanvasKit image.
Future<void> _expectBrowserAccessibility(WidgetTester tester) async {
  final SemanticsHandle semantics = tester.ensureSemantics();
  final Size originalSize = tester.view.physicalSize;
  final double originalScale = tester.platformDispatcher.textScaleFactor;
  final List<String> issues = <String>[];
  try {
    for (final AccessibilityGuideline guideline in <AccessibilityGuideline>[
      androidTapTargetGuideline,
      iOSTapTargetGuideline,
      labeledTapTargetGuideline,
      const BrowserTextContrastGuideline(),
    ]) {
      final Evaluation evaluation = await guideline.evaluate(tester);
      if (!evaluation.passed) {
        issues.add('${guideline.description}: ${evaluation.reason}');
      }
    }
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    for (final Size logical in <Size>[
      const Size(400, 800),
      const Size(800, 400),
    ]) {
      tester.view.physicalSize = logical * tester.view.devicePixelRatio;
      await tester.pump();
      final Object? exception = tester.takeException();
      if (exception != null) {
        issues.add('200 percent text at $logical: $exception');
      }
    }
    expect(issues, isEmpty, reason: issues.join('\n'));
  } finally {
    tester.platformDispatcher.textScaleFactorTestValue = originalScale;
    tester.view.physicalSize = originalSize;
    semantics.dispose();
    await tester.pump();
  }
}

/// A store whose recycle bin never answers, so the page stays loading.
final class _SilentBin implements RecordRepository {
  final StreamController<List<DeletedRecord>> _never =
      StreamController<List<DeletedRecord>>();

  @override
  Stream<List<DeletedRecord>> watchBin() => _never.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A purge store whose listing waits for the test to release it.
final class _HeldPurgeStore implements PurgeStore {
  final Completer<Result<List<PurgeCandidate>>> release =
      Completer<Result<List<PurgeCandidate>>>();

  @override
  Future<Result<List<PurgeCandidate>>> candidates() => release.future;

  @override
  Future<Result<int>> purge(PurgeCandidate candidate) async {
    return const Success<int>(0);
  }
}

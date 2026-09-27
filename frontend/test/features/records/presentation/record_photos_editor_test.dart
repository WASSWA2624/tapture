import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/router.dart' show AppRoutes;
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/capture/capture.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart'
    show CaptureController;
import 'package:tapture/features/processing/processing.dart'
    show processingRepositoryProvider;
import 'package:tapture/features/records/presentation/record_photos_editor.dart';
import 'package:tapture/features/templates/templates.dart' show TemplateDef;

import '../../../support/factories.dart';
import '../../../support/fakes/fake_photo_repository.dart';
import '../../../support/fakes/fake_processing_repository.dart';

const ValidationFailure _running = ValidationFailure(
  message: 'This record is being processed now.',
  recoveryAction: 'Wait for the run to finish, then try again.',
);

void main() {
  late FakeProcessingRepository processing;

  setUp(() {
    processing = FakeProcessingRepository();
  });

  tearDown(() {
    processing.dispose();
  });

  /// The record page opens the photo edit; the stand-in edit page pops the
  /// way the capture edit page does: with what a save did, or with nothing
  /// when the operator leaves.
  Future<GoRouter> pump(WidgetTester tester) async {
    final GoRouter router = GoRouter(
      initialLocation: AppRoutes.projectRecord('p1', 'r1'),
      routes: <RouteBase>[
        GoRoute(
          path: '/projects/:projectId/records/:recordId',
          builder: (BuildContext _, GoRouterState state) => Scaffold(
            body: Center(
              child: Consumer(
                builder: (BuildContext context, WidgetRef ref, Widget? _) {
                  return AppButton(
                    label: 'Edit photos',
                    onPressed: () => unawaited(
                      RecordPhotosEditor.open(
                        context,
                        ref,
                        projectId: state.pathParameters['projectId']!,
                        recordId: state.pathParameters['recordId']!,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          routes: <RouteBase>[
            GoRoute(
              path: 'edit',
              builder: (BuildContext _, GoRouterState _) => Scaffold(
                body: Builder(
                  builder: (BuildContext context) => Column(
                    children: <Widget>[
                      for (final int added in <int>[0, 2])
                        AppButton(
                          label: 'Save with $added',
                          onPressed: () => Navigator.of(
                            context,
                          ).pop<CaptureEditOutcome>((photosAdded: added)),
                        ),
                      AppButton(
                        label: 'Leave',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: (int _, Object _) => null,
        overrides: <Override>[
          processingRepositoryProvider.overrideWith((Ref _) => processing),
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

  Future<void> edit(WidgetTester tester, String action) async {
    await tester.tap(find.text('Edit photos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(action));
    await tester.pumpAndSettle();
  }

  Future<void> answer(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(of: find.byType(AppDialog), matching: find.text(label)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens the photo edit of the record', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pump(tester);

    await tester.tap(find.text('Edit photos'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.projectRecordEdit('p1', 'r1'));
  });

  testWidgets('a save that added photos offers to process the record again, '
      'naming how many, and accepting queues it', (WidgetTester tester) async {
    processing.recordStatuses['r1'] = RecordStatus.approved;
    final GoRouter router = await pump(tester);

    await edit(tester, 'Save with 2');

    expect(router.state.uri.path, AppRoutes.projectRecord('p1', 'r1'));
    expect(find.byType(AppDialog), findsOneWidget);
    expect(find.text(Copy.recordPhotosProcessTitle), findsOneWidget);
    expect(find.text(Copy.recordPhotosProcessMessage(2)), findsOneWidget);
    expect(processing.requeued, isEmpty);

    await answer(tester, Copy.recordPhotosProcessConfirm);

    expect(processing.requeued, <String>['r1']);
    expect(processing.recordStatuses['r1'], RecordStatus.queued);
    expect(find.text(Copy.recordPhotosProcessQueued), findsOneWidget);
  });

  testWidgets('declining the offer queues nothing', (
    WidgetTester tester,
  ) async {
    await pump(tester);

    await edit(tester, 'Save with 2');
    await answer(tester, Copy.cancel);

    expect(find.byType(AppDialog), findsNothing);
    expect(processing.requeued, isEmpty);
    expect(find.text(Copy.recordPhotosProcessQueued), findsNothing);
  });

  testWidgets('a save that added no photo offers nothing', (
    WidgetTester tester,
  ) async {
    await pump(tester);

    await edit(tester, 'Save with 0');

    expect(find.byType(AppDialog), findsNothing);
    expect(processing.requeued, isEmpty);
  });

  testWidgets('leaving the photo edit without saving offers nothing', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pump(tester);

    await edit(tester, 'Leave');

    expect(router.state.uri.path, AppRoutes.projectRecord('p1', 'r1'));
    expect(find.byType(AppDialog), findsNothing);
    expect(processing.requeued, isEmpty);
  });

  testWidgets('a record the queue refuses is reported with the reason and '
      'Retry, and a retry can succeed', (WidgetTester tester) async {
    processing.requeueFailures['r1'] = _running;
    await pump(tester);

    await edit(tester, 'Save with 2');
    await answer(tester, Copy.recordPhotosProcessConfirm);

    expect(processing.requeued, isEmpty);
    expect(find.text(_running.message), findsOneWidget);
    expect(find.text(Copy.recordPhotosProcessQueued), findsNothing);
    expect(find.text(Copy.queueRetry), findsOneWidget);

    processing.requeueFailures.clear();
    await tester.tap(find.text(Copy.queueRetry));
    await tester.pumpAndSettle();

    expect(processing.requeued, <String>['r1']);
    expect(find.text(Copy.recordPhotosProcessQueued), findsOneWidget);
  });

  testWidgets('a record that is processing now cannot be queued again, and '
      'the queue says why', (WidgetTester tester) async {
    processing.recordStatuses['r1'] = RecordStatus.processing;
    await pump(tester);

    await edit(tester, 'Save with 2');
    await answer(tester, Copy.recordPhotosProcessConfirm);

    expect(processing.requeued, isEmpty);
    expect(processing.recordStatuses['r1'], RecordStatus.processing);
    expect(find.text(Copy.recordPhotosProcessQueued), findsNothing);
    expect(find.text(Copy.queueRetry), findsOneWidget);
  });

  testWidgets('through the capture edit page, a save that files a new photo '
      'offers to process the record again', (WidgetTester tester) async {
    final FakePhotoRepository photos = FakePhotoRepository();
    addTearDown(photos.dispose);
    final _SavedRecord saved = _SavedRecord();
    final GoRouter router = GoRouter(
      initialLocation: AppRoutes.projectRecord('p1', 'r1'),
      routes: <RouteBase>[
        GoRoute(
          path: '/projects/:projectId/records/:recordId',
          builder: (BuildContext _, GoRouterState _) => Scaffold(
            body: Center(
              child: Consumer(
                builder: (BuildContext context, WidgetRef ref, Widget? _) {
                  return AppButton(
                    label: 'Edit photos',
                    onPressed: () => unawaited(
                      RecordPhotosEditor.open(
                        context,
                        ref,
                        projectId: 'p1',
                        recordId: 'r1',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          routes: <RouteBase>[
            GoRoute(
              path: 'edit',
              builder: (BuildContext _, GoRouterState state) => CaptureScreen(
                projectId: state.pathParameters['projectId']!,
                recordId: state.pathParameters['recordId']!,
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: (int _, Object _) => null,
        overrides: <Override>[
          processingRepositoryProvider.overrideWith((Ref _) => processing),
          photoRepositoryProvider.overrideWith((Ref _) => photos),
          capturePersistenceProvider.overrideWith(
            (Ref _) => CapturePersistenceImpl(
              photos: photos,
              store: TextStore.memory(),
            ),
          ),
          captureRecordWriterProvider.overrideWith((Ref _) => saved),
          captureProjectTemplatesProvider.overrideWith(
            (Ref _, String _) =>
                Stream<List<TemplateDef>>.value(<TemplateDef>[aTemplate()]),
          ),
        ],
        child: MaterialApp.router(
          theme: buildTheme(brightness: Brightness.light),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit photos'));
    await tester.pumpAndSettle();
    expect(find.byType(CaptureScreen), findsOneWidget);

    final CaptureController controller = ProviderScope.containerOf(
      tester.element(find.byType(CaptureScreen)),
    ).read(captureControllerProvider(CaptureSessionKey.edit('r1')).notifier);
    await controller.addPhoto(
      const PhotoDraft(
        id: 'new',
        projectId: 'p1',
        relativePath: 'photos/new.jpg',
        sha256: 'new-sha',
        sortOrder: 1,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.recordEditSave));
    await tester.pumpAndSettle();

    expect(saved.updates, hasLength(1));
    expect(find.byType(CaptureScreen), findsNothing);
    expect(find.text(Copy.recordPhotosProcessMessage(1)), findsOneWidget);

    await answer(tester, Copy.recordPhotosProcessConfirm);

    expect(processing.requeued, <String>['r1']);
  });
}

/// Saved record `r1` with one filed photo, as the capture writer loads it.
final class _SavedRecord implements CaptureRecordPersistence {
  final List<CaptureSession> updates = <CaptureSession>[];

  @override
  Future<Result<String>> persist(CaptureSession session) async {
    return Success<String>(session.id);
  }

  @override
  Future<Result<CaptureSession>> load(String recordId) async {
    return Success<CaptureSession>(
      CaptureSession(
        id: recordId,
        projectId: 'p1',
        templateId: 'template-1',
        contextSnapshot: const <String, String>{},
        recordId: recordId,
        editing: true,
        photos: <PhotoDraft>[
          PhotoDraft(
            id: 'filed',
            projectId: 'p1',
            recordId: recordId,
            relativePath: 'photos/filed.jpg',
            sha256: 'filed-sha',
          ),
        ],
      ),
    );
  }

  @override
  Future<Result<void>> update(CaptureSession edited) async {
    updates.add(edited);
    return const Success<void>(null);
  }
}

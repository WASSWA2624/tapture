import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/features/capture/data/capture_persistence_impl.dart';
import 'package:tapture/features/capture/domain/capture_persistence.dart';
import 'package:tapture/features/capture/domain/capture_record_persistence.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/capture_session_key.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/capture/presentation/capture_recovery_prompt.dart';
import 'package:tapture/features/capture/presentation/capture_screen.dart';
import 'package:tapture/features/capture/presentation/capture_target_fields.dart';
import 'package:tapture/features/templates/domain/template_def.dart';

import '../../../support/factories.dart';
import '../../../support/fakes/fake_photo_repository.dart';

void main() {
  testWidgets('Edit opens the record with its photos and captions', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _open(tester);

    expect(find.byType(CaptureScreen), findsOneWidget);
    expect(_thumb('f1'), findsOneWidget);
    expect(_thumb('f2'), findsOneWidget);
    expect(find.text(Copy.recordEditSave), findsOneWidget);
    expect(find.text(Copy.captureSaveRaw), findsNothing);
    expect(find.byType(CaptureTargetFields), findsNothing);
    expect(find.text(Copy.captionAddToAll(2)), findsOneWidget);
    expect(harness.session(tester).captions['f1'], 'Valve');
    expect(harness.session(tester).recordCaption, 'Boiler');
    // The field holds the record's own caption, not a photo's.
    expect(_captionText(tester), 'Boiler');
  });

  testWidgets('typing on the edit page changes no photo caption, and Add '
      'appends it to the photos', (WidgetTester tester) async {
    final _Harness harness = await _open(tester);
    await tester.enterText(_captionField, 'Pump room');
    await tester.pumpAndSettle();
    expect(harness.session(tester).captions['f1'], 'Valve');
    expect(harness.session(tester).captions['f2'] ?? '', isEmpty);
    expect(harness.session(tester).recordCaption, 'Pump room');

    await tester.tap(find.byKey(const ValueKey<String>('capture-caption-add')));
    await tester.pumpAndSettle();

    expect(harness.session(tester).captions['f1'], 'Valve\nPump room');
    expect(harness.session(tester).captions['f2'], 'Pump room');
    expect(harness.session(tester).recordCaption, '');
    expect(_captionText(tester), '');
    expect(find.text(Copy.captionAdded(2)), findsOneWidget);
  });

  testWidgets('Save changes writes the record and returns to its page', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _open(tester);
    await _remove(tester, 'f1');
    expect(_thumb('f1'), findsNothing);

    await tester.tap(find.text(Copy.recordEditSave));
    await tester.pumpAndSettle();

    expect(harness.records.updates, hasLength(1));
    expect(
      harness.records.updates.single.photos.map((PhotoDraft p) => p.id),
      <String>['f2'],
    );
    expect(harness.router.state.uri.path, RoutePaths.projectRecord('p1', 'r1'));
    expect(find.text('record page'), findsOneWidget);
    expect(find.text(Copy.recordEditSaved), findsOneWidget);
    expect(_ok(await harness.sessions.loadSession(_key)), isNull);
  });

  testWidgets('an unsaved new capture of the project survives an edit', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _open(
      tester,
      before: (CapturePersistence sessions) async {
        _ok(
          await sessions.saveSession(
            const CaptureSession(
              id: 'fresh',
              projectId: 'p1',
              templateId: 't1',
              contextSnapshot: <String, String>{},
              captions: <String, String>{'': 'New capture'},
              isDirty: true,
            ),
          ),
        );
      },
    );
    await _remove(tester, 'f2');
    await tester.tap(find.text(Copy.recordEditSave));
    await tester.pumpAndSettle();

    final CaptureSession? fresh = _ok(await harness.sessions.loadSession('p1'));
    expect(fresh?.recordCaption, 'New capture');
    expect(fresh?.editing, isFalse);
  });

  testWidgets('leaving without saving changes nothing and offers the edit '
      'back', (WidgetTester tester) async {
    final _Harness harness = await _open(tester);
    await _remove(tester, 'f1');

    harness.router.pop();
    await tester.pumpAndSettle();
    expect(find.text('record page'), findsOneWidget);
    expect(harness.records.updates, isEmpty);

    unawaited(harness.router.push(RoutePaths.projectRecordEdit('p1', 'r1')));
    await tester.pumpAndSettle();
    expect(find.byType(CaptureRecoveryPrompt), findsOneWidget);
  });

  testWidgets('a failing save keeps every change and offers Retry', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _open(tester, failUpdate: true);
    await _remove(tester, 'f1');

    await tester.tap(find.text(Copy.recordEditSave));
    await tester.pumpAndSettle();

    expect(find.byType(CaptureScreen), findsOneWidget);
    expect(find.text(Copy.queueRetry), findsOneWidget);
    expect(_thumb('f1'), findsNothing);
    expect(_thumb('f2'), findsOneWidget);
    expect(harness.session(tester).isDirty, isTrue);
  });

  for (final ({String name, Size size, double scale}) layout
      in <({String name, Size size, double scale})>[
        (name: '393 dp', size: const Size(393, 886), scale: 1),
        (name: '800 dp', size: const Size(800, 1000), scale: 1),
        (name: '1200 dp', size: const Size(1200, 800), scale: 1),
        (name: 'landscape', size: const Size(886, 393), scale: 1),
        (name: '200 percent text', size: const Size(393, 886), scale: 2),
      ]) {
    testWidgets('at ${layout.name} the edit page lays out with Save changes', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = layout.size;
      tester.platformDispatcher.textScaleFactorTestValue = layout.scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _open(tester);

      expect(tester.takeException(), isNull);
      final Rect save = tester.getRect(find.text(Copy.recordEditSave));
      expect(save.bottom, lessThanOrEqualTo(layout.size.height));
      expect(_thumb('f1'), findsOneWidget);
    });
  }
}

final String _key = CaptureSessionKey.edit('r1');

final Finder _captionField = find.byWidgetPredicate(
  (Widget widget) =>
      widget is TextField &&
      widget.decoration?.labelText == Copy.captureRecordCaption,
);

String _captionText(WidgetTester tester) {
  return tester.widget<TextField>(_captionField).controller?.text ?? '';
}

Finder _thumb(String id) => find.byKey(ValueKey<String>('photo-thumb-$id'));

Future<void> _remove(WidgetTester tester, String id) async {
  await tester.tap(
    find.descendant(
      of: _thumb(id),
      matching: find.byKey(
        const ValueKey<String>('photo-corner-remove-target'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

typedef _Harness = ({
  GoRouter router,
  _Records records,
  CapturePersistence sessions,
  CaptureSession Function(WidgetTester tester) session,
});

Future<_Harness> _open(
  WidgetTester tester, {
  bool failUpdate = false,
  Future<void> Function(CapturePersistence sessions)? before,
}) async {
  final FakePhotoRepository photos = FakePhotoRepository();
  addTearDown(photos.dispose);
  final CapturePersistence sessions = CapturePersistenceImpl(
    photos: photos,
    store: TextStore.memory(),
  );
  await before?.call(sessions);
  final _Records records = _Records()..failUpdate = failUpdate;
  final GoRouter router = GoRouter(
    initialLocation: RoutePaths.projectRecord('p1', 'r1'),
    routes: <RouteBase>[
      GoRoute(
        path: '/projects/:projectId/records/:recordId',
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Text('record page')),
        routes: <RouteBase>[
          GoRoute(
            path: 'edit',
            builder: (BuildContext _, GoRouterState state) {
              return CaptureScreen(
                projectId: state.pathParameters['projectId']!,
                recordId: state.pathParameters['recordId']!,
              );
            },
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        photoRepositoryProvider.overrideWith((Ref _) => photos),
        capturePersistenceProvider.overrideWith((Ref _) => sessions),
        captureRecordWriterProvider.overrideWith((Ref _) => records),
        captureProjectTemplatesProvider.overrideWith(
          (Ref ref, String id) =>
              Stream<List<TemplateDef>>.value(<TemplateDef>[aTemplate()]),
        ),
      ],
      child: MaterialApp.router(
        theme: buildTheme(brightness: Brightness.light),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  unawaited(router.push(RoutePaths.projectRecordEdit('p1', 'r1')));
  await tester.pumpAndSettle();
  return (
    router: router,
    records: records,
    sessions: sessions,
    session: (WidgetTester tester) => ProviderScope.containerOf(
      tester.element(find.byType(CaptureScreen)),
    ).read(captureControllerProvider(_key)),
  );
}

/// A record store holding record `r1` with two filed photos.
final class _Records implements CaptureRecordPersistence {
  final List<CaptureSession> updates = <CaptureSession>[];
  bool failUpdate = false;

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
        templateId: 't1',
        contextSnapshot: const <String, String>{},
        recordId: recordId,
        editing: true,
        photos: <PhotoDraft>[
          for (final String id in <String>['f1', 'f2'])
            PhotoDraft(
              id: id,
              projectId: 'p1',
              recordId: recordId,
              relativePath: 'photos/$id.jpg',
              sha256: '$id-sha',
              sortOrder: id == 'f1' ? 0 : 1,
            ),
        ],
        captions: const <String, String>{'': 'Boiler', 'f1': 'Valve'},
      ),
    );
  }

  @override
  Future<Result<void>> update(CaptureSession edited) async {
    if (failUpdate) {
      return const FailureResult<void>(
        StorageFailure(message: 'The database could not complete that write.'),
      );
    }
    updates.add(edited);
    return const Success<void>(null);
  }
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

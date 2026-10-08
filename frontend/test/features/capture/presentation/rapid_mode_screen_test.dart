import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/files/text_store.dart';
import 'package:tapture/core/network/offline_now.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/features/capture/data/capture_persistence_impl.dart';
import 'package:tapture/features/capture/domain/capture_persistence.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';
import 'package:tapture/features/capture/presentation/capture_screen.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../../support/fakes/fake_capture_photo_repository.dart';
import '../../projects/fakes/fake_project_repository.dart';

void main() {
  for (final bool legacy in <bool>[false, true]) {
    testWidgets(
      '${legacy ? 'legacy rapid' : 'ordinary capture'} opens the same durable '
      'draft through the production router',
      (WidgetTester tester) async {
        final Directory thumbs = Directory.systemTemp.createTempSync(
          'tapture-legacy-capture-',
        );
        addTearDown(() => thumbs.deleteSync(recursive: true));
        final FakeCapturePhotoRepository photos = FakeCapturePhotoRepository(
          thumbs: thumbs,
        );
        final CapturePersistence persistence = CapturePersistenceImpl(
          photos: photos,
          store: TextStore.memory(),
        );
        final FakeProjectRepository projects = FakeProjectRepository();
        addTearDown(projects.dispose);
        (await projects.create(aProject(id: 'p1'))).getOrThrow();
        const CaptureSession interrupted = CaptureSession(
          id: 'interrupted',
          projectId: 'p1',
          templateId: 't1',
          templateVersion: 1,
          contextSnapshot: <String, String>{},
          photos: <PhotoDraft>[
            PhotoDraft(
              id: 'photo-1',
              projectId: 'p1',
              relativePath: 'photos/_unfiled/photo-1.jpg',
              sha256: 'original-hash',
            ),
          ],
          captions: <String, String>{'': 'Original caption'},
          values: <String, Object?>{'serial': 'SN-7'},
          isDirty: true,
        );
        (await persistence.savePhoto(
          interrupted.photos.single,
          bytes: Uint8List.fromList(<int>[1, 2]),
        )).getOrThrow();
        (await persistence.saveSession(interrupted)).getOrThrow();
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              networkOnlineOverride(),
              offlineNowProvider.overrideWithValue(true),
              projectRepositoryProvider.overrideWithValue(projects),
              currentProjectDetailsProvider.overrideWith(
                (Ref _) => aProject(id: 'p1'),
              ),
              captureProjectTemplatesProvider.overrideWith(
                (Ref _, String _) => Stream<List<TemplateDef>>.value(
                  <TemplateDef>[aTemplate(id: 't1', projectId: 'p1')],
                ),
              ),
              photoRepositoryProvider.overrideWithValue(photos),
              capturePersistenceProvider.overrideWithValue(persistence),
            ],
            child: const TaptureApp(),
          ),
        );
        await tester.pumpAndSettle();
        final ProviderContainer container = ProviderScope.containerOf(
          tester.element(find.byType(TaptureApp)),
        );
        container.read(currentProjectProvider.notifier).open('p1');
        final GoRouter router = container.read(routerProvider);
        final Uri location = Uri(
          path: legacy
              ? RoutePaths.projectCaptureRapid('p1')
              : RoutePaths.projectCapture('p1'),
          query: 'template=t1&reference=kept',
          fragment: 'draft',
        );
        router.go(location.toString());
        await tester.pumpAndSettle();
        expect(router.state.uri.path, RoutePaths.projectCapture('p1'));
        expect(router.state.uri.query, location.query);
        expect(router.state.uri.fragment, location.fragment);
        expect(find.byType(CaptureScreen), findsOneWidget);
        expect(find.text(Copy.captureRecoveryTitle), findsOneWidget);
        final CaptureSession before = (await persistence.loadSession(
          'p1',
        )).getOrThrow()!;
        expect(before.id, interrupted.id);
        expect(before.values, interrupted.values);
        await tester.tap(find.text(Copy.captureResume));
        await tester.pumpAndSettle();
        final CaptureSession restored = container.read(
          captureControllerProvider('p1'),
        );
        expect(restored.id, interrupted.id);
        expect(restored.photos.single.sha256, 'original-hash');
        expect(restored.recordCaption, 'Original caption');
        expect(restored.values['serial'], 'SN-7');
        final AppPage page = tester.widget<AppPage>(
          find.descendant(
            of: find.byType(CaptureScreen),
            matching: find.byType(AppPage),
          ),
        );
        expect(
          page.overflow.any(
            (AppOverflowAction action) => action.label == Copy.captureRapidMode,
          ),
          isFalse,
        );
        expect(find.byKey(const ValueKey<String>('rapid-next')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

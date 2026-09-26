import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/files/photo_thumbnails.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_photo_thumb.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/features/projects/domain/project_repository.dart';
import 'package:tapture/features/projects/presentation/record_detail_screen.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../templates/fakes/fake_template_repository.dart';
import '../fakes/fake_project_repository.dart';

void main() {
  late Directory dir;
  late String thumbPath;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('tapture-record-page-');
    thumbPath = '${dir.path}/thumb.png';
    File(thumbPath).writeAsBytesSync(_onePixelPng);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  for (final ({String name, Size size, double scale}) layout
      in <({String name, Size size, double scale})>[
        (name: '393 dp', size: const Size(393, 886), scale: 1),
        (name: '800 dp', size: const Size(800, 1000), scale: 1),
        (name: '1200 dp', size: const Size(1200, 800), scale: 1),
        (name: 'landscape', size: const Size(886, 393), scale: 1),
        (name: '200 percent text', size: const Size(393, 886), scale: 2),
      ]) {
    testWidgets('at ${layout.name} the page shows the whole record', (
      WidgetTester tester,
    ) async {
      _surface(tester, layout.size, layout.scale);
      await _pump(tester, thumbPath: thumbPath);

      expect(tester.takeException(), isNull);
      expect(find.byType(RecordDetailScreen), findsOneWidget);
      expect(find.byType(AppPhotoThumb), findsNWidgets(2));
      expect(find.text('Boiler room'), findsOneWidget);
      expect(find.text('Asset tag'), findsOneWidget);
      // The title is the record's first value, and the field shows it too.
      expect(find.text('A-17'), findsNWidgets(2));
      expect(find.text('Condition note'), findsOneWidget);
      expect(find.text(Copy.recordFieldEmpty), findsOneWidget);
      expect(find.text(Copy.captureAudioCount(1)), findsOneWidget);
      expect(find.textContaining('Captured'), findsOneWidget);
    });
  }

  testWidgets('Edit fields opens the field editor', (
    WidgetTester tester,
  ) async {
    await _pump(tester, thumbPath: thumbPath);
    await tester.tap(find.byType(AppOverflowMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.recordEditFields));
    await tester.pumpAndSettle();
    expect(find.byType(AppBottomSheet), findsOneWidget);
    expect(find.text(Copy.recordEdit), findsWidgets);
  });

  testWidgets('Delete asks, archives the record and returns to the list', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester, thumbPath: thumbPath);
    await tester.tap(find.byType(AppOverflowMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.recordDelete));
    await tester.pumpAndSettle();
    expect(find.text(Copy.recordArchiveMessage), findsOneWidget);
    await tester.tap(find.text(Copy.recordDelete).last);
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.path, AppRoutes.project('project-1'));
    final List<ProjectRecordRow>? archived = await tester.runAsync(
      () => harness.projects
          .watchRecords('project-1', statuses: const <String>['archived'])
          .first,
    );
    expect(archived?.single.id, 'r1');
  });

  testWidgets('Edit opens the record on the capture page', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester, thumbPath: thumbPath);
    await tester.tap(find.byKey(const ValueKey<String>('record-edit')));
    await tester.pumpAndSettle();
    expect(
      harness.router.state.uri.path,
      AppRoutes.projectRecordEdit('project-1', 'r1'),
    );
    expect(find.text('edit page'), findsOneWidget);
  });

  testWidgets('a record that is gone says so', (WidgetTester tester) async {
    await _pump(tester, thumbPath: thumbPath, recordId: 'missing');
    expect(find.text(Copy.recordGoneHeadline), findsOneWidget);
  });
}

typedef _Harness = ({GoRouter router, FakeProjectRepository projects});

Future<_Harness> _pump(
  WidgetTester tester, {
  required String thumbPath,
  String recordId = 'r1',
}) async {
  final FakeProjectRepository projects = FakeProjectRepository();
  addTearDown(projects.dispose);
  final FakeTemplateRepository templates = FakeTemplateRepository();
  addTearDown(templates.dispose);
  await projects.create(aProject());
  await templates.save(
    aTemplate(
      fields: const <FieldDef>[
        FieldDef(
          fieldKey: 'asset_tag',
          label: 'Asset tag',
          type: FieldType.text,
        ),
        FieldDef(
          fieldKey: 'condition_note',
          label: 'Condition note',
          type: FieldType.longText,
          sortOrder: 1,
        ),
      ],
    ),
  );
  const RecordPhotoRef first = (
    sha256: 'sha-a',
    storagePath: 'projects/test-project/photos/a.jpg',
    quarterTurns: 0,
  );
  projects.seedDetail('project-1', (
    row: (
      id: 'r1',
      templateId: 'template-1',
      status: 'captured',
      photoCount: 2,
      thumb: first,
      fields: const <ProjectRecordFieldValue>[
        (fieldKey: 'asset_tag', raw: 'A-17', refined: '', approved: ''),
      ],
    ),
    caption: 'Boiler room',
    photos: const <RecordPhotoCaption>[
      (photo: first, caption: 'Front'),
      (
        photo: (
          sha256: 'sha-b',
          storagePath: 'projects/test-project/photos/b.jpg',
          quarterTurns: 1,
        ),
        caption: '',
      ),
    ],
    audioClips: 1,
    capturedAt: DateTime.utc(2026, 9, 25, 16),
  ));
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.project('project-1'),
    routes: <RouteBase>[
      GoRoute(
        path: '/projects/:projectId',
        builder: (BuildContext _, GoRouterState _) => const Text('home'),
        routes: <RouteBase>[
          GoRoute(
            path: 'records/:recordId',
            builder: (BuildContext _, GoRouterState state) {
              return RecordDetailScreen(
                projectId: state.pathParameters['projectId']!,
                recordId: state.pathParameters['recordId']!,
              );
            },
            routes: <RouteBase>[
              GoRoute(
                path: 'edit',
                builder: (BuildContext _, GoRouterState _) {
                  return const Text('edit page');
                },
              ),
            ],
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
        projectRepositoryProvider.overrideWith((Ref _) => projects),
        templateRepositoryProvider.overrideWith((Ref _) => templates),
        photoThumbnailsProvider.overrideWith(
          (Ref _) => PhotoThumbnails.fake(<String, String>{
            'projects/test-project/photos/a.jpg': thumbPath,
            'projects/test-project/photos/b.jpg': thumbPath,
          }),
        ),
      ],
      child: MaterialApp.router(
        theme: buildTheme(brightness: Brightness.light),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  unawaited(router.push(AppRoutes.projectRecord('project-1', recordId)));
  await tester.pumpAndSettle();
  return (router: router, projects: projects);
}

void _surface(WidgetTester tester, Size size, double scale) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// A valid 1×1 PNG, so a thumbnail decodes without an error placeholder.
final Uint8List _onePixelPng = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0xF8,
  0xCF,
  0xC0,
  0xF0,
  0x1F,
  0x00,
  0x05,
  0x00,
  0x01,
  0xFF,
  0x89,
  0x99,
  0x3D,
  0x1D,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/files/photo_thumbnails.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/features/processing/processing.dart'
    show processingRepositoryProvider;
import 'package:tapture/features/projects/projects.dart'
    show projectSettingsStoreProvider;
import 'package:tapture/features/records/domain/domain.dart';
import 'package:tapture/features/records/records.dart'
    show recordRepositoryProvider;
import 'package:tapture/features/review/review.dart';
import 'package:tapture/features/settings/settings.dart' show SettingsStore;
import 'package:tapture/features/templates/domain/field_def.dart';
import 'package:tapture/features/templates/templates.dart'
    show templateRepositoryProvider;

import '../../../support/factories.dart';
import '../../../support/fakes/fake_processing_repository.dart';
import '../../../support/fakes/fake_template_repository.dart';
import '../../records/fakes/fake_record_repository.dart';
import '../fakes/fake_review_repository.dart';

/// The project every review test works in.
const String reviewProject = 'project-1';

/// Stores and routes for the review screens, on fakes only.
final class ReviewHarness {
  /// Creates the fakes, torn down with the test.
  ReviewHarness() {
    addTearDown(records.dispose);
    addTearDown(templates.dispose);
    addTearDown(processing.dispose);
  }

  /// The record store.
  final FakeRecordRepository records = FakeRecordRepository();

  /// The template store.
  final FakeTemplateRepository templates = FakeTemplateRepository();

  /// The processing queue.
  final FakeProcessingRepository processing = FakeProcessingRepository();

  /// The settings store the remembered side lives in.
  final SettingsStore settings = SettingsStore.fake();

  /// The review store.
  late final FakeReviewRepository review = FakeReviewRepository(records);

  /// The template the records are captured with: Serial, Model, Note and
  /// Rating, in that order.
  Future<void> seedTemplate() async {
    await templates.save(
      aTemplate(
        fields: const <FieldDef>[
          FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
          FieldDef(
            fieldKey: 'model',
            label: 'Model',
            type: FieldType.text,
            sortOrder: 1,
          ),
          FieldDef(
            fieldKey: 'note',
            label: 'Note',
            type: FieldType.text,
            sortOrder: 2,
          ),
          FieldDef(
            fieldKey: 'rating',
            label: 'Rating',
            type: FieldType.text,
            sortOrder: 3,
          ),
          FieldDef(
            fieldKey: 'voltage',
            label: 'Voltage',
            type: FieldType.text,
            sortOrder: 4,
          ),
        ],
      ),
    );
  }

  /// A record waiting for review: a low-confidence Serial, a confident
  /// Model, no Note, and Rating and Voltage each with a captured and a
  /// different refined side. [photos] photos are filed on it.
  String seedRecord({
    String id = 'record-1',
    int photos = 0,
    DateTime? capturedAt,
    Set<RecordFlag> flags = const <RecordFlag>{},
  }) {
    final RecordEntry base = aRecordEntry(
      id: id,
      status: RecordStatus.needsReview,
      photos: photos,
      flags: flags,
      capturedAt: capturedAt,
      name: 'Pump $id',
    );
    return records.seedEntry(
      base.copyWith(
        values: const <RecordValue>[
          RecordValue(
            fieldKey: 'serial',
            raw: 'SN-1',
            source: 'ocr',
            confidence: 0.4,
            band: 'reviewRequired',
          ),
          RecordValue(
            fieldKey: 'model',
            raw: 'CR-10',
            source: 'extraction',
            confidence: 0.95,
            band: 'high',
          ),
          RecordValue(
            fieldKey: 'rating',
            raw: 'two forty volts',
            refined: '240 V',
            source: 'extraction',
            confidence: 0.6,
            band: 'medium',
          ),
          RecordValue(
            fieldKey: 'voltage',
            raw: 'four hundred',
            refined: '400',
            source: 'extraction',
            confidence: 0.6,
            band: 'medium',
          ),
        ],
      ),
    );
  }

  /// Every store the review screens read, overridden with the fakes.
  List<Override> get overrides => <Override>[
    recordRepositoryProvider.overrideWith((Ref _) => records),
    templateRepositoryProvider.overrideWith((Ref _) => templates),
    reviewRepositoryProvider.overrideWith((Ref _) => review),
    processingRepositoryProvider.overrideWith((Ref _) => processing),
    projectSettingsStoreProvider.overrideWith((Ref _) => settings),
    photoThumbnailsProvider.overrideWith(
      (Ref _) => PhotoThumbnails.fake(const <String, String>{}),
    ),
  ];

  /// Pumps the app on [location], with the review routes and the records
  /// list they leave for.
  Future<GoRouter> pump(WidgetTester tester, String location) async {
    final GoRouter router = GoRouter(
      initialLocation: location,
      routes: <RouteBase>[
        GoRoute(
          path: '/projects/:projectId/records',
          builder: (BuildContext _, GoRouterState _) =>
              const Text('records list'),
        ),
        GoRoute(
          path: '/projects/:projectId/review',
          builder: (BuildContext _, GoRouterState state) =>
              BatchReviewScreen(projectId: state.pathParameters['projectId']!),
        ),
        GoRoute(
          path: '/projects/:projectId/records/:recordId/review',
          builder: (BuildContext _, GoRouterState state) => ReviewScreen(
            projectId: state.pathParameters['projectId']!,
            recordId: state.pathParameters['recordId']!,
          ),
        ),
        GoRoute(
          path: '/projects/:projectId/records/:recordId/edit',
          builder: (BuildContext _, GoRouterState _) =>
              const Text('capture for the record'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: (int _, Object _) => null,
        overrides: overrides,
        child: MaterialApp.router(
          theme: buildTheme(brightness: Brightness.light),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  /// The review page of [recordId].
  static String recordReview(String recordId) =>
      RoutePaths.projectRecordReview(reviewProject, recordId);

  /// The batch review of the project.
  static String get batch => RoutePaths.projectBatchReview(reviewProject);
}

/// Sizes the test window to [size] at one pixel per point, reset after the
/// test.
void sizeWindow(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

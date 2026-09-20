import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/presentation/detection_profile_screen.dart';
import 'package:tapture/features/templates/presentation/template_list_screen.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../projects/fakes/fake_project_repository.dart';

void main() {
  test('a negative keyword excludes an otherwise matching profile', () {
    final TemplateDef template =
        aTemplate(
          fields: const <FieldDef>[
            FieldDef(
              fieldKey: 'serial',
              label: 'Serial',
              type: FieldType.text,
              validation: <String, Object?>{'pattern': r'^AST-\d{5}$'},
            ),
          ],
        ).copyWith(
          detection: const <String, Object?>{
            'keywords': <String>['serial', 'voltage'],
            'identifier_fields': <String>['serial'],
            'negative_keywords': <String>['floor plan'],
          },
        );

    expect(
      detectionProfileMatches(template, 'serial voltage on the rating plate'),
      isTrue,
    );
    expect(detectionProfileMatches(template, 'AST-12345'), isTrue);
    expect(
      detectionProfileMatches(template, 'serial number on a floor plan'),
      isFalse,
    );
  });

  test('an empty profile matches nothing and still works', () {
    expect(detectionProfileMatches(aTemplate(), 'serial voltage'), isFalse);
  });

  test('a shipped template arrives with defaults it can match on', () {
    final TemplateDef shipped = aTemplate(
      identityFieldKeys: const <String>['serial'],
      fields: const <FieldDef>[
        FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
      ],
    ).copyWith(source: 'shipped', kind: 'equipment');

    expect(detectionProfileMatches(shipped, 'this is equipment'), isTrue);
    expect(detectionProfileMatches(shipped, 'serial on the plate'), isTrue);
  });

  testWidgets('an empty template list renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      overrides: <Override>[
        templateListProvider.overrideWith(
          (Ref _) => Stream<List<TemplateDef>>.value(const <TemplateDef>[]),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.detectionProfileEmptyHeadline), findsOneWidget);
  });

  testWidgets('a failed load renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      overrides: <Override>[
        templateListProvider.overrideWith(
          (Ref _) => Stream<List<TemplateDef>>.error(
            const StorageFailure(
              message: 'The detection profile could not be read.',
              recoveryAction: 'Try again.',
            ),
          ),
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(
      find.text('The detection profile could not be read.'),
      findsOneWidget,
    );
  });
}

Future<void> _pump(
  WidgetTester tester, {
  List<Override> overrides = const <Override>[],
  String templateId = 'template-1',
}) async {
  final FakeProjectRepository projects = FakeProjectRepository();
  addTearDown(projects.dispose);
  _ok(await projects.create(aProject()));
  final SettingsStore store = SettingsStore.fake(
    stored: <String, Object?>{SettingKeys.openProjectId.name: 'project-1'},
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        projectRepositoryProvider.overrideWith((Ref _) => projects),
        projectSettingsStoreProvider.overrideWith((Ref _) => store),
        ...overrides,
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: DetectionProfileScreen(templateId: templateId),
      ),
    ),
  );
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

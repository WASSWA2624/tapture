import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/templates/presentation/template_import_action.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../fakes/fake_template_repository.dart';

void main() {
  testWidgets('empty payload shows the empty state and writes nothing', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    _ok(await templates.save(aTemplate()));

    await _pump(tester, templates: templates);
    await tester.pump();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.templatesImportEmptyHeadline), findsOneWidget);
    expect(find.text(Copy.templatesImportEmptyMessage), findsOneWidget);
    expect(find.byType(AppPrimaryAction), findsNothing);
    expect(templates.count, 1);
  });

  testWidgets('invalid JSON shows the failure and writes nothing', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    _ok(await templates.save(aTemplate()));

    await _pump(tester, templates: templates, payload: '{');
    await tester.pump();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(Copy.templatesImportInvalid), findsOneWidget);
    expect(find.text(Copy.templatesImportInvalidRecovery), findsOneWidget);
    expect(find.byType(AppPrimaryAction), findsNothing);
    expect(templates.count, 1);
  });

  testWidgets('an unknown schema version is rejected and writes nothing', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    _ok(await templates.save(aTemplate()));

    await _pump(
      tester,
      templates: templates,
      payload: const <String, Object?>{
        'schema_version': 2,
        'name': 'Assets',
        'fields': <Object>[],
      },
    );
    await tester.pump();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text(Copy.templatesImportUnknownSchema), findsOneWidget);
    expect(
      find.text(Copy.templatesImportUnknownSchemaRecovery),
      findsOneWidget,
    );
    expect(find.byType(AppPrimaryAction), findsNothing);
    expect(templates.count, 1);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeTemplateRepository templates,
  Object? payload,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        templateRepositoryProvider.overrideWith((Ref _) => templates),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: TemplateImportAction(projectId: 'project-1', payload: payload),
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

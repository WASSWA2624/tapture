import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/templates/presentation/xlsx_mapping_screen.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../fakes/fake_template_repository.dart';

void main() {
  testWidgets('empty path shows the empty state and writes nothing', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);

    await _pump(tester, templates: templates);
    await tester.pump();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.xlsxMappingEmptyHeadline), findsOneWidget);
    expect(find.text(Copy.xlsxMappingEmptyMessage), findsOneWidget);
    expect(find.byType(AppPrimaryAction), findsNothing);
    expect(templates.count, 0);
  });

  testWidgets('an unreadable file shows the failure and writes nothing', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    final Directory temp = Directory.systemTemp.createTempSync(
      'tapture-xlsx-map-',
    );
    addTearDown(() {
      if (temp.existsSync()) {
        temp.deleteSync(recursive: true);
      }
    });
    final File file = File('${temp.path}/notes.txt');
    file.writeAsStringSync('not a spreadsheet');

    await _pump(
      tester,
      templates: templates,
      path: file.path,
      project: aProject(),
    );
    await _waitFor(tester, find.byType(AppErrorState));

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.byType(AppPrimaryAction), findsNothing);
    expect(templates.count, 0);
  });

  testWidgets('skipping a column omits it from the saved template', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    final Directory temp = Directory.systemTemp.createTempSync(
      'tapture-xlsx-map-',
    );
    addTearDown(() {
      if (temp.existsSync()) {
        temp.deleteSync(recursive: true);
      }
    });
    final File source = File('${temp.path}/register.csv');
    source.writeAsStringSync('Asset tag,Serial,Status\nA-1,100,Active\n');
    final String before = source.readAsStringSync();
    final Project project = aProject();

    await _pump(
      tester,
      templates: templates,
      path: source.path,
      project: project,
      persist:
          ({
            required String projectId,
            required String projectName,
            required String folderName,
            required String path,
            required TemplateDef draft,
          }) async {
            return templates.save(draft.copyWith(id: '', projectId: projectId));
          },
    );
    await _waitFor(tester, find.byType(AppListTile));

    expect(find.byType(AppPrimaryAction), findsOneWidget);
    expect(templates.count, 0);

    await tester.tap(find.byTooltip(Copy.overflowMenu).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.xlsxMappingSkip));
    await tester.pump();
    expect(find.text(Copy.xlsxMappingSkipped), findsOneWidget);

    await tester.tap(find.byType(AppPrimaryAction));
    for (int attempt = 0; attempt < 40 && templates.count == 0; attempt++) {
      await _flushAsync(tester);
    }

    expect(templates.count, 1);
    final TemplateDef saved = _ok(await templates.byId('template-0'))!;
    expect(saved.source, 'imported');
    expect(saved.sheetName, isNotEmpty);
    expect(saved.headerRow, 1);
    expect(saved.fields.map((FieldDef field) => field.label), <String>[
      'Asset tag',
      'Status',
    ]);
    expect(saved.fields.map((FieldDef field) => field.outputColumn), <String>[
      'A',
      'C',
    ]);
    expect(source.readAsStringSync(), before);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeTemplateRepository templates,
  String? path,
  Project? project,
  StorageRoot? storage,
  Future<Result<TemplateDef>> Function({
    required String projectId,
    required String projectName,
    required String folderName,
    required String path,
    required TemplateDef draft,
  })?
  persist,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        templateRepositoryProvider.overrideWith((Ref _) => templates),
        if (storage != null)
          storageRootProvider.overrideWith((Ref _) => storage),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: XlsxMappingScreen(path: path, project: project, persist: persist),
      ),
    ),
  );
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (int attempt = 0; attempt < 40; attempt++) {
    await _flushAsync(tester);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('timed out waiting for $finder');
}

Future<void> _flushAsync(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pump();
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

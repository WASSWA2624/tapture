import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/presentation/field_add_sheet.dart';
import 'package:tapture/features/templates/presentation/field_list_screen.dart';
import 'package:tapture/features/templates/presentation/shipped_picker_screen.dart';
import 'package:tapture/features/templates/presentation/template_create_screen.dart';
import 'package:tapture/features/templates/presentation/template_list_screen.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../../support/screen_matrix.dart';
import '../../projects/fakes/fake_project_repository.dart';
import '../fakes/fake_shipped_template_loader.dart';
import '../fakes/fake_template_repository.dart';

void main() {
  testWidgets(
    'global library ignores a selected project and customizes an immutable asset',
    (WidgetTester tester) async {
      final FakeTemplateRepository templates = _repository();
      await templates.save(_library);
      await templates.save(aTemplate(id: 'project-only', name: 'Project only'));
      final FakeShippedTemplateLoader loader = _loader(templates);
      await _pump(tester, templates, loader, selectedProject: true);
      expect(find.text('My library'), findsOneWidget);
      expect(find.text('Project only'), findsNothing);
      await tester.enterText(find.byType(TextField).first, 'Survey asset');
      await tester.pumpAndSettle();
      final Finder asset = find.widgetWithText(AppListTile, 'Survey asset');
      expect(
        find.descendant(of: asset, matching: find.byType(AppOverflowMenu)),
        findsNothing,
      );
      await tester.tap(asset);
      await tester.pumpAndSettle();
      expect(find.text(Copy.templatesCustomizeCopy), findsOneWidget);
      expect(find.text(Copy.templatesDelete), findsNothing);
      await tester.tap(find.byType(AppPrimaryAction));
      await tester.pumpAndSettle();
      final List<TemplateDef> saved = _owned(templates, null);
      expect(saved, hasLength(2));
      expect(
        saved.singleWhere((row) => row.id != _library.id).source,
        'shipped',
      );
      expect(find.byType(FieldListScreen), findsOneWidget);
      expect(loader.rows.single, _asset);
      expect(loader.rows.single.id, isEmpty);
    },
  );

  testWidgets(
    'blank global creation and field editing work without a project and retain failures',
    (WidgetTester tester) async {
      final FakeTemplateRepository templates = _repository();
      await _pump(tester, templates, _loader(templates));
      await tester.tap(find.text(Copy.templatesCreate));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'Custom observations',
      );
      await tester.tap(find.byType(AppPrimaryAction));
      await tester.pumpAndSettle();
      final TemplateDef created = _owned(templates, null).single;
      expect(created.projectId, isNull);
      await tester.tap(find.byType(AppPrimaryAction));
      await tester.pumpAndSettle();
      expect(find.byType(FieldAddSheet), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Observation');
      templates.saveFailure = const StorageFailure(
        message: 'Local save failed',
      );
      await tester.tap(find.byType(AppPrimaryAction));
      await tester.pumpAndSettle();
      expect(find.text('Local save failed'), findsOneWidget);
      expect((await templates.byId(created.id)).getOrThrow()!.fields, isEmpty);
      templates.saveFailure = null;
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(FieldAddSheet)),
      );
      container.read(currentProjectProvider.notifier).open('project-2');
      await tester.tap(find.byType(AppPrimaryAction));
      await tester.pumpAndSettle();
      final TemplateDef edited = (await templates.byId(
        created.id,
      )).getOrThrow()!;
      expect(edited.projectId, isNull);
      expect(edited.fields.single.label, 'Observation');
      expect(edited.version, created.version + 1);
    },
  );

  testWidgets(
    'a saved shipped-derived library template deletes and Undo restores it',
    (WidgetTester tester) async {
      final FakeTemplateRepository templates = _repository();
      await templates.save(_library);
      await _pump(tester, templates, _loader(templates));
      final Finder row = find.byKey(
        const ValueKey<String>('library-template-library'),
      );
      await tester.tap(
        find.descendant(of: row, matching: find.byType(AppOverflowMenu)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(Copy.templatesDelete));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Copy.templatesDelete));
      await tester.pumpAndSettle();
      expect(_owned(templates, null), isEmpty);
      await tester.tap(find.text(Copy.undo));
      await tester.pumpAndSettle();
      expect(_owned(templates, null).single.id, 'library');
      expect(
        find.byKey(const ValueKey<String>('library-template-library')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'project picker attaches a saved library copy with its explicit owner',
    (WidgetTester tester) async {
      final FakeTemplateRepository templates = _repository();
      await templates.save(_library);
      await _pump(
        tester,
        templates,
        _loader(templates),
        projectId: 'project-2',
        selectedProject: true,
        picker: true,
      );
      await tester.tap(find.text('My library'));
      await tester.pumpAndSettle();
      final TemplateDef attached = _owned(templates, 'project-2').single;
      expect(attached.id, isNot('library'));
      expect(attached.version, 1);
      await templates.save(
        _library.copyWith(name: 'Changed source', fields: const <FieldDef>[]),
      );
      await templates.delete('library', reason: 'Remove source');
      expect((await templates.byId(attached.id)).getOrThrow(), attached);
      expect(_owned(templates, 'project-1'), isEmpty);
    },
  );

  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets(
      'global catalogue preview remains reachable at ${cell.description}',
      (WidgetTester tester) async {
        final FakeTemplateRepository templates = _repository();
        await templates.save(_library);
        await _pump(tester, templates, _loader(templates), cell: cell);
        expect(find.text('My library'), findsOneWidget);
        await tester.enterText(find.byType(TextField).first, 'Survey asset');
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(AppListTile, 'Survey asset'));
        await tester.pumpAndSettle();
        expect(find.text(Copy.templatesCustomizeCopy), findsOneWidget);
        await tester.ensureVisible(find.byType(AppPrimaryAction));
        await tester.tap(find.byType(AppPrimaryAction));
        await tester.pumpAndSettle();
        expect(find.byType(FieldListScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.all(),
    );
  }

  for (final (String, Brightness, bool) mode in <(String, Brightness, bool)>[
    ('light', Brightness.light, false),
    ('dark', Brightness.dark, false),
    ('outdoor', Brightness.light, true),
  ]) {
    for (final bool preview in <bool>[false, true]) {
      testWidgets(
        'global library golden ${mode.$1} ${preview ? 'preview_text2' : 'catalogue'}',
        (WidgetTester tester) async {
          final FakeTemplateRepository templates = _repository();
          await templates.save(_library);
          await _pump(
            tester,
            templates,
            _loader(templates),
            cell: ScreenMatrix(
              const Size(393, 852),
              preview ? 2 : 1,
              mode.$2,
              mode.$3,
            ),
          );
          if (preview) {
            await tester.enterText(
              find.byType(TextField).first,
              'Survey asset',
            );
            await tester.pumpAndSettle();
            await tester.tap(find.widgetWithText(AppListTile, 'Survey asset'));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/template_library_${preview ? 'preview_text2' : 'catalogue'}_${mode.$1}.png',
            ),
          );
        },
        skip: kIsWeb,
      );
    }
  }

  testWidgets('pseudo-locale keeps global create and customization reachable', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = _repository();
    await _pump(
      tester,
      templates,
      _loader(templates),
      locale: const Locale('en', 'XA'),
      cell: const ScreenMatrix(Size(393, 320), 2, Brightness.light, false),
    );
    final LocalizedCopy copy = Copy.of(
      tester.element(find.byType(ShippedPickerScreen)),
    );
    expect(copy.templatesCreate, isNot(Copy.templatesCreate));
    expect(find.text(copy.templatesCreate), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Survey asset');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppListTile, 'Survey asset'));
    await tester.pumpAndSettle();
    expect(find.text(copy.templatesCustomizeCopy), findsOneWidget);
    await tester.ensureVisible(find.byType(AppPrimaryAction));
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pumpAndSettle();
    expect(find.byType(FieldListScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

FakeTemplateRepository _repository() {
  final FakeTemplateRepository repository = FakeTemplateRepository();
  addTearDown(repository.dispose);
  return repository;
}

List<TemplateDef> _owned(
  FakeTemplateRepository repository,
  String? projectId,
) => repository.stored.where((row) => row.projectId == projectId).toList();

FakeShippedTemplateLoader _loader(FakeTemplateRepository repository) =>
    FakeShippedTemplateLoader(repository: repository)
      ..catalogue.add(_entry)
      ..rows.add(_asset);

const TemplateDef _asset = TemplateDef(
  id: '',
  templateKey: 'survey',
  name: 'Survey asset',
  version: 1,
  fields: <FieldDef>[
    FieldDef(fieldKey: 'note', label: 'Observation', type: FieldType.text),
  ],
  identityFieldKeys: <String>[],
  rows: <TemplateRow>[],
  source: 'shipped',
);

const TemplateDef _library = TemplateDef(
  id: 'library',
  templateKey: 'custom',
  name: 'My library',
  version: 1,
  fields: <FieldDef>[
    FieldDef(fieldKey: 'note', label: 'Observation', type: FieldType.text),
  ],
  identityFieldKeys: <String>[],
  rows: <TemplateRow>[],
  source: 'shipped',
);

const ShippedTemplateEntry _entry = ShippedTemplateEntry(
  templateKey: 'survey',
  kind: 'observation',
  fieldCount: 1,
  title: 'Survey asset',
  code: 'OBS-001',
  category: ShippedCatalogueCategory(
    code: 'OBS',
    title: 'Observations',
    supergroupCode: '01',
    supergroupTitle: 'Field work',
  ),
  recordType: ShippedRecordType(
    code: 'OBS',
    title: 'Observation',
    kind: 'observation',
    capture: 'Notes',
    aiAssistance: 'None',
    outputs: 'Record',
    review: 'Review notes',
  ),
);

Future<void> _pump(
  WidgetTester tester,
  FakeTemplateRepository templates,
  FakeShippedTemplateLoader loader, {
  String? projectId,
  bool selectedProject = false,
  bool picker = false,
  Locale locale = const Locale('en'),
  ScreenMatrix cell = const ScreenMatrix(
    Size(800, 900),
    1,
    Brightness.light,
    false,
  ),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = cell.size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final FakeProjectRepository projects = FakeProjectRepository();
  addTearDown(projects.dispose);
  await projects.create(aProject());
  await projects.create(aProject(id: 'project-2', name: 'Second project'));
  final SettingsStore settings = SettingsStore.fake(
    stored: <String, Object?>{
      if (selectedProject) SettingKeys.openProjectId.name: 'project-1',
    },
  );
  final String root = RoutePaths.templateRoot(projectId: projectId);
  final GoRouter router = GoRouter(
    initialLocation: picker ? '$root/library' : root,
    routes: <RouteBase>[
      GoRoute(
        path: root,
        builder: (_, _) => TemplateListScreen(projectId: projectId),
        routes: <RouteBase>[
          GoRoute(
            path: 'new',
            builder: (_, _) => TemplateCreateScreen(projectId: projectId),
          ),
          GoRoute(
            path: 'library',
            builder: (_, _) => ShippedPickerScreen(projectId: projectId),
          ),
          GoRoute(
            path: ':templateId',
            builder: (_, state) => FieldListScreen(
              templateId: state.pathParameters['templateId']!,
            ),
            routes: <RouteBase>[
              GoRoute(
                path: 'fields/new',
                builder: (_, state) => FieldAddSheet(
                  templateId: state.pathParameters['templateId']!,
                ),
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
      overrides: <Override>[
        templateRepositoryProvider.overrideWithValue(templates),
        shippedTemplateLoaderProvider.overrideWithValue(loader),
        projectRepositoryProvider.overrideWithValue(projects),
        projectSettingsStoreProvider.overrideWithValue(settings),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        locale: locale,
        theme: cell.outdoor
            ? buildOutdoorTheme(Brightness.light)
            : buildTheme(brightness: cell.brightness),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(cell.textScale)),
          child: child!,
        ),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

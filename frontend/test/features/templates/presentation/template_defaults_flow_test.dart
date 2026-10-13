import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/network/network.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/presentation/offline_switch.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/presentation/field_add_sheet.dart';
import 'package:tapture/features/templates/presentation/field_list_screen.dart';
import 'package:tapture/features/templates/presentation/shipped_picker_screen.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../../support/screen_fonts.dart';
import '../../projects/fakes/fake_project_repository.dart';
import '../fakes/fake_shipped_template_loader.dart';
import '../fakes/fake_template_repository.dart';

void main() {
  setUpAll(ScreenFonts.loadForApp);

  testWidgets(
    'an attached template configures defaults in its owning project',
    (WidgetTester tester) async {
      final FakeTemplateRepository templates = await _repository();
      final GoRouter router = await _pump(
        tester,
        templates,
        location: RoutePaths.templateLibrary(projectId: 'project-2'),
      );
      templates.saveFailure = const StorageFailure(
        message: 'The template could not be saved locally.',
      );
      await _tapRow(tester, 'Library equipment');
      expect(_owned(templates, 'project-2'), isEmpty);
      expect(find.byType(ShippedPickerScreen), findsOneWidget);
      expect(find.byType(FieldListScreen), findsNothing);
      templates.saveFailure = null;
      await _tapRow(tester, 'Library equipment');

      final TemplateDef attached = _owned(templates, 'project-2').single;
      expect(attached.id, isNot(_library.id));
      expect(attached.version, 1);
      expect(attached.fields.single, _condition);
      expect(router.state.uri.toString(), _detail(attached.id));
      expect(
        tester
            .widget<FieldListScreen>(find.byType(FieldListScreen))
            .showAdvanced,
        isFalse,
      );
      expect(find.byType(FieldAddSheet), findsNothing);

      router.go(RoutePaths.templateRoot(projectId: 'project-2'));
      await tester.pumpAndSettle();
      await _menu(tester, 'Library equipment', Copy.fieldDefaultsTitle);
      expect(
        router.state.uri.queryParameters[RoutePaths.fieldAdvancedQuery],
        'true',
      );
      expect(
        tester
            .widget<FieldListScreen>(find.byType(FieldListScreen))
            .showAdvanced,
        isTrue,
      );
      await _tapRow(tester, _condition.label);
      expect(
        router.state.uri.toString(),
        RoutePaths.templateField(
          attached.id,
          _condition.fieldKey,
          projectId: 'project-2',
          showAdvanced: true,
        ),
      );
      _expectAdvanced(tester);
      expect(_value(tester, Copy.fieldDefaultValue), 'In service');
      await _enter(tester, Copy.fieldDefaultValue, 'Project condition');
      await _chooseSource(tester, AutoFill.device);
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(FieldAddSheet)),
      );
      container.read(currentProjectProvider.notifier).open('project-1');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AppPrimaryAction));
      await tester.pumpAndSettle();

      expect(
        router.state.uri.toString(),
        _detail(attached.id, showAdvanced: true),
      );
      expect(
        router.state.uri.queryParameters[RoutePaths.fieldAdvancedQuery],
        'true',
      );
      expect(find.byType(FieldListScreen), findsOneWidget);
      expect(
        tester
            .widget<FieldListScreen>(find.byType(FieldListScreen))
            .showAdvanced,
        isTrue,
      );
      final TemplateDef saved = _owned(templates, 'project-2').single;
      expect(saved.version, 2);
      expect(saved.fields.single.defaultValue, 'Project condition');
      expect(saved.fields.single.autoFill, AutoFill.device);
      expect(_owned(templates, null).single, _library);
      expect(_owned(templates, 'project-1').single.fields.single, _condition);
      expect(
        tester.widget<AppListTile>(_row(_condition.label)).subtitle,
        Copy.english.fieldFillingSummary(
          Copy.fieldRowSubtitle(
            typeLabel: Copy.fieldTypeLabel('text'),
            requiredField: false,
            calculated: false,
            fromPhotos: false,
            defaultValue: 'Project condition',
          ),
          Copy.fieldAutoFillLabel(AutoFill.device.name),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'field defaults open directly while adding a field stays simple',
    (WidgetTester tester) async {
      final FakeTemplateRepository templates = await _repository();
      final TemplateDef projectTemplate = (await templates.save(
        aTemplate(
          id: 'project-template',
          projectId: 'project-2',
          fields: const <FieldDef>[_condition],
        ),
      )).getOrThrow();
      final GoRouter router = await _pump(
        tester,
        templates,
        location: _detail(projectTemplate.id),
      );
      await _menu(tester, _condition.label, Copy.fieldDefaultsTitle);
      expect(
        router.state.uri.queryParameters[RoutePaths.fieldAdvancedQuery],
        'true',
      );
      _expectAdvanced(tester);
      expect(_value(tester, Copy.fieldDefaultValue), 'In service');
      await tester.tap(find.byType(AppPrimaryAction));
      await tester.pumpAndSettle();
      expect(
        router.state.uri.toString(),
        _detail(projectTemplate.id, showAdvanced: true),
      );
      await tester.tap(find.byType(AppPrimaryAction));
      await tester.pumpAndSettle();

      expect(
        router.state.uri.toString(),
        RoutePaths.templateFieldNew(projectTemplate.id, projectId: 'project-2'),
      );
      final FieldAddSheet editor = tester.widget<FieldAddSheet>(
        find.byType(FieldAddSheet),
      );
      expect(editor.fieldKey, isNull);
      expect(editor.showAdvanced, isFalse);
      expect(_textField(Copy.fieldDefaultValue), findsNothing);
      expect(tester.widget<AppSwitchTile>(_advanced()).value, isFalse);
      final TemplateDef saved = templates.stored.singleWhere(
        (row) => row.id == projectTemplate.id,
      );
      expect(saved.version, projectTemplate.version + 1);
      expect(saved.fields, projectTemplate.fields);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'library defaults stay global while another project is selected',
    (WidgetTester tester) async {
      final FakeTemplateRepository templates = await _repository();
      final GoRouter router = await _pump(
        tester,
        templates,
        location: RoutePaths.templates,
      );
      await _menu(tester, 'Library equipment', Copy.fieldDefaultsTitle);
      expect(
        router.state.uri.toString(),
        RoutePaths.templateDetail(_library.id, showAdvanced: true),
      );
      await _tapRow(tester, _condition.label);
      _expectAdvanced(tester);
      await _enter(tester, Copy.fieldDefaultValue, 'Library condition');
      await _chooseSource(tester, AutoFill.operator);
      await tester.tap(find.byType(AppPrimaryAction));
      await tester.pumpAndSettle();

      expect(
        router.state.uri.toString(),
        RoutePaths.templateDetail(_library.id, showAdvanced: true),
      );
      expect(
        _owned(templates, null).single.fields.single.defaultValue,
        'Library condition',
      );
      expect(
        _owned(templates, null).single.fields.single.autoFill,
        AutoFill.operator,
      );
      expect(_owned(templates, 'project-1').single.fields.single, _condition);
      expect(_owned(templates, 'project-2'), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}

const FieldDef _condition = FieldDef(
  fieldKey: 'condition',
  label: 'Condition',
  type: FieldType.text,
  defaultValue: 'In service',
);

const TemplateDef _library = TemplateDef(
  id: 'saved-library',
  templateKey: 'equipment',
  name: 'Library equipment',
  version: 1,
  fields: <FieldDef>[_condition],
  identityFieldKeys: <String>[],
  rows: <TemplateRow>[],
);

Future<FakeTemplateRepository> _repository() async {
  final FakeTemplateRepository repository = FakeTemplateRepository();
  addTearDown(repository.dispose);
  await repository.save(_library);
  await repository.save(
    aTemplate(
      id: 'other-project-template',
      projectId: 'project-1',
      name: 'Other project form',
      fields: const <FieldDef>[_condition],
    ),
  );
  return repository;
}

List<TemplateDef> _owned(FakeTemplateRepository repository, String? owner) =>
    repository.stored.where((template) => template.projectId == owner).toList();

String _detail(String id, {bool showAdvanced = false}) =>
    RoutePaths.templateDetail(
      id,
      projectId: 'project-2',
      showAdvanced: showAdvanced,
    );

Future<GoRouter> _pump(
  WidgetTester tester,
  FakeTemplateRepository templates, {
  required String location,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final FakeProjectRepository projects = FakeProjectRepository();
  addTearDown(projects.dispose);
  await projects.create(aProject(id: 'project-1', name: 'First project'));
  await projects.create(aProject(id: 'project-2', name: 'Second project'));
  final SettingsStore settings = SettingsStore.fake(
    stored: <String, Object?>{
      SettingKeys.openProjectId.name: 'project-1',
      SettingKeys.lastLocation.name: location,
    },
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        templateRepositoryProvider.overrideWithValue(templates),
        shippedTemplateLoaderProvider.overrideWithValue(
          FakeShippedTemplateLoader(repository: templates),
        ),
        projectRepositoryProvider.overrideWithValue(projects),
        projectSettingsStoreProvider.overrideWithValue(settings),
        offlineByChoiceOverride(true),
        connectivityServiceProvider.overrideWith((Ref ref) {
          final ConnectivityService service = ConnectivityService.fake(
            source: Stream<NetworkState>.value(NetworkState.offline),
          );
          ref.onDispose(service.dispose);
          return service;
        }),
      ],
      child: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) =>
            MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: ScreenFonts.theme(
                buildTheme(brightness: Brightness.light),
              ),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: ref.watch(routerProvider),
            ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  ).read(routerProvider);
}

Finder _row(String title) => find.byWidgetPredicate(
  (Widget widget) => widget is AppListTile && widget.title == title,
);

Future<void> _tapRow(WidgetTester tester, String title) async {
  await tester.ensureVisible(_row(title));
  await tester.tap(
    find.descendant(of: _row(title), matching: find.text(title)),
  );
  await tester.pumpAndSettle();
}

Future<void> _menu(WidgetTester tester, String title, String action) async {
  await tester.ensureVisible(_row(title));
  await tester.tap(
    find.descendant(of: _row(title), matching: find.byType(AppOverflowMenu)),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(action));
  await tester.pumpAndSettle();
}

Finder _advanced() => find.byWidgetPredicate(
  (Widget widget) =>
      widget is AppSwitchTile && widget.title == Copy.fieldAdvanced,
);

void _expectAdvanced(WidgetTester tester) {
  expect(
    tester.widget<FieldAddSheet>(find.byType(FieldAddSheet)).showAdvanced,
    isTrue,
  );
  expect(tester.widget<AppSwitchTile>(_advanced()).value, isTrue);
  expect(_textField(Copy.fieldDefaultValue), findsOneWidget);
}

Finder _textField(String label) => find.byWidgetPredicate(
  (Widget widget) => widget is AppTextField && widget.label == label,
);

String _value(WidgetTester tester, String label) =>
    tester.widget<AppTextField>(_textField(label)).controller.text;

Future<void> _enter(WidgetTester tester, String label, String value) async {
  await tester.ensureVisible(_textField(label));
  await tester.enterText(_textField(label), value);
  await tester.pumpAndSettle();
}

Future<void> _chooseSource(WidgetTester tester, AutoFill source) async {
  final Finder picker = find.byWidgetPredicate(
    (Widget widget) =>
        widget is AppChoiceField<String> && widget.label == Copy.fieldAutoFill,
  );
  await tester.ensureVisible(picker);
  await tester.tap(picker);
  await tester.pumpAndSettle();
  final String label = Copy.fieldAutoFillLabel(source.name);
  await tester.enterText(
    find.descendant(
      of: find.byType(AppSearchField).last,
      matching: find.byType(TextField),
    ),
    label,
  );
  await tester.pumpAndSettle();
  await _tapRow(tester, label);
}

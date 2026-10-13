import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/features/templates/presentation/field_add_sheet.dart';
import 'package:tapture/features/templates/presentation/template_duplicate_action.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../../support/pump_app.dart';
import '../../../support/screen_fonts.dart';
import '../fakes/fake_template_repository.dart';

void main() {
  setUpAll(ScreenFonts.loadForApp);

  for (final AutoFill source in AutoFill.values) {
    testWidgets('${source.name} can be selected, saved and reopened', (
      WidgetTester tester,
    ) async {
      final FakeTemplateRepository repository = await _store();
      await _open(tester, repository);
      await _choose<InputMode>(tester, Copy.fieldInputMode, InputMode.auto);
      await _choose<String>(tester, Copy.fieldAutoFill, source.name);
      await _save(tester);

      final FieldDef saved = _saved(repository);
      expect(saved.autoFill, source);
      expect(saved.inputMode, InputMode.auto);
      expect(repository.stored.single.version, 2);

      await _reopen(tester, repository);
      expect(_choiceValue<String>(tester, Copy.fieldAutoFill), source.name);
      expect(
        _choiceValue<InputMode>(tester, Copy.fieldInputMode),
        InputMode.auto,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final InputMode mode in InputMode.values) {
    testWidgets(
      '${mode.name} retains a fixed default through save and reopen',
      (WidgetTester tester) async {
        final FakeTemplateRepository repository = await _store();
        await _open(tester, repository);
        await _enter(tester, Copy.fieldDefaultValue, 'In service');
        await _choose<InputMode>(tester, Copy.fieldInputMode, mode);
        await _save(tester);

        expect(_saved(repository).defaultValue, 'In service');
        expect(_saved(repository).inputMode, mode);
        expect(_saved(repository).autoFill, isNull);

        await _reopen(tester, repository);
        expect(_text(tester, Copy.fieldDefaultValue), 'In service');
        expect(_choiceValue<InputMode>(tester, Copy.fieldInputMode), mode);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('context settings retain field mappings and dataset bindings', (
    WidgetTester tester,
  ) async {
    const FieldDef original = FieldDef(
      fieldKey: 'supplier',
      label: 'Supplier',
      type: FieldType.lookup,
      group: 'Equipment',
      outputColumn: 'F',
      sortOrder: 7,
      lookup: <String, Object?>{
        'datasetId': 'suppliers',
        'matchColumn': 'code',
      },
    );
    final FakeTemplateRepository repository = await _store(field: original);
    await _open(tester, repository, fieldKey: original.fieldKey);
    await _enter(tester, Copy.fieldDefaultValue, 'Local supplier');
    await _choose<String>(tester, Copy.fieldAutoFill, AutoFill.context.name);
    await _enter(tester, Copy.fieldContextLevel, '2');
    await _switch(tester, Copy.fieldStickable);
    await _save(tester);

    final FieldDef saved = _saved(repository);
    expect(saved.defaultValue, 'Local supplier');
    expect(saved.autoFill, AutoFill.context);
    expect(saved.contextLevel, 2);
    expect(saved.stickable, isTrue);
    expect(saved.group, original.group);
    expect(saved.outputColumn, original.outputColumn);
    expect(saved.lookup, original.lookup);
    expect(saved.sortOrder, original.sortOrder);

    await _reopen(tester, repository, fieldKey: original.fieldKey);
    expect(_text(tester, Copy.fieldContextLevel), '2');
    expect(
      tester.widget<AppSwitchTile>(_switchFinder(Copy.fieldStickable)).value,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('clearing the default and source persists empty settings', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository repository = await _store(
      field: _field.copyWith(
        defaultValue: 'Old value',
        inputMode: InputMode.auto,
        autoFill: AutoFill.device,
      ),
    );
    await _open(tester, repository);
    expect(_text(tester, Copy.fieldDefaultValue), 'Old value');
    expect(
      _choiceValue<String>(tester, Copy.fieldAutoFill),
      AutoFill.device.name,
    );
    await _enter(tester, Copy.fieldDefaultValue, '');
    await _choose<String>(tester, Copy.fieldAutoFill, 'none');
    await _choose<InputMode>(tester, Copy.fieldInputMode, InputMode.manualOnly);
    await _save(tester);

    expect(_saved(repository).defaultValue, isNull);
    expect(_saved(repository).autoFill, isNull);
    expect(_saved(repository).inputMode, InputMode.manualOnly);

    await _reopen(tester, repository);
    expect(_text(tester, Copy.fieldDefaultValue), isEmpty);
    expect(_choiceValue<String>(tester, Copy.fieldAutoFill), 'none');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed save keeps source settings until a durable retry', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository repository = await _store();
    await _open(tester, repository);
    await _enter(tester, Copy.fieldDefaultValue, 'Fallback value');
    await _choose<InputMode>(tester, Copy.fieldInputMode, InputMode.auto);
    await _choose<String>(tester, Copy.fieldAutoFill, AutoFill.sequence.name);
    repository.saveFailure = const StorageFailure(
      message: 'The device is full.',
      recoveryAction: 'Free space and save again.',
    );
    await _save(tester);

    expect(repository.stored.single.version, 1);
    expect(_saved(repository), _field);
    expect(find.text('The device is full.'), findsWidgets);
    expect(_text(tester, Copy.fieldDefaultValue), 'Fallback value');
    expect(
      _choiceValue<InputMode>(tester, Copy.fieldInputMode),
      InputMode.auto,
    );
    expect(
      _choiceValue<String>(tester, Copy.fieldAutoFill),
      AutoFill.sequence.name,
    );

    repository.saveFailure = null;
    await _save(tester);
    expect(repository.stored.single.version, 2);
    expect(_saved(repository).defaultValue, 'Fallback value');
    expect(_saved(repository).autoFill, AutoFill.sequence);
    expect(_saved(repository).inputMode, InputMode.auto);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving a default-only edit asks before discarding it', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository repository = await _store();
    await _open(tester, repository, inRoute: true);
    await _enter(tester, Copy.fieldDefaultValue, 'Unsaved default');
    await Navigator.of(tester.element(find.byType(FieldAddSheet))).maybePop();
    await tester.pumpAndSettle();

    expect(find.text(Copy.unsavedChanges), findsOneWidget);
    expect(_saved(repository).defaultValue, isNull);
    await tester.tap(find.text(Copy.cancel));
    await tester.pumpAndSettle();
    expect(_text(tester, Copy.fieldDefaultValue), 'Unsaved default');
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening saved defaults leaves the form clean', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository repository = await _store(
      field: _field.copyWith(defaultValue: 'Stored default', contextLevel: 2),
    );
    await _open(tester, repository, inRoute: true);
    expect(_text(tester, Copy.fieldDefaultValue), 'Stored default');
    await Navigator.of(tester.element(find.byType(FieldAddSheet))).maybePop();
    await tester.pumpAndSettle();

    expect(find.text(Copy.unsavedChanges), findsNothing);
    expect(find.byType(FieldAddSheet), findsNothing);
    expect(_saved(repository).defaultValue, 'Stored default');
    expect(repository.stored.single.version, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('configuring a project copy preserves its library source', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository repository = FakeTemplateRepository();
    addTearDown(repository.dispose);
    const TemplateDef library = TemplateDef(
      id: 'library',
      templateKey: 'equipment',
      name: 'Equipment',
      version: 1,
      fields: <FieldDef>[_field],
      identityFieldKeys: <String>[],
      rows: <TemplateRow>[],
    );
    await repository.save(library);
    final TemplateDef attached = (await repository.save(
      TemplateDuplicateAction.draftFrom(library).copyWith(projectId: 'project'),
    )).getOrThrow();
    await _open(tester, repository, templateId: attached.id);
    await _enter(tester, Copy.fieldDefaultValue, 'Project value');
    await _choose<String>(tester, Copy.fieldAutoFill, AutoFill.operator.name);
    await _save(tester);

    final TemplateDef saved = repository.stored.singleWhere(
      (TemplateDef template) => template.id == attached.id,
    );
    expect(saved.projectId, 'project');
    expect(saved.fields.single.defaultValue, 'Project value');
    expect(saved.fields.single.autoFill, AutoFill.operator);
    expect(
      repository.stored.singleWhere(
        (TemplateDef template) => template.id == 'library',
      ),
      library,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'adding a field keeps default and source settings behind Advanced',
    (WidgetTester tester) async {
      final FakeTemplateRepository repository = await _store();
      await _open(tester, repository, fieldKey: null);
      expect(_textField(Copy.fieldDefaultValue), findsNothing);
      await _enter(tester, Copy.fieldLabel, 'Inspector');
      await _switch(tester, Copy.fieldAdvanced);
      await _enter(tester, Copy.fieldDefaultValue, 'Assigned later');
      await _choose<InputMode>(tester, Copy.fieldInputMode, InputMode.auto);
      await _choose<String>(tester, Copy.fieldAutoFill, AutoFill.operator.name);
      await _save(tester);

      final List<FieldDef> fields = repository.stored.single.fields;
      expect(fields, hasLength(2));
      expect(fields.first, _field);
      expect(fields.last.fieldKey, 'inspector');
      expect(fields.last.defaultValue, 'Assigned later');
      expect(fields.last.inputMode, InputMode.auto);
      expect(fields.last.autoFill, AutoFill.operator);
      expect(tester.takeException(), isNull);
    },
  );
}

const FieldDef _field = FieldDef(
  fieldKey: 'status',
  label: 'Status',
  type: FieldType.text,
);

Future<FakeTemplateRepository> _store({FieldDef field = _field}) async {
  final FakeTemplateRepository repository = FakeTemplateRepository();
  addTearDown(repository.dispose);
  await repository.save(aTemplate(id: 'template', fields: <FieldDef>[field]));
  return repository;
}

FieldDef _saved(FakeTemplateRepository repository) =>
    repository.stored.single.fields.single;

Future<void> _open(
  WidgetTester tester,
  FakeTemplateRepository repository, {
  String templateId = 'template',
  String? fieldKey = 'status',
  bool inRoute = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final Widget screen = FieldAddSheet(
    templateId: templateId,
    fieldKey: fieldKey,
    showAdvanced: fieldKey != null,
  );
  await pumpApp(
    tester,
    inRoute ? const SizedBox.shrink() : screen,
    useScreenFonts: true,
    overrides: <Override>[
      templateRepositoryProvider.overrideWithValue(repository),
    ],
  );
  await tester.pumpAndSettle();
  if (inRoute) {
    unawaited(
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push(MaterialPageRoute<void>(builder: (BuildContext _) => screen)),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _reopen(
  WidgetTester tester,
  FakeTemplateRepository repository, {
  String fieldKey = 'status',
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await _open(tester, repository, fieldKey: fieldKey);
}

Finder _textField(String label) => find.byWidgetPredicate(
  (Widget widget) => widget is AppTextField && widget.label == label,
);

String _text(WidgetTester tester, String label) =>
    tester.widget<AppTextField>(_textField(label)).controller.text;

Future<void> _enter(WidgetTester tester, String label, String value) async {
  final Finder field = _textField(label);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

Finder _choice<T>(String label) => find.byWidgetPredicate(
  (Widget widget) => widget is AppChoiceField<T> && widget.label == label,
);

T? _choiceValue<T>(WidgetTester tester, String label) =>
    tester.widget<AppChoiceField<T>>(_choice<T>(label)).value;

Future<void> _choose<T>(WidgetTester tester, String label, T value) async {
  final Finder field = _choice<T>(label);
  final String selected = tester
      .widget<AppChoiceField<T>>(field)
      .options
      .singleWhere((option) => option.value == value)
      .label;
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.descendant(
      of: find.byType(AppSearchField),
      matching: find.byType(TextField),
    ),
    selected,
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byWidgetPredicate(
      (Widget widget) => widget is AppListTile && widget.title == selected,
    ),
  );
  await tester.pumpAndSettle();
}

Finder _switchFinder(String label) => find.byWidgetPredicate(
  (Widget widget) => widget is AppSwitchTile && widget.title == label,
);

Future<void> _switch(WidgetTester tester, String label) async {
  final Finder field = _switchFinder(label);
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.byType(AppPrimaryAction));
  await tester.pumpAndSettle();
}

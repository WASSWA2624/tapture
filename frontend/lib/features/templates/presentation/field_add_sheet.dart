import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/field_def.dart';
import '../domain/template_def.dart';
import '../templates.dart' show templateRepositoryProvider;
import 'field_advanced_section.dart';
import 'field_options_editor.dart';
import 'field_validation_editor.dart';
import 'template_editor_source.dart';
import 'template_locations.dart';

/// Three-question add and edit flow, with Advanced collapsed by default.
class FieldAddSheet extends ConsumerStatefulWidget {
  /// Creates the sheet for [templateId]. [fieldKey] set means edit.
  const FieldAddSheet({super.key, required this.templateId, this.fieldKey});

  /// Template that owns the field.
  final String templateId;

  /// Existing key when editing. Null creates a new field.
  final String? fieldKey;

  /// snake_case key from [label], with [unit] appended when measured.
  static String keyFrom(String label, {String? unit}) {
    String slug = label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (slug.isEmpty || !_startsLetter.hasMatch(slug)) {
      slug = slug.isEmpty ? 'field' : 'field_$slug';
    }
    final String suffix = (unit ?? '').trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    if (suffix.isNotEmpty && !slug.endsWith('_$suffix')) {
      slug = '${slug}_$suffix';
    }
    return slug;
  }

  /// [base], or [base]_2 and up until the key is free. [keep] is allowed.
  static String uniqueKey(String base, Iterable<String> taken, {String? keep}) {
    if (base == keep || !taken.contains(base)) {
      return base;
    }
    int suffix = 2;
    while (taken.contains('${base}_$suffix')) {
      suffix += 1;
    }
    return '${base}_$suffix';
  }

  /// Whether [label] or [key] packs two facts (§13.1).
  static bool packsTwoFacts(String label, {String? key}) {
    final String resolved = key ?? keyFrom(label);
    if (resolved == 'make_model' ||
        resolved == 'address' ||
        resolved.contains('_and_')) {
      return true;
    }
    return _packed.hasMatch(resolved) || _packed.hasMatch(label);
  }

  /// Sets [hidden] on [fieldKey] and bumps the version. Values are untouched.
  static TemplateDef setHidden(
    TemplateDef template, {
    required String fieldKey,
    required bool hidden,
  }) {
    return template.copyWith(
      version: template.version + 1,
      fields: <FieldDef>[
        for (final FieldDef field in template.fields)
          field.fieldKey == fieldKey ? field.copyWith(hidden: hidden) : field,
      ],
    );
  }

  /// Keys capture and export still offer — hidden fields are omitted.
  static List<String> visibleKeys(Iterable<FieldDef> fields) {
    return <String>[
      for (final FieldDef field in fields)
        if (!field.hidden) field.fieldKey,
    ];
  }

  @override
  ConsumerState<FieldAddSheet> createState() => _FieldAddSheetState();
}

class _FieldAddSheetState extends ConsumerState<FieldAddSheet> {
  final TextEditingController _label = TextEditingController();
  final TextEditingController _defaultValue = TextEditingController();
  final TextEditingController _unit = TextEditingController();
  final TextEditingController _help = TextEditingController();
  final TextEditingController _requiredWhen = TextEditingController();
  final TextEditingController _contextLevel = TextEditingController();
  bool _hydrated = false;

  @override
  void dispose() {
    _label.dispose();
    _defaultValue.dispose();
    _unit.dispose();
    _help.dispose();
    _requiredWhen.dispose();
    _contextLevel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<TemplateDef?> value = ref
        .watch(templateEditorSourceProvider(widget.templateId))
        .whenData(_pick);
    final _FieldAddView view = ref.watch(_fieldAddProvider);
    final TemplateDef? template = value.asData?.value;
    _hydrate(template);
    return AppPage(
      key: ValueKey<String>(
        widget.fieldKey == null ? 'route-field-add' : 'route-field-edit',
      ),
      title: widget.fieldKey == null
          ? localCopy.templatesAddField
          : localCopy.templatesEditField,
      scrollable: false,
      overflow: <AppOverflowAction>[
        if (widget.fieldKey != null)
          AppOverflowAction(
            key: const ValueKey<String>('field-bind-dataset'),
            label: localCopy.templatesBindDataset,
            icon: AppIcons.dataset,
            onTap: _bindDataset,
          ),
      ],
      body: AsyncValueView<TemplateDef?>(
        value: value,
        isEmpty: (TemplateDef? row) => row == null,
        empty: () => AppEmptyState(
          icon: AppIcons.fields,
          headline: Copy.of(context).fieldAddEmptyHeadline,
          message: Copy.of(context).fieldAddEmptyMessage,
        ),
        onRetry: () =>
            ref.invalidate(templateEditorSourceProvider(widget.templateId)),
        data: (TemplateDef? row) => _form(row!, view),
      ),
    );
  }

  Widget _form(TemplateDef template, _FieldAddView view) {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool choice =
        view.type == FieldType.choice || view.type == FieldType.multiChoice;
    return AppForm(
      guardUnsaved: true,
      dirty: view.dirty,
      errors: <String>[
        if (Copy.of(
              context,
            ).stateText(view.localizedSaveError, view.saveError) !=
            null)
          Copy.of(context).stateText(view.localizedSaveError, view.saveError)!,
        if (view.twoFactsWarning != null)
          localCopy.stateText(
            view.localizedTwoFactsWarning,
            view.twoFactsWarning,
          )!,
      ],
      fields: <Widget>[
        if (view.twoFactsWarning != null) ...<Widget>[
          AppBanner(
            message: localCopy.fieldTwoFactsWarning,
            icon: AppIcons.warning,
            tone: SnackTone.warning,
          ),
          AppButton(
            label: localCopy.fieldKeepAnyway,
            variant: AppButtonVariant.secondary,
            onPressed: () => ref.read(_fieldAddProvider.notifier).keepAnyway(),
          ),
        ],
        AppTextField(
          label: localCopy.fieldLabel,
          controller: _label,
          requiredness: FieldRequiredness.required,
          errorText: Copy.of(
            context,
          ).stateText(view.localizedLabelError, view.labelError),
          textInputAction: TextInputAction.next,
        ),
        AppChoiceField<FieldType>(
          label: localCopy.fieldType,
          value: view.type,
          options: <Choice<FieldType>>[
            for (final FieldType type in FieldType.values)
              Choice<FieldType>(type, localCopy.fieldTypeLabel(type.name)),
          ],
          onChanged: (FieldType? type) {
            if (type != null) {
              ref.read(_fieldAddProvider.notifier).setType(type);
            }
          },
        ),
        if (view.type == FieldType.lookup && widget.fieldKey != null)
          AppListTile(
            key: const ValueKey<String>('field-bind-dataset-row'),
            title: localCopy.templatesBindDataset,
            trailing: const Icon(AppIcons.open),
            onTap: _bindDataset,
          ),
        AppRadioGroup<Requiredness>(
          label: localCopy.fieldRequiredness,
          value: view.requiredness,
          direction: Axis.horizontal,
          options: <Choice<Requiredness>>[
            Choice<Requiredness>(
              Requiredness.required,
              localCopy.fieldRequired,
            ),
            Choice<Requiredness>(
              Requiredness.recommended,
              localCopy.fieldRecommended,
            ),
            Choice<Requiredness>(
              Requiredness.optional,
              localCopy.fieldOptional,
            ),
          ],
          onChanged: (Requiredness value) {
            ref.read(_fieldAddProvider.notifier).setRequiredness(value);
          },
        ),
        AppSwitchTile(
          title: localCopy.fieldAdvanced,
          description: view.advanced
              ? localCopy.fieldAdvancedHide
              : localCopy.fieldAdvancedShow,
          value: view.advanced,
          dense: true,
          onChanged: (bool on) {
            ref.read(_fieldAddProvider.notifier).setAdvanced(on);
          },
        ),
        if (view.advanced) ...<Widget>[
          FieldAdvancedSection(
            defaultValue: _defaultValue,
            unit: _unit,
            help: _help,
            requiredWhen: _requiredWhen,
            contextLevel: _contextLevel,
            inputMode: view.inputMode,
            autoFill: view.autoFill,
            autoFillUnavailable: _carriedSource(view.validation) != null,
            stickable: view.stickable,
            refine: view.refine,
            identity: view.identity,
            hidden: view.hidden,
            knownKeys: template.fields.map((FieldDef field) => field.fieldKey),
            labelsByKey: <String, String>{
              for (final FieldDef field in template.fields)
                field.fieldKey: field.label,
            },
            requiredWhenError: Copy.of(context).stateText(
              view.localizedRequiredWhenError,
              view.requiredWhenError,
            ),
            localizedRequiredWhenError: view.localizedRequiredWhenError,
            onInputMode: ref.read(_fieldAddProvider.notifier).setInputMode,
            onAutoFill: ref.read(_fieldAddProvider.notifier).setAutoFill,
            onStickable: ref.read(_fieldAddProvider.notifier).setStickable,
            onRefine: ref.read(_fieldAddProvider.notifier).setRefine,
            onIdentity: ref.read(_fieldAddProvider.notifier).setIdentity,
            onHidden: ref.read(_fieldAddProvider.notifier).setHidden,
            onRequiredWhenChanged: (String value) {
              ref
                  .read(_fieldAddProvider.notifier)
                  .validateRequiredWhen(value, template);
            },
          ),
          FieldValidationEditor(
            validation: view.validation,
            type: view.type,
            fieldKeys: <String>[
              for (final FieldDef field in template.fields) field.fieldKey,
            ],
            onChanged: ref.read(_fieldAddProvider.notifier).setValidation,
          ),
          if (choice)
            FieldOptionsEditor(
              options: view.options,
              onChanged: ref.read(_fieldAddProvider.notifier).setOptions,
            ),
        ],
      ],
      submitLabel: localCopy.save,
      onSubmit: () =>
          ref.read(_fieldAddProvider.notifier).save(context, this, template),
    );
  }

  TemplateDef? _pick(List<TemplateDef> rows) {
    for (final TemplateDef row in rows) {
      if (row.id == widget.templateId) {
        return row;
      }
    }
    return null;
  }

  /// Opens the lookup binding of the field being edited (task 010 step 6).
  void _bindDataset() {
    final String? key = widget.fieldKey;
    if (key == null) {
      return;
    }
    unawaited(
      context.push(
        RoutePaths.templateFieldLookup(
          widget.templateId,
          key,
          projectId: TemplateLocations.projectIdOf(context),
        ),
      ),
    );
  }

  void _hydrate(TemplateDef? template) {
    if (_hydrated || template == null) {
      return;
    }
    _hydrated = true;
    final String? key = widget.fieldKey;
    if (key == null) {
      return;
    }
    for (final FieldDef field in template.fields) {
      if (field.fieldKey != key) {
        continue;
      }
      _label.text = field.label;
      _defaultValue.text = field.defaultValue ?? '';
      _unit.text = field.unit ?? '';
      _help.text = field.helpText ?? '';
      _requiredWhen.text = field.requiredWhen ?? '';
      _contextLevel.text = field.contextLevel?.toString() ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(_fieldAddProvider.notifier).hydrate(field);
        }
      });
      return;
    }
  }
}

final class _FieldAddView {
  const _FieldAddView({
    this.advanced = false,
    this.keepAnyway = false,
    this.dirty = false,
    this.type = FieldType.text,
    this.requiredness = Requiredness.optional,
    this.inputMode = InputMode.any,
    this.autoFill,
    this.stickable = false,
    this.refine = false,
    this.identity = false,
    this.hidden = false,
    this.validation = const <String, Object?>{},
    this.options = const <Object>[],
    this.labelError,
    this.localizedLabelError,
    this.requiredWhenError,
    this.localizedRequiredWhenError,
    this.saveError,
    this.localizedSaveError,
    this.twoFactsWarning,
    this.localizedTwoFactsWarning,
  });

  final bool advanced;
  final bool keepAnyway;
  final bool dirty;
  final FieldType type;
  final Requiredness requiredness;
  final InputMode inputMode;
  final AutoFill? autoFill;
  final bool stickable;
  final bool refine;
  final bool identity;
  final bool hidden;
  final Map<String, Object?> validation;
  final List<Object> options;
  final String? labelError;

  /// Semantic error retained until the current locale renders the form.
  final LocalizedMessage? localizedLabelError;
  final String? requiredWhenError;

  /// Semantic error retained until the current locale renders the form.
  final LocalizedMessage? localizedRequiredWhenError;
  final String? saveError;

  /// Semantic error retained until the current locale renders the form.
  final LocalizedMessage? localizedSaveError;
  final String? twoFactsWarning;
  final LocalizedMessage? localizedTwoFactsWarning;

  _FieldAddView copyWith({
    bool? advanced,
    bool? keepAnyway,
    bool? dirty,
    FieldType? type,
    Requiredness? requiredness,
    InputMode? inputMode,
    AutoFill? autoFill,
    bool clearAutoFill = false,
    bool? stickable,
    bool? refine,
    bool? identity,
    bool? hidden,
    Map<String, Object?>? validation,
    List<Object>? options,
    String? labelError,
    LocalizedMessage? localizedLabelError,
    String? requiredWhenError,
    LocalizedMessage? localizedRequiredWhenError,
    String? saveError,
    LocalizedMessage? localizedSaveError,
    String? twoFactsWarning,
    LocalizedMessage? localizedTwoFactsWarning,
    bool clearWarning = false,
  }) {
    return _FieldAddView(
      advanced: advanced ?? this.advanced,
      keepAnyway: keepAnyway ?? this.keepAnyway,
      dirty: dirty ?? this.dirty,
      type: type ?? this.type,
      requiredness: requiredness ?? this.requiredness,
      inputMode: inputMode ?? this.inputMode,
      autoFill: clearAutoFill ? null : (autoFill ?? this.autoFill),
      stickable: stickable ?? this.stickable,
      refine: refine ?? this.refine,
      identity: identity ?? this.identity,
      hidden: hidden ?? this.hidden,
      validation: validation ?? this.validation,
      options: options ?? this.options,
      labelError: labelError,
      localizedLabelError: localizedLabelError,
      requiredWhenError: requiredWhenError,
      localizedRequiredWhenError: localizedRequiredWhenError,
      saveError: saveError,
      localizedSaveError: localizedSaveError,
      localizedTwoFactsWarning: clearWarning
          ? null
          : (localizedTwoFactsWarning ?? this.localizedTwoFactsWarning),
      twoFactsWarning: clearWarning
          ? null
          : (twoFactsWarning ?? this.twoFactsWarning),
    );
  }
}

class _FieldAdd extends Notifier<_FieldAddView> {
  @override
  _FieldAddView build() => const _FieldAddView();

  void hydrate(FieldDef field) {
    state = _FieldAddView(
      type: field.type,
      requiredness: field.requiredness,
      inputMode: field.inputMode,
      autoFill: field.autoFill,
      stickable: field.stickable,
      refine: field.refine,
      identity: field.identity,
      hidden: field.hidden,
      validation: field.validation,
      options: field.options,
    );
  }

  void setAdvanced(bool value) =>
      state = state.copyWith(advanced: value, dirty: true);
  void setType(FieldType type) =>
      state = state.copyWith(type: type, dirty: true);
  void setRequiredness(Requiredness value) =>
      state = state.copyWith(requiredness: value, dirty: true);
  void setInputMode(InputMode value) =>
      state = state.copyWith(inputMode: value, dirty: true);
  void setAutoFill(AutoFill? value) => state = state.copyWith(
    autoFill: value,
    clearAutoFill: value == null,
    validation: _withoutCarriedSource(state.validation),
    dirty: true,
  );
  void setStickable(bool value) =>
      state = state.copyWith(stickable: value, dirty: true);
  void setRefine(bool value) =>
      state = state.copyWith(refine: value, dirty: true);
  void setIdentity(bool value) =>
      state = state.copyWith(identity: value, dirty: true);
  void setHidden(bool value) =>
      state = state.copyWith(hidden: value, dirty: true);
  void setValidation(Map<String, Object?> value) => state = state.copyWith(
    validation: <String, Object?>{
      ...value,
      if (_carriedSource(state.validation) != null)
        '_tapture': state.validation['_tapture'],
    },
    dirty: true,
  );
  void setOptions(List<Object> value) =>
      state = state.copyWith(options: value, dirty: true);

  void keepAnyway() {
    state = state.copyWith(keepAnyway: true, clearWarning: true);
  }

  void validateRequiredWhen(String expression, TemplateDef template) {
    final Result<void> result = FieldAdvancedSection.validateRequiredWhen(
      expression,
      template.fields.map((FieldDef field) => field.fieldKey),
    );
    state = state.copyWith(
      dirty: true,
      requiredWhenError: switch (result) {
        Success<void>() => null,
        FailureResult<void>(:final Failure failure) => failure.message,
      },
      localizedRequiredWhenError: switch (result) {
        Success<void>() => null,
        FailureResult<void>(:final Failure failure) => failure.explanation,
      },
    );
  }

  /// Validates and stores the field. Completes with whether it was stored.
  Future<bool> save(
    BuildContext context,
    _FieldAddSheetState form,
    TemplateDef template,
  ) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final String label = form._label.text.trim();
    if (label.isEmpty) {
      state = state.copyWith(
        labelError: localCopy.nameRequired,
        localizedLabelError: LocalizedMessage.optional(localCopy.nameRequired),
      );
      return false;
    }
    final String key = widgetKey(form, template, label);
    if (FieldAddSheet.packsTwoFacts(label, key: key) && !state.keepAnyway) {
      state = state.copyWith(
        labelError: null,
        localizedLabelError: null,
        twoFactsWarning: Copy.fieldTwoFactsWarning,
        localizedTwoFactsWarning: Copy.messages.fieldTwoFactsWarning,
      );
      return false;
    }
    final Result<void> when = FieldAdvancedSection.validateRequiredWhen(
      form._requiredWhen.text,
      template.fields.map((FieldDef field) => field.fieldKey),
    );
    if (when is FailureResult<void>) {
      state = state.copyWith(
        requiredWhenError: Copy.of(context).failureMessage(when.failure),
        localizedRequiredWhenError: when.failure.explanation,
        advanced: true,
      );
      return false;
    }
    final FieldDef field = _toField(form, key, label);
    final Result<TemplateDef> result = await ref
        .read(templateRepositoryProvider)
        .save(_write(template, field));
    if (!context.mounted) {
      return result is Success<TemplateDef>;
    }
    switch (result) {
      case Success<TemplateDef>():
        GoRouter.maybeOf(
          context,
        )?.go(TemplateLocations.detail(context, template.id));
        return true;
      case FailureResult<TemplateDef>(:final Failure failure):
        state = state.copyWith(
          saveError: Copy.of(context).failureMessage(failure),
          localizedSaveError: failure.explanation,
        );
        return false;
    }
  }

  String widgetKey(
    _FieldAddSheetState form,
    TemplateDef template,
    String label,
  ) {
    final String? keep = form.widget.fieldKey;
    if (keep != null) {
      return keep;
    }
    return FieldAddSheet.uniqueKey(
      FieldAddSheet.keyFrom(label, unit: form._unit.text),
      template.fields.map((FieldDef field) => field.fieldKey),
    );
  }

  FieldDef _toField(_FieldAddSheetState form, String key, String label) {
    return FieldDef(
      fieldKey: key,
      label: label,
      type: state.type,
      requiredness: state.requiredness,
      defaultValue: _emptyToNull(form._defaultValue.text),
      unit: _emptyToNull(form._unit.text),
      helpText: _emptyToNull(form._help.text),
      inputMode: state.inputMode,
      stickable: state.stickable,
      contextLevel: int.tryParse(form._contextLevel.text.trim()),
      autoFill: state.autoFill,
      refine: state.refine,
      options: state.options,
      requiredWhen: _emptyToNull(form._requiredWhen.text),
      hidden: state.hidden,
      identity: state.identity,
      validation: state.validation,
    );
  }

  TemplateDef _write(TemplateDef template, FieldDef field) {
    final bool editing = template.fields.any(
      (FieldDef row) => row.fieldKey == field.fieldKey,
    );
    final List<FieldDef> fields = editing
        ? <FieldDef>[
            for (final FieldDef row in template.fields)
              row.fieldKey == field.fieldKey ? field : row,
          ]
        : <FieldDef>[...template.fields, field];
    final List<String> identity = <String>[
      for (final String key in template.identityFieldKeys)
        if (key != field.fieldKey) key,
      if (field.identity) field.fieldKey,
    ];
    return template.copyWith(
      version: template.version + 1,
      fields: fields,
      identityFieldKeys: identity,
    );
  }
}

/// Draft for one opening of the add/edit sheet (FE-STATE-09).
final NotifierProvider<_FieldAdd, _FieldAddView> _fieldAddProvider =
    NotifierProvider.autoDispose<_FieldAdd, _FieldAddView>(
      _FieldAdd.new,
      retry: (int _, Object _) => null,
    );

String? _emptyToNull(String raw) {
  final String trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

Object? _carriedSource(Map<String, Object?> validation) {
  final Object? attrs = validation['_tapture'];
  return attrs is Map ? attrs['autoFill'] : null;
}

Map<String, Object?> _withoutCarriedSource(Map<String, Object?> validation) {
  final Map<String, Object?> next = Map<String, Object?>.of(validation);
  final Object? raw = next['_tapture'];
  if (raw is Map) {
    final Map<String, Object?> attrs = Map<String, Object?>.from(raw)
      ..remove('autoFill')
      ..remove('autoFillTop');
    if (attrs.isEmpty) {
      next.remove('_tapture');
    } else {
      next['_tapture'] = attrs;
    }
  }
  return next;
}

final RegExp _startsLetter = RegExp(r'^[a-z]');
final RegExp _packed = RegExp(
  r'/|&| and |[A-Za-z]\+[A-Za-z]',
  caseSensitive: false,
);

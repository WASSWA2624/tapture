import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_checkbox_group.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/reference/reference.dart'
    show LookupBinding, NoMatchBehaviour, ReferenceDataset, datasetListProvider;
import 'package:tapture/features/templates/domain/field_def.dart';
import 'package:tapture/features/templates/domain/template_def.dart';
import 'package:tapture/features/templates/templates.dart'
    show templateRepositoryProvider;

import 'template_locations.dart';

/// Binds a template field to a project dataset (task 010 step 6): which
/// dataset, the ordered match columns, which dataset column fills which
/// template field, fuzzy matching and its threshold, and what happens when
/// nothing matches. The binding is the field's §12.2 `lookup` attribute.
class LookupBindingScreen extends ConsumerWidget {
  /// Creates the binding editor for [templateId] / [fieldKey].
  const LookupBindingScreen({
    super.key,
    required this.templateId,
    required this.fieldKey,
  });

  /// Template that owns the field.
  final String templateId;

  /// Field being bound.
  final String fieldKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final ({String templateId, String fieldKey}) target = (
      templateId: templateId,
      fieldKey: fieldKey,
    );
    final AsyncValue<_BindingView> value = ref.watch(_bindingProvider(target));
    return AppPage(
      key: const ValueKey<String>('route-field-lookup'),
      title: localCopy.datasetsLookupBinding,
      scrollable: false,
      body: AsyncValueView<_BindingView>(
        value: value,
        isEmpty: (_BindingView view) => view.template == null,
        empty: () => SingleChildScrollView(
          child: AppEmptyState(
            icon: AppIcons.template,
            headline: Copy.of(context).templatesEmptyHeadline,
            message: Copy.of(context).templatesEmptyMessage,
            actionLabel: Copy.of(context).navTemplates,
            onAction: () => context.go(TemplateLocations.root(context)),
          ),
        ),
        onRetry: () => ref.invalidate(_bindingProvider(target)),
        data: (_BindingView view) {
          final LocalizedCopy localCopy = Copy.of(context);

          final TemplateDef template = view.template!;
          final FieldDef? field = view.field;
          if (field == null) {
            return SingleChildScrollView(
              child: AppEmptyState(
                icon: AppIcons.fields,
                headline: localCopy.lookupFieldMissingHeadline,
                message: localCopy.lookupFieldMissingMessage,
                actionLabel: localCopy.templateFieldsTitle,
                onAction: () =>
                    context.go(TemplateLocations.detail(context, template.id)),
              ),
            );
          }
          final String? projectId =
              _present(template.projectId) ??
              _present(ref.watch(currentProjectProvider));
          final AsyncValue<List<ReferenceDataset>> datasets = projectId == null
              ? const AsyncValue<List<ReferenceDataset>>.data(
                  <ReferenceDataset>[],
                )
              : ref.watch(datasetListProvider(projectId));
          return AsyncValueView<List<ReferenceDataset>>(
            value: datasets,
            isEmpty: (List<ReferenceDataset> rows) => rows.isEmpty,
            empty: () => SingleChildScrollView(
              child: AppEmptyState(
                icon: AppIcons.dataset,
                headline: Copy.of(context).datasetsBindingEmptyHeadline,
                message: Copy.of(context).datasetsBindingEmptyMessage,
                actionLabel: projectId == null
                    ? Copy.of(context).navProjects
                    : Copy.of(context).datasetsImport,
                onAction: () => context.push(
                  projectId == null
                      ? RoutePaths.projects
                      : RoutePaths.projectDatasetImport(projectId),
                ),
              ),
            ),
            onRetry: projectId == null
                ? null
                : () => ref.invalidate(datasetListProvider(projectId)),
            data: (List<ReferenceDataset> rows) =>
                _BindingForm(target: target, view: view, datasets: rows),
          );
        },
      ),
    );
  }
}

/// The binding's fields, one control each, saved by the form's one action.
class _BindingForm extends ConsumerWidget {
  const _BindingForm({
    required this.target,
    required this.view,
    required this.datasets,
  });

  final ({String templateId, String fieldKey}) target;
  final _BindingView view;
  final List<ReferenceDataset> datasets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final _Binding controller = ref.read(_bindingProvider(target).notifier);
    final ReferenceDataset? dataset = _selected(datasets, view.datasetId);
    final FieldDef field = view.field!;
    final List<String> match = dataset == null
        ? const <String>[]
        : _matchOrder(dataset, view.matchColumns);
    final List<({String key, String label})> targets = _targets(view);
    final String? error = localCopy.stateText(view.localizedError, view.error);
    return AppForm(
      guardUnsaved: true,
      dirty: view.dirty,
      errors: <String>[?error],
      fields: <Widget>[
        if (field.type != FieldType.lookup)
          AppBanner(
            message: localCopy.lookupBecomesLookup,
            icon: AppIcons.info,
            tone: SnackTone.info,
          ),
        AppChoiceField<String>(
          label: localCopy.navDatasets,
          value: dataset?.id,
          options: <Choice<String>>[
            for (final ReferenceDataset row in datasets)
              Choice<String>(row.id, row.name),
          ],
          onChanged: (String? id) {
            if (id != null) {
              controller.chooseDataset(id);
            }
          },
        ),
        if (dataset != null) ...<Widget>[
          AppListTile(
            title: localCopy.lookupKeyColumn,
            subtitle: dataset.keyColumn,
            dense: true,
          ),
          AppListTile(
            title: localCopy.lookupMatchColumns,
            subtitle: localCopy.lookupMatchOrder(match),
            dense: true,
          ),
          AppCheckboxGroup<String>(
            label: localCopy.lookupMatchColumns,
            showLabel: false,
            options: <Choice<String>>[
              for (final String column in dataset.columns)
                Choice<String>(column, column),
            ],
            value: match.toSet(),
            onChanged: (Set<String> next) =>
                controller.chooseMatch(dataset, next),
          ),
          AppSectionHeader(title: localCopy.lookupFills, dense: true),
          for (final ({String key, String label}) fill in targets)
            AppChoiceField<String>(
              key: ValueKey<String>('lookup-fill-${fill.key}'),
              label: fill.label,
              value: view.fills[fill.key] ?? '',
              options: <Choice<String>>[
                Choice<String>('', localCopy.lookupNotFilled),
                for (final String column in dataset.columns)
                  Choice<String>(column, column),
              ],
              onChanged: (String? column) =>
                  controller.fill(fill.key, column ?? ''),
            ),
          AppSwitchTile(
            title: localCopy.datasetsFuzzyEnabled,
            value: view.fuzzy,
            onChanged: controller.setFuzzy,
          ),
          if (view.fuzzy)
            AppChoiceField<double>(
              label: localCopy.lookupFuzzyThreshold,
              value: view.threshold,
              options: <Choice<double>>[
                for (final double threshold in <double>{
                  ..._thresholds,
                  view.threshold,
                }.toList()..sort())
                  Choice<double>(
                    threshold,
                    localCopy.lookupThresholdLabel((threshold * 100).round()),
                  ),
              ],
              onChanged: (double? threshold) {
                if (threshold != null) {
                  controller.setThreshold(threshold);
                }
              },
            ),
          AppChoiceField<NoMatchBehaviour>(
            label: localCopy.datasetsOnNoMatch,
            value: view.onNoMatch,
            options: <Choice<NoMatchBehaviour>>[
              Choice<NoMatchBehaviour>(
                NoMatchBehaviour.leaveEmpty,
                localCopy.lookupNoMatchLeaveEmpty,
              ),
              Choice<NoMatchBehaviour>(
                NoMatchBehaviour.promptAddRow,
                localCopy.lookupNoMatchPromptAdd,
              ),
              Choice<NoMatchBehaviour>(
                NoMatchBehaviour.warn,
                localCopy.lookupNoMatchWarn,
              ),
            ],
            onChanged: (NoMatchBehaviour? behaviour) {
              if (behaviour != null) {
                controller.setOnNoMatch(behaviour);
              }
            },
          ),
        ],
      ],
      submitLabel: localCopy.datasetsSaveBinding,
      onSubmit: () async {
        final bool saved = await controller.save(datasets);
        if (saved && context.mounted) {
          // The form forgets its edits once this returns; leave after that.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              unawaited(Navigator.of(context).maybePop());
            }
          });
        }
        return saved;
      },
    );
  }
}

/// The binding being edited: the template and field it belongs to, and the
/// choices so far. [fills] runs template field → dataset column, one column
/// per field, as the screen shows it.
typedef _BindingView = ({
  TemplateDef? template,
  FieldDef? field,
  String? datasetId,
  List<String> matchColumns,
  Map<String, String> fills,
  bool fuzzy,
  double threshold,
  NoMatchBehaviour onNoMatch,
  String? error,
  LocalizedMessage? localizedError,
  bool dirty,
});

final class _Binding extends AsyncNotifier<_BindingView> {
  _Binding(this.target);

  final ({String templateId, String fieldKey}) target;

  @override
  Future<_BindingView> build() async {
    final Result<TemplateDef?> read = await ref
        .watch(templateRepositoryProvider)
        .byId(target.templateId);
    final TemplateDef? template = switch (read) {
      Success<TemplateDef?>(:final TemplateDef? value) => value,
      FailureResult<TemplateDef?>(:final Failure failure) => throw failure,
    };
    FieldDef? field;
    for (final FieldDef candidate in template?.fields ?? const <FieldDef>[]) {
      if (candidate.fieldKey == target.fieldKey) {
        field = candidate;
      }
    }
    // Reopening shows the stored binding, in either spelling, so saving
    // again never silently replaces it.
    final LookupBinding? stored = field == null
        ? null
        : LookupBinding.fromMap(field.lookup);
    return (
      template: template,
      field: field,
      datasetId: stored?.datasetId,
      matchColumns: stored?.matchColumns ?? const <String>[],
      fills: <String, String>{
        for (final MapEntry<String, String> fill
            in (stored?.fillMapping ?? const <String, String>{}).entries)
          fill.value: fill.key,
      },
      fuzzy: stored?.fuzzyEnabled ?? false,
      threshold: stored?.fuzzyThreshold ?? _defaultThreshold,
      onNoMatch: stored?.onNoMatch ?? NoMatchBehaviour.leaveEmpty,
      error: null,
      localizedError: null,
      dirty: false,
    );
  }

  /// Binds to dataset [id]; its own key and name become the match columns
  /// and no field is filled yet.
  void chooseDataset(String id) {
    _edit(
      (_BindingView view) => view.datasetId == id
          ? view
          : _with(
              view,
              datasetId: id,
              matchColumns: const <String>[],
              fills: const <String, String>{},
            ),
    );
  }

  /// Matches on [columns]; [dataset]'s key stays first, then the columns in
  /// the order they were added.
  void chooseMatch(ReferenceDataset dataset, Set<String> columns) {
    _edit((_BindingView view) {
      final List<String> current = _matchOrder(dataset, view.matchColumns);
      return _with(
        view,
        matchColumns: <String>[
          for (final String column in current)
            if (columns.contains(column)) column,
          for (final String column in dataset.columns)
            if (columns.contains(column) && !current.contains(column)) column,
        ],
      );
    });
  }

  /// Fills template field [fieldKey] from dataset [column]; '' fills
  /// nothing.
  void fill(String fieldKey, String column) {
    _edit((_BindingView view) {
      final Map<String, String> fills = Map<String, String>.of(view.fills);
      if (column.isEmpty) {
        fills.remove(fieldKey);
      } else {
        fills[fieldKey] = column;
      }
      return _with(view, fills: fills);
    });
  }

  /// Allows or stops fuzzy suggestions.
  void setFuzzy(bool on) =>
      _edit((_BindingView view) => _with(view, fuzzy: on));

  /// Offers fuzzy suggestions scoring at least [threshold].
  void setThreshold(double threshold) =>
      _edit((_BindingView view) => _with(view, threshold: threshold));

  /// What capture does when nothing matches.
  void setOnNoMatch(NoMatchBehaviour behaviour) =>
      _edit((_BindingView view) => _with(view, onNoMatch: behaviour));

  /// Stores the binding on the field, which becomes a lookup field. A
  /// mapping that fills a field the template does not define, or one field
  /// or column twice, is refused and says why. Completes with whether the
  /// template was saved.
  Future<bool> save(List<ReferenceDataset> datasets) async {
    final _BindingView? view = state.value;
    final TemplateDef? template = view?.template;
    if (view == null || template == null) {
      return false;
    }
    final ReferenceDataset? dataset = _selected(datasets, view.datasetId);
    if (dataset == null) {
      _refuse(view, Copy.messages.lookupPickDataset);
      return false;
    }
    final Map<String, String> fillMapping = <String, String>{};
    for (final MapEntry<String, String> fill in view.fills.entries) {
      if (fillMapping.containsKey(fill.value)) {
        _refuse(view, Copy.messages.lookupColumnTwice(fill.value));
        return false;
      }
      fillMapping[fill.value] = fill.key;
    }
    final LookupBinding binding = LookupBinding(
      datasetId: dataset.id,
      matchColumns: _matchOrder(dataset, view.matchColumns),
      fillMapping: fillMapping,
      fuzzyEnabled: view.fuzzy,
      fuzzyThreshold: view.threshold,
      onNoMatch: view.onNoMatch,
    );
    final LocalizedMessage? invalid = LookupBinding.validationMessage(
      binding: binding,
      templateFieldKeys: <String>{
        for (final FieldDef field in template.fields) field.fieldKey,
      },
    );
    if (invalid != null) {
      _refuse(view, invalid);
      return false;
    }
    final Result<TemplateDef> saved = await ref
        .read(templateRepositoryProvider)
        .save(
          template.copyWith(
            fields: <FieldDef>[
              for (final FieldDef field in template.fields)
                field.fieldKey == target.fieldKey
                    ? field.copyWith(
                        lookup: binding.toMap(),
                        type: FieldType.lookup,
                      )
                    : field,
            ],
          ),
        );
    if (!ref.mounted) {
      return false;
    }
    switch (saved) {
      case FailureResult<TemplateDef>(:final Failure failure):
        _refuse(view, failure.explanation);
        return false;
      case Success<TemplateDef>():
        state = AsyncData<_BindingView>(
          _with(
            view,
            error: null,
            localizedError: null,
            clearError: true,
            dirty: false,
          ),
        );
        return true;
    }
  }

  void _refuse(_BindingView view, LocalizedMessage reason) {
    state = AsyncData<_BindingView>(
      _with(view, error: reason.fallback, localizedError: reason),
    );
  }

  void _edit(_BindingView Function(_BindingView view) change) {
    final _BindingView? view = state.value;
    if (view == null) {
      return;
    }
    final _BindingView next = change(view);
    if (identical(next, view)) {
      return;
    }
    state = AsyncData<_BindingView>(_with(next, clearError: true, dirty: true));
  }

  _BindingView _with(
    _BindingView view, {
    String? datasetId,
    List<String>? matchColumns,
    Map<String, String>? fills,
    bool? fuzzy,
    double? threshold,
    NoMatchBehaviour? onNoMatch,
    String? error,
    LocalizedMessage? localizedError,
    bool clearError = false,
    bool? dirty,
  }) {
    return (
      template: view.template,
      field: view.field,
      datasetId: datasetId ?? view.datasetId,
      matchColumns: matchColumns ?? view.matchColumns,
      fills: fills ?? view.fills,
      fuzzy: fuzzy ?? view.fuzzy,
      threshold: threshold ?? view.threshold,
      onNoMatch: onNoMatch ?? view.onNoMatch,
      error: clearError ? null : (error ?? view.error),
      localizedError: clearError
          ? null
          : (localizedError ?? view.localizedError),
      dirty: dirty ?? view.dirty,
    );
  }
}

/// One field's binding draft. Auto-dispose: leaving the screen drops it.
final _bindingProvider = AsyncNotifierProvider.autoDispose
    .family<_Binding, _BindingView, ({String templateId, String fieldKey})>(
      _Binding.new,
      retry: (int _, Object _) => null,
    );

/// The dataset bound so far, else the first one offered.
ReferenceDataset? _selected(List<ReferenceDataset> datasets, String? id) {
  for (final ReferenceDataset dataset in datasets) {
    if (dataset.id == id) {
      return dataset;
    }
  }
  return datasets.isEmpty ? null : datasets.first;
}

/// [chosen] as tried: the key column first, then the rest in the order they
/// were added. With nothing chosen, the key then the first name column
/// (task 010 step 6).
List<String> _matchOrder(ReferenceDataset dataset, List<String> chosen) {
  final List<String> known = <String>[
    for (final String column in chosen)
      if (dataset.columns.contains(column)) column,
  ];
  if (known.isEmpty) {
    String? name;
    for (final String column in dataset.columns) {
      if (column != dataset.keyColumn &&
          column.toLowerCase().contains('name')) {
        name = column;
        break;
      }
    }
    return <String>[dataset.keyColumn, ?name];
  }
  return <String>[
    if (known.contains(dataset.keyColumn)) dataset.keyColumn,
    for (final String column in known)
      if (column != dataset.keyColumn) column,
  ];
}

/// The fields a dataset column can fill: every template field but the
/// bound one, then any target a stored binding names that the template
/// does not define, so it can be seen and cleared.
List<({String key, String label})> _targets(_BindingView view) {
  final List<FieldDef> fields = view.template?.fields ?? const <FieldDef>[];
  final Set<String> known = <String>{
    for (final FieldDef field in fields) field.fieldKey,
  };
  return <({String key, String label})>[
    for (final FieldDef field in fields)
      if (field.fieldKey != view.field?.fieldKey)
        (key: field.fieldKey, label: field.label),
    for (final String key in view.fills.keys)
      if (!known.contains(key)) (key: key, label: key),
  ];
}

/// The fuzzy thresholds offered; typical typos score between the lowest
/// two.
const List<double> _thresholds = <double>[0.6, 0.7, 0.8];

/// The threshold a new binding starts with.
const double _defaultThreshold = 0.8;

String? _present(String? id) => id == null || id.isEmpty ? null : id;

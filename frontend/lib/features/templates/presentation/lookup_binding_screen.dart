import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/reference/reference.dart';
import 'package:tapture/features/templates/domain/field_def.dart';
import 'package:tapture/features/templates/domain/template_def.dart';
import 'package:tapture/features/templates/templates.dart'
    show templateRepositoryProvider;

/// Binds a template field to a project dataset (§12.2 lookup attribute).
class LookupBindingScreen extends ConsumerStatefulWidget {
  /// Creates the binding editor for [templateId] / [fieldKey].
  const LookupBindingScreen({
    super.key,
    required this.templateId,
    required this.fieldKey,
    this.failure,
  });

  /// Template that owns the field.
  final String templateId;

  /// Field being bound.
  final String fieldKey;

  /// Injected failure for widget tests.
  final Failure? failure;

  @override
  ConsumerState<LookupBindingScreen> createState() =>
      _LookupBindingScreenState();
}

class _LookupBindingScreenState extends ConsumerState<LookupBindingScreen> {
  String? _datasetId;
  final List<String> _matchColumns = <String>[];
  final Map<String, String> _fillMapping = <String, String>{};
  bool _fuzzy = false;
  final double _threshold = 0.8;
  NoMatchBehaviour _onNoMatch = NoMatchBehaviour.leaveEmpty;
  Failure? _error;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final Failure? failure = widget.failure ?? _error;
    if (failure != null) {
      return AppPage(
        title: Copy.datasetsLookupBinding,
        showAppBar: false,
        body: AsyncValueView<void>(
          value: AsyncValue<void>.error(failure, StackTrace.empty),
          data: (_) => const SizedBox.shrink(),
          onRetry: () => setState(() => _error = null),
        ),
      );
    }
    final AsyncValue<TemplateDef?> template = ref.watch(
      _templateProvider(widget.templateId),
    );
    final String? projectId = ref.watch(currentProjectProvider);
    final AsyncValue<List<ReferenceDataset>> datasets = projectId == null
        ? const AsyncValue<List<ReferenceDataset>>.data(<ReferenceDataset>[])
        : ref.watch(datasetListProvider(projectId));
    return AppPage(
      title: Copy.datasetsLookupBinding,
      showAppBar: false,
      footer: AppPrimaryAction(
        label: Copy.datasetsSaveBinding,
        onPressed: _saving
            ? null
            : () => unawaited(_save(template.asData?.value)),
      ),
      body: AsyncValueView<TemplateDef?>(
        value: template,
        isEmpty: (TemplateDef? value) => value == null,
        empty: () => const AppEmptyState(
          icon: AppIcons.template,
          headline: Copy.templatesEmptyHeadline,
          message: Copy.templatesEmptyMessage,
        ),
        data: (TemplateDef? value) {
          if (value == null) {
            return const SizedBox.shrink();
          }
          final FieldDef? field = _fieldOf(value);
          if (field == null) {
            return const AppEmptyState(
              icon: AppIcons.unlink,
              headline: Copy.datasetsBrowserEmptyHeadline,
              message: Copy.datasetsBrowserEmptyMessage,
            );
          }
          return AsyncValueView<List<ReferenceDataset>>(
            value: datasets,
            isEmpty: (List<ReferenceDataset> rows) => rows.isEmpty,
            empty: () => AppEmptyState(
              icon: AppIcons.dataset,
              headline: Copy.datasetsBindingEmptyHeadline,
              message: Copy.datasetsBindingEmptyMessage,
              actionLabel: Copy.datasetsImport,
              onAction: projectId == null
                  ? null
                  : () =>
                        context.go(RoutePaths.projectDatasetImport(projectId)),
            ),
            data: (List<ReferenceDataset> rows) {
              final ReferenceDataset? selected = _selected(rows);
              return ListView(
                children: <Widget>[
                  AppChoiceField<String>(
                    label: Copy.navDatasets,
                    value: _datasetId ?? selected?.id,
                    options: <Choice<String>>[
                      for (final ReferenceDataset dataset in rows)
                        Choice<String>(dataset.id, dataset.name),
                    ],
                    onChanged: (String? id) {
                      setState(() {
                        _datasetId = id;
                        _matchColumns
                          ..clear()
                          ..addAll(_defaultMatch(rows, id));
                      });
                    },
                  ),
                  if (selected != null) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.all(Space.x4),
                      child: Text(selected.keyColumn),
                    ),
                    for (final String column in selected.columns)
                      CheckboxListTile(
                        title: Text(column),
                        value: _matchColumns.contains(column),
                        onChanged: (bool? on) {
                          setState(() {
                            if (on ?? false) {
                              if (!_matchColumns.contains(column)) {
                                _matchColumns.add(column);
                              }
                            } else {
                              _matchColumns.remove(column);
                            }
                          });
                        },
                      ),
                    for (final FieldDef target in value.fields)
                      AppChoiceField<String>(
                        label: target.label,
                        value: _fillTarget(selected, target.fieldKey),
                        options: <Choice<String>>[
                          const Choice<String>('', '—'),
                          for (final String column in selected.columns)
                            Choice<String>(column, column),
                        ],
                        onChanged: (String? column) {
                          setState(() {
                            _fillMapping.removeWhere(
                              (String _, String v) => v == target.fieldKey,
                            );
                            if (column != null && column.isNotEmpty) {
                              _fillMapping[column] = target.fieldKey;
                            }
                          });
                        },
                      ),
                    AppSwitchTile(
                      title: Copy.datasetsFuzzyEnabled,
                      value: _fuzzy,
                      onChanged: (bool value) => setState(() => _fuzzy = value),
                    ),
                    AppChoiceField<NoMatchBehaviour>(
                      label: Copy.datasetsOnNoMatch,
                      value: _onNoMatch,
                      options: <Choice<NoMatchBehaviour>>[
                        for (final NoMatchBehaviour behaviour
                            in NoMatchBehaviour.values)
                          Choice<NoMatchBehaviour>(behaviour, behaviour.name),
                      ],
                      onChanged: (NoMatchBehaviour? value) {
                        if (value != null) {
                          setState(() => _onNoMatch = value);
                        }
                      },
                    ),
                  ],
                  AppButton(
                    label: Copy.datasetsSaveBinding,
                    onPressed: () => unawaited(_save(value)),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  FieldDef? _fieldOf(TemplateDef template) {
    for (final FieldDef field in template.fields) {
      if (field.fieldKey == widget.fieldKey) {
        return field;
      }
    }
    return null;
  }

  ReferenceDataset? _selected(List<ReferenceDataset> rows) {
    final String? id = _datasetId;
    if (id == null) {
      return rows.isEmpty ? null : rows.first;
    }
    for (final ReferenceDataset dataset in rows) {
      if (dataset.id == id) {
        return dataset;
      }
    }
    return null;
  }

  List<String> _defaultMatch(List<ReferenceDataset> rows, String? id) {
    final ReferenceDataset? dataset = _selected(
      id == null
          ? rows
          : <ReferenceDataset>[
              for (final ReferenceDataset row in rows)
                if (row.id == id) row,
            ],
    );
    if (dataset == null) {
      return const <String>[];
    }
    final List<String> match = <String>[dataset.keyColumn];
    for (final String column in dataset.columns) {
      if (column != dataset.keyColumn &&
          (column.toLowerCase().contains('name') || match.length < 2)) {
        match.add(column);
        break;
      }
    }
    return match;
  }

  String? _fillTarget(ReferenceDataset dataset, String fieldKey) {
    for (final MapEntry<String, String> entry in _fillMapping.entries) {
      if (entry.value == fieldKey) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> _save(TemplateDef? template) async {
    if (template == null) {
      return;
    }
    final String projectKey = template.projectId ?? '';
    final AsyncValue<List<ReferenceDataset>> datasetsAsync = ref.read(
      datasetListProvider(projectKey),
    );
    final List<ReferenceDataset> datasets =
        datasetsAsync.asData?.value ?? const <ReferenceDataset>[];
    final ReferenceDataset? dataset = _selected(datasets);
    final String? id = _datasetId ?? dataset?.id;
    if (id == null || dataset == null) {
      setState(() {
        _error = const ValidationFailure(
          message: 'Pick a dataset before saving the binding.',
          recoveryAction: 'Choose a dataset and try again.',
        );
      });
      return;
    }
    final LookupBinding binding = LookupBinding(
      datasetId: id,
      matchColumns: _matchColumns.isEmpty
          ? <String>[dataset.keyColumn]
          : List<String>.of(_matchColumns),
      fillMapping: Map<String, String>.of(_fillMapping),
      fuzzyEnabled: _fuzzy,
      fuzzyThreshold: _threshold,
      onNoMatch: _onNoMatch,
    );
    final String? invalid = LookupBinding.validate(
      binding: binding,
      templateFieldKeys: <String>{
        for (final FieldDef field in template.fields) field.fieldKey,
      },
    );
    if (invalid != null) {
      setState(() {
        _error = ValidationFailure(
          message: invalid,
          recoveryAction: 'Fix the fill mapping and try again.',
        );
      });
      return;
    }
    setState(() => _saving = true);
    final List<FieldDef> fields = <FieldDef>[
      for (final FieldDef field in template.fields)
        if (field.fieldKey == widget.fieldKey)
          field.copyWith(lookup: binding.toMap(), type: FieldType.lookup)
        else
          field,
    ];
    final Result<TemplateDef> saved = await ref
        .read(templateRepositoryProvider)
        .save(template.copyWith(fields: fields));
    if (!mounted) {
      return;
    }
    switch (saved) {
      case FailureResult<TemplateDef>(:final Failure failure):
        setState(() {
          _saving = false;
          _error = failure;
        });
      case Success<TemplateDef>():
        context.pop();
    }
  }
}

final _templateProvider = FutureProvider.autoDispose
    .family<TemplateDef?, String>((Ref ref, String id) async {
      final Result<TemplateDef?> result = await ref
          .watch(templateRepositoryProvider)
          .byId(id);
      return switch (result) {
        Success<TemplateDef?>(:final TemplateDef? value) => value,
        FailureResult<TemplateDef?>() => null,
      };
    }, retry: (int _, Object _) => null);

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/state_refresh.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/templates/templates.dart';

import '../context.dart' show contextRepositoryProvider;
import '../domain/context_state.dart';
import '../domain/template_context_proposal.dart';
import 'context_providers.dart';

/// Chooses and orders a project's context levels from template field keys.
///
/// Every add, remove, move and edit is stored at once, so the page has no
/// save button: its one primary action adds the next level.
class ContextHierarchyScreen extends ConsumerStatefulWidget {
  /// Creates the hierarchy editor.
  const ContextHierarchyScreen({super.key, this.projectId});

  /// Owning project; the open project when null.
  final String? projectId;

  @override
  ConsumerState<ContextHierarchyScreen> createState() =>
      _ContextHierarchyScreenState();
}

class _ContextHierarchyScreenState extends ConsumerState<ContextHierarchyScreen>
    with StateRefresh {
  /// Levels on their way to the store, shown until it reports them back. A
  /// failed write drops them, so the page never shows unsaved levels.
  List<ContextLevel>? _pending;
  String? _templateId;
  Failure? _error;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final String? projectId =
        widget.projectId ?? ref.watch(currentProjectProvider);
    if (projectId == null || projectId.isEmpty) {
      return AppPage(
        title: localCopy.contextHierarchyTitle,
        showAppBar: false,
        body: AppEmptyState(
          icon: AppIcons.context,
          headline: localCopy.contextHierarchyEmptyHeadline,
          message: localCopy.contextHierarchyEmptyMessage,
          actionLabel: localCopy.navProjects,
          onAction: () => context.go(RoutePaths.projects),
        ),
      );
    }
    ref.listen<AsyncValue<ContextState>>(projectContextProvider(projectId), (
      AsyncValue<ContextState>? _,
      AsyncValue<ContextState> next,
    ) {
      if (!_saving && _pending != null && next.hasValue) {
        refresh(() => _pending = null);
      }
    });
    final AsyncValue<ContextState> stored = ref.watch(
      projectContextProvider(projectId),
    );
    final AsyncValue<List<TemplateDef>> templates = ref.watch(
      contextTemplatesProvider(projectId),
    );
    final ContextState? state = stored.asData?.value;
    final List<ContextLevel>? levels =
        _pending ?? (state == null ? null : orderedLevels(state));
    return AppPage(
      title: localCopy.contextHierarchyTitle,
      showAppBar: false,
      scrollable: false,
      footer: _footer(projectId, levels, templates.asData?.value),
      body: AsyncValueView<ContextState>(
        value: stored,
        onRetry: () => ref.invalidate(projectContextProvider(projectId)),
        data: (ContextState _) => _body(
          context,
          projectId,
          levels ?? const <ContextLevel>[],
          templates,
        ),
      ),
    );
  }

  /// The page's one primary action: take the template's levels while there
  /// are none and it declares some, otherwise add a level.
  Widget? _footer(
    String projectId,
    List<ContextLevel>? levels,
    List<TemplateDef>? templates,
  ) {
    final LocalizedCopy localCopy = Copy.of(context);

    if (levels == null || templates == null || templates.isEmpty) {
      return null;
    }
    final TemplateContextProposal proposal = _proposal(templates, projectId);
    if (levels.isEmpty &&
        !proposal.hasConflicts &&
        proposal.levels.isNotEmpty) {
      return AppPrimaryAction(
        label: localCopy.contextUseTemplateLevels,
        busy: _saving,
        onPressed: _saving
            ? null
            : () => unawaited(_useTemplateLevels(projectId, proposal.levels)),
      );
    }
    return AppPrimaryAction(
      label: localCopy.contextAddLevel,
      onPressed: _saving ? null : () => unawaited(_addLevel(projectId, levels)),
    );
  }

  /// One scroll view for the whole page, so nothing overflows in landscape
  /// or at 200 percent text (FE-RESP-06).
  Widget _body(
    BuildContext context,
    String projectId,
    List<ContextLevel> levels,
    AsyncValue<List<TemplateDef>> templates,
  ) {
    final LocalizedCopy localCopy = Copy.of(context);

    final double gutter = AppPage.gutter(context);
    final List<TemplateDef> loaded =
        templates.asData?.value ?? const <TemplateDef>[];
    final Failure? error = _error;
    return CustomScrollView(
      key: const ValueKey<String>('context-hierarchy-body'),
      slivers: <Widget>[
        if (error != null)
          SliverToBoxAdapter(
            child: AppBanner(
              message: error.message,
              icon: AppIcons.error,
              tone: SnackTone.error,
              onDismiss: () => refresh(() => _error = null),
            ),
          ),
        if (loaded.length > 1)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, Space.x3, gutter, Space.x0),
            sliver: SliverToBoxAdapter(
              child: AppChoiceField<String>(
                label: localCopy.contextLevelSource,
                value: _selectedTemplate(loaded).id,
                options: <Choice<String>>[
                  for (final TemplateDef template in loaded)
                    Choice<String>(template.id, template.name),
                ],
                onChanged: (String? id) => refresh(() => _templateId = id),
              ),
            ),
          ),
        if (levels.isEmpty)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            sliver: SliverToBoxAdapter(
              child: _proposalView(projectId, templates),
            ),
          )
        else ...<Widget>[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, Space.x2, gutter, Space.x0),
            sliver: SliverReorderableList(
              itemCount: levels.length,
              onReorderItem: (int from, int to) =>
                  unawaited(_move(projectId, levels, from, to)),
              proxyDecorator: (Widget child, int _, Animation<double> _) =>
                  Material(color: context.colors.surface, child: child),
              itemBuilder: (BuildContext context, int index) =>
                  _row(projectId, levels, index),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, Space.x3, gutter, Space.x3),
            sliver: SliverToBoxAdapter(
              child: AppListTile(
                key: const ValueKey<String>('context-presets-row'),
                leading: const Icon(AppIcons.preset),
                title: localCopy.contextPresetsTitle,
                subtitle: localCopy.contextPresetsHint,
                trailing: const Icon(AppIcons.open),
                onTap: () => unawaited(
                  context.push(RoutePaths.projectContextPresets(projectId)),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// A level row: drag by its handle, or move, edit and remove from its one
  /// menu, which screen-reader and switch users can reach (FE-A11Y-06).
  Widget _row(String projectId, List<ContextLevel> levels, int index) {
    final LocalizedCopy localCopy = Copy.of(context);

    final ContextLevel level = levels[index];
    final String name = contextLevelName(level);
    return AppListTile(
      key: ValueKey<String>(level.fieldKey),
      title: name,
      subtitle: localCopy.contextLevelRow(index + 1, level.fieldKey),
      leading: ReorderableDragStartListener(
        index: index,
        child: Icon(
          AppIcons.reorder,
          semanticLabel: localCopy.contextDragLevel(name),
        ),
      ),
      trailing: AppOverflowMenu(
        key: ValueKey<String>('context-level-menu-${level.fieldKey}'),
        items: <AppOverflowAction>[
          if (index > 0)
            AppOverflowAction(
              label: localCopy.fieldMoveUp(name),
              icon: AppIcons.moveUp,
              onTap: () =>
                  unawaited(_move(projectId, levels, index, index - 1)),
            ),
          if (index < levels.length - 1)
            AppOverflowAction(
              label: localCopy.fieldMoveDown(name),
              icon: AppIcons.moveDown,
              onTap: () =>
                  unawaited(_move(projectId, levels, index, index + 1)),
            ),
          AppOverflowAction(
            label: localCopy.templatesEdit,
            icon: AppIcons.edit,
            onTap: () => unawaited(_editLevel(projectId, levels, index)),
          ),
          AppOverflowAction(
            label: localCopy.contextRemoveLevel,
            icon: AppIcons.delete,
            onTap: () => unawaited(
              _persist(projectId, <ContextLevel>[
                for (final ContextLevel row in levels)
                  if (row.fieldKey != level.fieldKey) row,
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _proposalView(
    String projectId,
    AsyncValue<List<TemplateDef>> templates,
  ) {
    return AsyncValueView<List<TemplateDef>>(
      value: templates,
      onRetry: () => ref.invalidate(contextTemplatesProvider(projectId)),
      isEmpty: (List<TemplateDef> loaded) => loaded.isEmpty,
      empty: () => AppEmptyState(
        icon: AppIcons.template,
        headline: Copy.of(context).contextNoTemplatesHeadline,
        message: Copy.of(context).contextNoTemplatesMessage,
        actionLabel: Copy.of(context).contextOpenTemplates,
        onAction: () => _openTemplates(projectId),
      ),
      data: (List<TemplateDef> loaded) {
        final LocalizedCopy localCopy = Copy.of(context);

        final TemplateContextProposal proposal = _proposal(loaded, projectId);
        if (proposal.hasConflicts) {
          return AppEmptyState(
            icon: AppIcons.warning,
            headline: localCopy.contextTemplateConflictHeadline,
            message: localCopy.contextTemplateConflictMessage(
              proposal.conflicts.join(', '),
            ),
            actionLabel: localCopy.navTemplates,
            onAction: () => _openTemplates(projectId),
          );
        }
        if (proposal.levels.isEmpty) {
          return AppEmptyState(
            icon: AppIcons.context,
            headline: localCopy.contextNoDeclaredLevelsHeadline,
            message: localCopy.contextNoDeclaredLevelsMessage,
            actionLabel: localCopy.navTemplates,
            onAction: () => _openTemplates(projectId),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final TemplateContextLevelProposal level in proposal.levels)
              AppListTile(
                title: level.field.label,
                subtitle: localCopy.contextLevelRow(
                  level.level,
                  level.field.fieldKey,
                ),
              ),
            const SizedBox(height: Space.x3),
            AppButton(
              label: localCopy.contextAddLevel,
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: _saving
                  ? null
                  : () =>
                        unawaited(_addLevel(projectId, const <ContextLevel>[])),
            ),
            const SizedBox(height: Space.x3),
          ],
        );
      },
    );
  }

  void _openTemplates(String projectId) {
    unawaited(context.push(RoutePaths.projectTemplates(projectId)));
  }

  /// The template levels are suggested from: the one chosen, else the first
  /// that declares levels, else the first.
  TemplateDef _selectedTemplate(List<TemplateDef> templates) {
    for (final TemplateDef template in templates) {
      if (template.id == _templateId) {
        return template;
      }
    }
    for (final TemplateDef template in templates) {
      if (template.fields.any((FieldDef f) => (f.contextLevel ?? 0) > 0)) {
        return template;
      }
    }
    return templates.first;
  }

  TemplateContextProposal _proposal(
    List<TemplateDef> templates,
    String projectId,
  ) {
    return TemplateContextProposal.fromTemplates(<TemplateDef>[
      _selectedTemplate(templates),
    ], projectId: projectId);
  }

  Future<void> _useTemplateLevels(
    String projectId,
    List<TemplateContextLevelProposal> proposals,
  ) {
    return _persist(projectId, <ContextLevel>[
      for (final TemplateContextLevelProposal proposal in proposals)
        _levelFor(proposal.field, proposal.level - 1),
    ]);
  }

  /// Appends a level below every existing one: its order is one past the
  /// highest, so a removal earlier never leaves two levels sharing an order.
  Future<void> _addLevel(String projectId, List<ContextLevel> levels) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final FieldDef? picked = await _pickField(
      projectId,
      title: localCopy.contextAddLevel,
      used: <String>{for (final ContextLevel level in levels) level.fieldKey},
    );
    if (picked == null || !mounted) {
      return;
    }
    final int order = levels.isEmpty
        ? 0
        : levels.map((ContextLevel level) => level.order).reduce(math.max) + 1;
    await _persist(projectId, <ContextLevel>[
      ...levels,
      _levelFor(picked, order),
    ]);
  }

  Future<void> _editLevel(
    String projectId,
    List<ContextLevel> levels,
    int index,
  ) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final ContextLevel current = levels[index];
    final FieldDef? picked = await _pickField(
      projectId,
      title: localCopy.templatesEdit,
      used: <String>{
        for (final ContextLevel level in levels)
          if (level.fieldKey != current.fieldKey) level.fieldKey,
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    final List<ContextLevel> next = List<ContextLevel>.of(levels);
    next[index] = _levelFor(picked, current.order);
    await _persist(projectId, next);
  }

  /// Moves the level at [from] to [to]; levels are renumbered top down.
  Future<void> _move(
    String projectId,
    List<ContextLevel> levels,
    int from,
    int to,
  ) {
    final List<ContextLevel> next = List<ContextLevel>.of(levels);
    final ContextLevel item = next.removeAt(from);
    next.insert(to, item);
    return _persist(projectId, <ContextLevel>[
      for (int i = 0; i < next.length; i++) next[i].copyWith(order: i),
    ]);
  }

  /// A template field the project does not use as a level yet, from the
  /// selected template, levels it declares first.
  Future<FieldDef?> _pickField(
    String projectId, {
    required String title,
    required Set<String> used,
  }) {
    return showAppSheet<FieldDef>(
      context,
      title: title,
      contentSized: true,
      builder: (BuildContext sheet) => Consumer(
        builder: (BuildContext sheet, WidgetRef ref, Widget? _) {
          return AsyncValueView<List<TemplateDef>>(
            value: ref.watch(contextTemplatesProvider(projectId)),
            onRetry: () => ref.invalidate(contextTemplatesProvider(projectId)),
            isEmpty: (List<TemplateDef> loaded) => loaded.isEmpty,
            empty: () => AppEmptyState(
              icon: AppIcons.template,
              headline: Copy.of(sheet).contextNoTemplatesHeadline,
              message: Copy.of(sheet).contextNoTemplatesMessage,
              actionLabel: Copy.of(sheet).contextOpenTemplates,
              onAction: () {
                Navigator.pop(sheet);
                _openTemplates(projectId);
              },
            ),
            data: (List<TemplateDef> loaded) {
              final LocalizedCopy localCopy = Copy.of(sheet);

              final List<FieldDef> available = _available(loaded, used);
              if (available.isEmpty) {
                return AppEmptyState(
                  icon: AppIcons.context,
                  headline: localCopy.contextNoEligibleFieldsHeadline,
                  message: localCopy.contextNoEligibleFieldsMessage,
                  actionLabel: localCopy.navTemplates,
                  onAction: () {
                    Navigator.pop(sheet);
                    _openTemplates(projectId);
                  },
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final FieldDef field in available)
                    AppListTile(
                      title: field.label,
                      subtitle: (field.contextLevel ?? 0) <= 0
                          ? field.fieldKey
                          : localCopy.contextLevelRow(
                              field.contextLevel!,
                              field.fieldKey,
                            ),
                      onTap: () => Navigator.pop(sheet, field),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<FieldDef> _available(List<TemplateDef> templates, Set<String> used) {
    final Set<String> seen = <String>{...used};
    return <FieldDef>[
      for (final FieldDef field in _selectedTemplate(templates).fields)
        if (seen.add(field.fieldKey)) field,
    ]..sort((FieldDef left, FieldDef right) {
      final int leftLevel = left.contextLevel ?? 1 << 30;
      final int rightLevel = right.contextLevel ?? 1 << 30;
      final int byLevel = leftLevel.compareTo(rightLevel);
      return byLevel != 0 ? byLevel : left.sortOrder.compareTo(right.sortOrder);
    });
  }

  ContextLevel _levelFor(FieldDef field, int order) {
    final Object? datasetId = field.lookup['datasetId'];
    return ContextLevel(
      fieldKey: field.fieldKey,
      order: order,
      label: field.label,
      datasetId: datasetId is String ? datasetId : null,
    );
  }

  /// Stores [next] at once. A failure keeps the stored levels on screen and
  /// says why in a banner above them.
  Future<void> _persist(String projectId, List<ContextLevel> next) async {
    refresh(() {
      _pending = next;
      _saving = true;
      _error = null;
    });
    final Result<ContextState> result = await ref
        .read(contextRepositoryProvider)
        .saveHierarchy(projectId, next);
    if (!mounted) {
      return;
    }
    refresh(() {
      _saving = false;
      switch (result) {
        case FailureResult<ContextState>(:final Failure failure):
          _error = failure;
          _pending = null;
        case Success<ContextState>():
          break;
      }
    });
  }
}

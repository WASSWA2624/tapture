import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/templates/templates.dart';

import '../context.dart' show contextRepositoryProvider;
import '../domain/context_state.dart';
import '../domain/template_context_proposal.dart';
import 'context_providers.dart';
import 'pinned_fields_sheet.dart';

/// Project-owned templates used by both proposals and the add-level sheet.
final contextHierarchyTemplatesProvider =
    StreamProvider.family<List<TemplateDef>, String>((
      Ref ref,
      String projectId,
    ) {
      return ref.watch(templateRepositoryProvider).watchByProject(projectId);
    }, retry: (int _, Object _) => null);

/// Chooses and orders a project's context levels from template field keys.
class ContextHierarchyScreen extends ConsumerStatefulWidget {
  /// Creates the hierarchy editor.
  const ContextHierarchyScreen({super.key, this.projectId, this.failure});

  /// Owning project.
  final String? projectId;

  /// Injected failure for tests.
  final Failure? failure;

  @override
  ConsumerState<ContextHierarchyScreen> createState() =>
      _ContextHierarchyScreenState();
}

class _ContextHierarchyScreenState
    extends ConsumerState<ContextHierarchyScreen> {
  List<ContextLevel> _levels = <ContextLevel>[];
  bool _loaded = false;
  Failure? _error;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final Failure? failure = widget.failure ?? _error;
    final String? projectId =
        widget.projectId ?? ref.watch(currentProjectProvider);
    if (failure != null) {
      return AppPage(
        title: Copy.contextHierarchyTitle,
        showAppBar: false,
        body: AsyncValueView<void>(
          value: AsyncValue<void>.error(failure, StackTrace.empty),
          data: (_) => const SizedBox.shrink(),
          onRetry: () => setState(() => _error = null),
        ),
      );
    }
    if (projectId == null || projectId.isEmpty) {
      return const AppPage(
        title: Copy.contextHierarchyTitle,
        showAppBar: false,
        body: AppEmptyState(
          icon: Icons.account_tree_outlined,
          headline: Copy.contextHierarchyEmptyHeadline,
          message: Copy.contextHierarchyEmptyMessage,
        ),
      );
    }
    final AsyncValue<ContextState> state = ref.watch(
      projectContextProvider(projectId),
    );
    final AsyncValue<List<TemplateDef>> templates = ref.watch(
      contextHierarchyTemplatesProvider(projectId),
    );
    state.whenData((ContextState value) {
      if (!_loaded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _loaded) {
            return;
          }
          setState(() {
            _levels = List<ContextLevel>.of(value.levels);
            _loaded = true;
          });
        });
      }
    });
    return AppPage(
      title: Copy.contextHierarchyTitle,
      showAppBar: false,
      scrollable: false,
      footer: AppPrimaryAction(
        label: Copy.contextSaveHierarchy,
        onPressed: _saving ? null : () => unawaited(_save(projectId)),
      ),
      body: Column(
        children: <Widget>[
          AppListTile(
            title: Copy.contextPinnedTitle,
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                showPinnedFieldsSheet(context: context, projectId: projectId),
          ),
          Expanded(
            child: _levels.isEmpty
                ? _proposalView(context, projectId, templates)
                : ReorderableListView.builder(
                    itemCount: _levels.length,
                    onReorderItem: (int oldIndex, int newIndex) {
                      setState(() {
                        final ContextLevel item = _levels.removeAt(oldIndex);
                        _levels.insert(newIndex, item);
                        _levels = <ContextLevel>[
                          for (int i = 0; i < _levels.length; i++)
                            _levels[i].copyWith(order: i),
                        ];
                      });
                      unawaited(_persist(projectId));
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final ContextLevel level = _levels[index];
                      return AppListTile(
                        key: ValueKey<String>(level.fieldKey),
                        title: level.label.isEmpty
                            ? level.fieldKey
                            : level.label,
                        subtitle: Copy.contextLevelRow(
                          index + 1,
                          level.fieldKey,
                        ),
                        trailing: IconButton(
                          tooltip: Copy.contextRemoveLevel,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            setState(() {
                              _levels = <ContextLevel>[
                                for (final ContextLevel row in _levels)
                                  if (row.fieldKey != level.fieldKey) row,
                              ];
                              _levels = <ContextLevel>[
                                for (int i = 0; i < _levels.length; i++)
                                  _levels[i].copyWith(order: i),
                              ];
                            });
                            unawaited(_persist(projectId));
                          },
                        ),
                      );
                    },
                  ),
          ),
          TextButton(
            onPressed: () => unawaited(_addLevel(projectId)),
            child: const Text(Copy.contextAddLevel),
          ),
        ],
      ),
    );
  }

  Widget _proposalView(
    BuildContext context,
    String projectId,
    AsyncValue<List<TemplateDef>> templates,
  ) {
    return templates.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object _, StackTrace _) => AppEmptyState(
        icon: Icons.error_outline,
        headline: Copy.contextTemplateFailureHeadline,
        message: Copy.contextTemplateFailureMessage,
        actionLabel: Copy.queueRetry,
        onAction: () =>
            ref.invalidate(contextHierarchyTemplatesProvider(projectId)),
      ),
      data: (List<TemplateDef> loaded) {
        if (loaded.isEmpty) {
          return AppEmptyState(
            icon: Icons.article_outlined,
            headline: Copy.contextNoTemplatesHeadline,
            message: Copy.contextNoTemplatesMessage,
            actionLabel: Copy.contextOpenTemplates,
            onAction: () => context.push(_projectTemplates(projectId)),
          );
        }
        final TemplateContextProposal proposal =
            TemplateContextProposal.fromTemplates(loaded, projectId: projectId);
        if (proposal.hasConflicts) {
          return AppEmptyState(
            icon: Icons.warning_amber_outlined,
            headline: Copy.contextTemplateConflictHeadline,
            message: Copy.contextTemplateConflictMessage(
              proposal.conflicts.join(', '),
            ),
            actionLabel: Copy.contextOpenTemplates,
            onAction: () => context.push(_projectTemplates(projectId)),
          );
        }
        if (proposal.levels.isEmpty) {
          return AppEmptyState(
            icon: Icons.account_tree_outlined,
            headline: Copy.contextNoDeclaredLevelsHeadline,
            message: Copy.contextNoDeclaredLevelsMessage,
            actionLabel: Copy.contextOpenTemplates,
            onAction: () => context.push(_projectTemplates(projectId)),
          );
        }
        return ListView(
          children: <Widget>[
            for (final TemplateContextLevelProposal level in proposal.levels)
              AppListTile(
                title: level.field.label,
                subtitle: Copy.contextLevelRow(
                  level.level,
                  level.field.fieldKey,
                ),
              ),
            AppPrimaryAction(
              label: Copy.contextUseTemplateLevels,
              onPressed: () =>
                  unawaited(_useTemplateLevels(projectId, proposal.levels)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _useTemplateLevels(
    String projectId,
    List<TemplateContextLevelProposal> proposals,
  ) async {
    setState(() {
      _levels = <ContextLevel>[
        for (int index = 0; index < proposals.length; index++)
          ContextLevel(
            fieldKey: proposals[index].field.fieldKey,
            order: index,
            label: proposals[index].field.label,
            datasetId: proposals[index].field.lookup['datasetId'] is String
                ? proposals[index].field.lookup['datasetId']! as String
                : null,
          ),
      ];
    });
    await _persist(projectId);
  }

  Future<void> _addLevel(String projectId) async {
    final Result<List<TemplateDef>> templates = await _templates(projectId);
    final List<FieldDef> fields = <FieldDef>[];
    Failure? loadFailure;
    switch (templates) {
      case FailureResult<List<TemplateDef>>(:final Failure failure):
        loadFailure = failure;
      case Success<List<TemplateDef>>(:final List<TemplateDef> value):
        for (final TemplateDef template in value) {
          fields.addAll(template.fields);
        }
    }
    final Set<String> used = <String>{
      for (final ContextLevel level in _levels) level.fieldKey,
    };
    final List<FieldDef> available =
        <FieldDef>[
          for (final FieldDef field in fields)
            if (!used.contains(field.fieldKey)) field,
        ]..sort((FieldDef left, FieldDef right) {
          final int leftLevel = left.contextLevel ?? 1 << 30;
          final int rightLevel = right.contextLevel ?? 1 << 30;
          final int byLevel = leftLevel.compareTo(rightLevel);
          return byLevel != 0
              ? byLevel
              : left.sortOrder.compareTo(right.sortOrder);
        });
    if (!mounted) {
      return;
    }
    final FieldDef? picked = await showAppSheet<FieldDef>(
      context,
      title: Copy.contextAddLevel,
      builder: (BuildContext context) {
        if (loadFailure != null) {
          return AppEmptyState(
            icon: Icons.error_outline,
            headline: Copy.contextTemplateFailureHeadline,
            message: loadFailure.message,
          );
        }
        if (fields.isEmpty) {
          return const AppEmptyState(
            icon: Icons.article_outlined,
            headline: Copy.contextNoTemplatesHeadline,
            message: Copy.contextNoTemplatesMessage,
          );
        }
        if (available.isEmpty) {
          return const AppEmptyState(
            icon: Icons.account_tree_outlined,
            headline: Copy.contextNoEligibleFieldsHeadline,
            message: Copy.contextNoEligibleFieldsMessage,
          );
        }
        return ListView(
          children: <Widget>[
            for (final FieldDef field in available)
              AppListTile(
                title: field.label,
                subtitle: field.contextLevel == null || field.contextLevel! <= 0
                    ? field.fieldKey
                    : Copy.contextLevelRow(field.contextLevel!, field.fieldKey),
                onTap: () => Navigator.pop(context, field),
              ),
          ],
        );
      },
    );
    if (picked == null) {
      return;
    }
    final Object? datasetId = picked.lookup['datasetId'];
    setState(() {
      _levels = <ContextLevel>[
        ..._levels,
        ContextLevel(
          fieldKey: picked.fieldKey,
          order: _levels.length,
          label: picked.label,
          datasetId: datasetId is String ? datasetId : null,
        ),
      ];
    });
    await _persist(projectId);
  }

  Future<Result<List<TemplateDef>>> _templates(String projectId) async {
    try {
      final List<TemplateDef> list = await ref
          .read(templateRepositoryProvider)
          .watchByProject(projectId)
          .first;
      return Success<List<TemplateDef>>(list);
    } on Object catch (error) {
      return FailureResult<List<TemplateDef>>(
        StorageFailure(message: error.toString(), recoveryAction: 'Try again.'),
      );
    }
  }

  Future<void> _persist(String projectId) => _save(projectId);

  Future<void> _save(String projectId) async {
    setState(() => _saving = true);
    final Result<ContextState> result = await ref
        .read(contextRepositoryProvider)
        .saveHierarchy(projectId, _levels);
    if (!mounted) {
      return;
    }
    switch (result) {
      case FailureResult<ContextState>(:final Failure failure):
        setState(() {
          _saving = false;
          _error = failure;
        });
      case Success<ContextState>():
        setState(() => _saving = false);
    }
  }
}

String _projectTemplates(String projectId) {
  return RoutePaths.projectTemplates(projectId);
}

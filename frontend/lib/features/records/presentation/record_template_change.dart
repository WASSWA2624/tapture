import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/templates/templates.dart'
    show FieldDef, TemplateDef;

import '../domain/record_entry.dart';
import '../domain/record_value.dart';
import '../domain/template_change_plan.dart';
import 'record_providers.dart';
import 'record_template_change_controller.dart';

/// Moves a saved record to another template of its project (task 014 step
/// 5), showing first what the move does to every value: which carry over by
/// field key, which are kept as retired, which fields start empty and which
/// retired values come back. Nothing changes until Change template is
/// pressed; no value is ever deleted, and an approved record is warned that
/// it goes back to review.
final class RecordTemplateChange extends ConsumerStatefulWidget {
  /// Creates the sheet's body for record [recordId] of project [projectId].
  const RecordTemplateChange({
    super.key,
    required this.projectId,
    required this.recordId,
  });

  /// The project whose templates the record may move to.
  final String projectId;

  /// The record being moved.
  final String recordId;

  /// Opens the template change of record [recordId] as a sheet, or a side
  /// panel on expanded windows (FE-CONS-05). Once the record has moved, the
  /// sheet closes and a snack says so, and that the record is back in
  /// review when it was approved. Dismissing it changes nothing.
  static Future<void> show(
    BuildContext context, {
    required String projectId,
    required String recordId,
  }) async {
    final BuildContext host = _snackHost(context);
    final _Moved? moved = await showAppSheet<_Moved>(
      context,
      title: Copy.recordTemplateChangeTitle,
      builder: (BuildContext _) =>
          RecordTemplateChange(projectId: projectId, recordId: recordId),
    );
    if (moved == null || !host.mounted) {
      return;
    }
    showAppSnack(
      host,
      Copy.recordTemplateChanged(backToReview: moved.backToReview),
      tone: SnackTone.success,
    );
  }

  @override
  ConsumerState<RecordTemplateChange> createState() =>
      _RecordTemplateChangeState();
}

class _RecordTemplateChangeState extends ConsumerState<RecordTemplateChange> {
  @override
  Widget build(BuildContext context) {
    final AsyncValue<RecordEntry?> entry = ref.watch(
      recordEntryProvider(widget.recordId),
    );
    final AsyncValue<List<TemplateDef>> templates = ref.watch(
      recordTemplateChangeChoicesProvider(widget.projectId),
    );
    return AsyncValueView<RecordEntry?>(
      value: entry,
      onRetry: () => ref.invalidate(recordEntryProvider(widget.recordId)),
      isEmpty: (RecordEntry? loaded) => loaded == null,
      empty: () => const AppEmptyState(
        icon: AppIcons.records,
        headline: Copy.recordTemplateChangeGoneHeadline,
        message: Copy.recordTemplateChangeGoneMessage,
      ),
      data: (RecordEntry? loaded) {
        final RecordEntry record = loaded!;
        return AsyncValueView<List<TemplateDef>>(
          value: templates,
          onRetry: () => ref.invalidate(
            recordTemplateChangeChoicesProvider(widget.projectId),
          ),
          isEmpty: (List<TemplateDef> all) => _choicesFor(record, all).isEmpty,
          empty: () => AppEmptyState(
            icon: AppIcons.template,
            headline: Copy.recordTemplateChangeEmptyHeadline,
            message: Copy.recordTemplateChangeEmptyMessage,
            actionLabel: Copy.recordTemplateChangeEmptyAction,
            onAction: _openTemplates,
          ),
          data: (List<TemplateDef> all) => _body(record, all),
        );
      },
    );
  }

  Widget _body(RecordEntry record, List<TemplateDef> all) {
    final RecordTemplateChangeState state = ref.watch(
      recordTemplateChangeControllerProvider(widget.recordId),
    );
    final RecordTemplateChangeController controller = ref.read(
      recordTemplateChangeControllerProvider(widget.recordId).notifier,
    );
    final List<TemplateDef> choices = _choicesFor(record, all);
    final TemplateDef? current = _find(all, record.templateId);
    final String? targetId = state.targetId;
    final TemplateDef? target = targetId == null ? null : _find(all, targetId);
    final AsyncValue<TemplateChangePlan>? plan = target == null
        ? null
        : ref.watch(
            recordTemplateChangePlanProvider((
              recordId: record.id,
              templateId: target.id,
            )),
          );
    final Failure? failure = state.failure;
    final AppColors colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.x3,
        Space.x0,
        Space.x3,
        Space.x3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: ListView(
              key: const ValueKey<String>('record-template-change-body'),
              children: <Widget>[
                if (current != null) ...<Widget>[
                  Text(
                    Copy.recordTemplateChangeCurrent(current.name),
                    style: AppText.caption.copyWith(color: colors.onSurface),
                  ),
                  const SizedBox(height: Space.x2),
                ],
                if (record.status == RecordStatus.approved) ...<Widget>[
                  const AppBanner(
                    message: Copy.recordTemplateChangeApprovedNotice,
                    icon: AppIcons.warning,
                    tone: SnackTone.warning,
                  ),
                  const SizedBox(height: Space.x2),
                ],
                const AppSectionHeader(
                  title: Copy.recordTemplateChangeChoose,
                  dense: true,
                ),
                for (final TemplateDef choice in choices)
                  AppListTile(
                    key: ValueKey<String>(
                      'template-change-choice-${choice.id}',
                    ),
                    title: choice.name,
                    subtitle: Copy.fieldsCount(choice.fields.length),
                    selected: choice.id == target?.id,
                    onTap: state.applying
                        ? null
                        : () => controller.choose(choice.id),
                  ),
                const SizedBox(height: Space.x3),
                if (target == null || plan == null)
                  Text(
                    Copy.recordTemplateChangeHint,
                    style: AppText.body.copyWith(color: colors.onSurface),
                  )
                else
                  AsyncValueView<TemplateChangePlan>(
                    value: plan,
                    onRetry: () => ref.invalidate(
                      recordTemplateChangePlanProvider((
                        recordId: record.id,
                        templateId: target.id,
                      )),
                    ),
                    data: (TemplateChangePlan loaded) => _TemplateChangePreview(
                      plan: loaded,
                      record: record,
                      from: current,
                      to: target,
                    ),
                  ),
              ],
            ),
          ),
          if (failure != null) ...<Widget>[
            const SizedBox(height: Space.x2),
            AppBanner(
              key: const ValueKey<String>('record-template-change-failure'),
              message: failure.message,
              icon: AppIcons.error,
              tone: SnackTone.error,
            ),
          ],
          const SizedBox(height: Space.x3),
          AppPrimaryAction(
            key: const ValueKey<String>('record-template-change-apply'),
            label: Copy.recordTemplateChangeApply,
            busy: state.applying,
            onPressed: plan?.hasValue ?? false
                ? () => unawaited(_apply(record))
                : null,
          ),
        ],
      ),
    );
  }

  /// Applies the chosen template. The sheet closes on success, carrying
  /// whether the record went back to review; a failure keeps it open with
  /// the reason beside the chosen template.
  Future<void> _apply(RecordEntry record) async {
    final NavigatorState navigator = Navigator.of(context);
    final Result<void> applied = await ref
        .read(recordTemplateChangeControllerProvider(widget.recordId).notifier)
        .apply();
    if (!mounted || applied is! Success<void>) {
      return;
    }
    navigator.pop<_Moved>((
      backToReview: record.status == RecordStatus.approved,
    ));
  }

  /// Closes the sheet and opens the project's templates, where another one
  /// can be added.
  void _openTemplates() {
    final GoRouter? router = GoRouter.maybeOf(context);
    Navigator.of(context).pop();
    if (router != null) {
      unawaited(
        router.push<void>(RoutePaths.projectTemplates(widget.projectId)),
      );
    }
  }
}

/// What the move does to each value, grouped the way the plan groups it,
/// every value named by its field's label and shown with what it holds.
final class _TemplateChangePreview extends StatelessWidget {
  const _TemplateChangePreview({
    required this.plan,
    required this.record,
    required this.from,
    required this.to,
  });

  final TemplateChangePlan plan;
  final RecordEntry record;
  final TemplateDef? from;
  final TemplateDef to;

  @override
  Widget build(BuildContext context) {
    final bool nothing =
        plan.mapped.isEmpty &&
        plan.retired.isEmpty &&
        plan.added.isEmpty &&
        plan.restored.isEmpty;
    if (nothing) {
      return Text(
        Copy.recordTemplateChangeNoValues,
        style: AppText.body.copyWith(color: context.colors.onSurface),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ..._section(
          'mapped',
          Copy.recordTemplateChangeMapped(plan.mapped.length),
          plan.mapped,
          labels: to,
        ),
        ..._section(
          'retired',
          Copy.recordTemplateChangeRetired(plan.retired.length),
          plan.retired,
          labels: from,
        ),
        if (plan.retired.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.x2),
          const AppBanner(
            message: Copy.recordTemplateChangeRetiredNotice,
            icon: AppIcons.info,
            tone: SnackTone.info,
          ),
        ],
        ..._section(
          'added',
          Copy.recordTemplateChangeAdded(plan.added.length),
          plan.added,
          labels: to,
          withValues: false,
        ),
        ..._section(
          'restored',
          Copy.recordTemplateChangeRestored(plan.restored.length),
          plan.restored,
          labels: to,
        ),
      ],
    );
  }

  /// One group of the preview: its heading and a row per field key, or
  /// nothing when the group is empty.
  List<Widget> _section(
    String group,
    String title,
    List<String> keys, {
    required TemplateDef? labels,
    bool withValues = true,
  }) {
    if (keys.isEmpty) {
      return const <Widget>[];
    }
    return <Widget>[
      AppSectionHeader(
        key: ValueKey<String>('template-change-$group'),
        title: title,
        dense: true,
      ),
      for (final String key in keys)
        AppListTile(
          key: ValueKey<String>('template-change-$group-$key'),
          title: _labelOf(key, labels),
          subtitle: withValues ? _valueOf(key) : null,
          dense: true,
        ),
    ];
  }

  /// The label [template] gives field [key], else the label the record's
  /// other template gives it, else the key itself.
  String _labelOf(String key, TemplateDef? template) {
    for (final TemplateDef? source in <TemplateDef?>[template, to, from]) {
      for (final FieldDef field in source?.fields ?? const <FieldDef>[]) {
        if (field.fieldKey == key && field.label.trim().isNotEmpty) {
          return field.label;
        }
      }
    }
    return key;
  }

  /// What the record holds for [key], or null when it holds nothing.
  String? _valueOf(String key) {
    final RecordValue? value = record.valueOf(key);
    final String text = value?.display ?? '';
    return text.isEmpty ? null : text;
  }
}

/// The templates [record] can move to: every template of its project but
/// the one it is on, in the order the project lists them.
List<TemplateDef> _choicesFor(RecordEntry record, List<TemplateDef> all) {
  return <TemplateDef>[
    for (final TemplateDef template in all)
      if (template.id != record.templateId) template,
  ];
}

TemplateDef? _find(List<TemplateDef> all, String id) {
  for (final TemplateDef template in all) {
    if (template.id == id) {
      return template;
    }
  }
  return null;
}

/// A context that outlives the sheet: the root navigator sits under the
/// app's scaffold messenger, so the snack lands where the operator is.
BuildContext _snackHost(BuildContext context) {
  return Navigator.maybeOf(context, rootNavigator: true)?.context ?? context;
}

/// What the sheet hands back once the record has moved.
typedef _Moved = ({bool backToReview});

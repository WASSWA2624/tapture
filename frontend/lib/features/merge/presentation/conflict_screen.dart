import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_card.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/show_app_text_prompt.dart';
import 'package:tapture/core/widgets/responsive/responsive_pair.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/conflict_choice.dart';
import '../domain/conflict_kind.dart';
import '../domain/field_conflict.dart';
import 'merge_controller.dart';
import 'merge_labels.dart';
import 'merge_view.dart';

/// One merge conflict at a time, "Conflict 3 of 7" (task 076, W21): the
/// record, what differs, and both sides with their device and time. The
/// bulk choices are second controls that confirm with their count
/// (FE-SIMP-07). A choice is only remembered; Merge writes it.
final class ConflictScreen extends ConsumerWidget {
  /// Creates the screen for [projectId]'s merge. [conflictId] opens that
  /// conflict; otherwise the first one still unsettled shows.
  const ConflictScreen({required this.projectId, this.conflictId, super.key});

  /// The project the package merges into.
  final String projectId;

  /// The conflict to show, when one was chosen from the preview.
  final String? conflictId;

  /// Keeps this device's side.
  static const ValueKey<String> keepMineKey = ValueKey<String>(
    'conflict-keep-mine',
  );

  /// Takes the incoming side.
  static const ValueKey<String> takeIncomingKey = ValueKey<String>(
    'conflict-take-incoming',
  );

  /// Keeps this device's side of every unsettled conflict.
  static const ValueKey<String> keepAllKey = ValueKey<String>(
    'conflict-keep-all',
  );

  /// Takes the incoming side of every unsettled conflict.
  static const ValueKey<String> takeAllKey = ValueKey<String>(
    'conflict-take-all',
  );

  /// Types a replacement value.
  static const ValueKey<String> typeValueKey = ValueKey<String>(
    'conflict-type-value',
  );

  /// Leaves this conflict for later.
  static const ValueKey<String> decideLaterKey = ValueKey<String>(
    'conflict-decide-later',
  );

  /// Keeps both divergent template shapes and their capture metadata.
  static const ValueKey<String> keepBothKey = ValueKey<String>(
    'conflict-keep-both',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<MergeView?> value = ref.watch(
      mergeControllerProvider(projectId),
    );
    final MergeView? view = value.asData?.value;
    final FieldConflict? shown = view == null ? null : _shown(view);
    final int total = view?.plan.conflicts.length ?? 0;
    final int index = shown == null
        ? 0
        : view!.plan.conflicts.indexOf(shown) + 1;
    return AppPage(
      key: const ValueKey<String>('route-project-merge-conflicts'),
      title: shown == null
          ? localCopy.mergePackage
          : localCopy.conflictProgress(index, total),
      body: AsyncValueView<MergeView?>(
        value: value,
        isEmpty: (MergeView? _) => shown == null,
        empty: () => AppEmptyState(
          icon: AppIcons.done,
          headline: Copy.of(context).mergePackage,
          message: Copy.of(context).mergeNothing,
        ),
        onRetry: () => ref.invalidate(mergeControllerProvider(projectId)),
        data: (MergeView? view) => _Conflict(
          conflict: shown!,
          view: view!,
          onChoose: (ConflictChoice choice) =>
              unawaited(_choose(context, ref, shown, choice)),
          onChooseAll: (ConflictChoice choice) =>
              unawaited(_chooseAll(context, ref, view, choice)),
        ),
      ),
    );
  }

  FieldConflict? _shown(MergeView view) {
    for (final FieldConflict conflict in view.plan.conflicts) {
      if (conflict.id == conflictId) {
        return conflict;
      }
    }
    final List<FieldConflict> unsettled = view.unsettled;
    return unsettled.isEmpty ? null : unsettled.first;
  }

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    FieldConflict conflict,
    ConflictChoice choice,
  ) {
    return _chooseValue(context, ref, conflict, choice);
  }

  Future<void> _chooseValue(
    BuildContext context,
    WidgetRef ref,
    FieldConflict conflict,
    ConflictChoice choice,
  ) async {
    final LocalizedCopy localCopy = Copy.of(context);

    String? typedValue;
    if (choice == ConflictChoice.typed) {
      final MergeController controller = ref.read(
        mergeControllerProvider(projectId).notifier,
      );
      typedValue = await showAppTextPrompt(
        context,
        title: localCopy.conflictTypeValue,
        label: conflict.fieldLabel.isEmpty
            ? localCopy.conflictCaptionLabel
            : conflict.fieldLabel,
        initialValue:
            ref
                .read(mergeControllerProvider(projectId))
                .value
                ?.typedValues[conflict.id] ??
            conflict.mine,
        validate: (String value) =>
            controller.validateTypedValue(conflict, value),
      );
      if (typedValue == null || !context.mounted) {
        return;
      }
    }
    ref
        .read(mergeControllerProvider(projectId).notifier)
        .choose(conflict.id, choice, typedValue: typedValue);
    final bool done =
        ref.read(mergeControllerProvider(projectId)).value?.unsettled.isEmpty ??
        true;
    if (conflictId != null || done) {
      context.pop();
    }
  }

  Future<void> _chooseAll(
    BuildContext context,
    WidgetRef ref,
    MergeView view,
    ConflictChoice choice,
  ) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final int n = view.unsettled.length;
    final bool incoming = choice == ConflictChoice.theirs;
    final bool confirmed = await showAppConfirm(
      context,
      title: incoming
          ? localCopy.mergeTakeAllIncoming(n)
          : localCopy.mergeKeepAllMine(n),
      message: localCopy.mergeBulkConfirm(n, incoming: incoming),
      confirmLabel: incoming
          ? localCopy.conflictTakeIncoming
          : localCopy.conflictKeepMine,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    ref.read(mergeControllerProvider(projectId).notifier).chooseAll(choice);
    context.pop();
  }
}

class _Conflict extends StatelessWidget {
  const _Conflict({
    required this.conflict,
    required this.view,
    required this.onChoose,
    required this.onChooseAll,
  });

  final FieldConflict conflict;
  final MergeView view;
  final ValueChanged<ConflictChoice> onChoose;
  final ValueChanged<ConflictChoice> onChooseAll;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool deletion =
        conflict.kind == ConflictKind.deletedThere ||
        conflict.kind == ConflictKind.deletedHere;
    final String mine = switch (conflict.kind) {
      ConflictKind.deletedThere => localCopy.conflictChanged,
      ConflictKind.deletedHere => localCopy.conflictDeleted,
      _ => _displayValue(conflict, conflict.mine, localCopy),
    };
    final String theirs = switch (conflict.kind) {
      ConflictKind.deletedThere => localCopy.conflictDeleted,
      ConflictKind.deletedHere => localCopy.conflictChanged,
      _ => _displayValue(conflict, conflict.theirs, localCopy),
    };
    final ConflictChoice? chosen = view.choices[conflict.id];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          conflict.recordLabel.isEmpty
              ? localCopy.mergeRecordUnnamed(conflict.recordId)
              : conflict.recordLabel,
          style: AppText.section,
        ),
        const SizedBox(height: Space.x1),
        Text(
          localCopy.conflictKind(conflict.kind.name, conflict.fieldLabel),
          style: AppText.bodyStrong,
        ),
        if (deletion) ...<Widget>[
          const SizedBox(height: Space.x1),
          Text(
            localCopy.conflictDeletion(conflict.kind.name),
            style: AppText.body,
          ),
        ],
        const SizedBox(height: Space.x3),
        ResponsivePair(
          matchesHeights: true,
          start: _Side(
            heading: localCopy.conflictThisDevice,
            value: mine,
            device: conflict.mineDevice,
            at: mergeInstant(conflict.mineAt),
          ),
          end: _Side(
            heading: localCopy.conflictIncoming,
            value: theirs,
            device: conflict.theirsDevice,
            at: mergeInstant(conflict.theirsAt),
          ),
        ),
        const SizedBox(height: Space.x4),
        ResponsivePair(
          stacksOnCompact: false,
          matchesHeights: true,
          start: AppButton(
            key: ConflictScreen.keepMineKey,
            label: localCopy.conflictKeepMine,
            icon: chosen == ConflictChoice.mine ? AppIcons.check : null,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: conflict.allowChooseOne
                ? () => onChoose(ConflictChoice.mine)
                : null,
          ),
          end: AppButton(
            key: ConflictScreen.takeIncomingKey,
            label: localCopy.conflictTakeIncoming,
            icon: chosen == ConflictChoice.theirs ? AppIcons.check : null,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: conflict.allowChooseOne
                ? () => onChoose(ConflictChoice.theirs)
                : null,
          ),
        ),
        const SizedBox(height: Space.x2),
        if (conflict.kind == ConflictKind.template)
          AppButton(
            key: ConflictScreen.keepBothKey,
            label: localCopy.duplicateKeepBoth,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () => onChoose(ConflictChoice.keepBoth),
          ),
        if (conflict.kind == ConflictKind.value ||
            conflict.kind == ConflictKind.caption)
          AppButton(
            key: ConflictScreen.typeValueKey,
            label: localCopy.conflictTypeValue,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () => onChoose(ConflictChoice.typed),
          ),
        const SizedBox(height: Space.x2),
        if (conflict.kind != ConflictKind.template)
          AppButton(
            key: ConflictScreen.decideLaterKey,
            label: localCopy.conflictDecideLater,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () => onChoose(ConflictChoice.later),
          ),
        if (view.unsettled.length > 1 &&
            view.unsettled.every(
              (FieldConflict c) => c.allowChooseOne,
            )) ...<Widget>[
          const SizedBox(height: Space.x4),
          Wrap(
            spacing: Space.x2,
            runSpacing: Space.x2,
            children: <Widget>[
              AppButton(
                key: ConflictScreen.keepAllKey,
                label: localCopy.mergeKeepAllMine(view.unsettled.length),
                variant: AppButtonVariant.text,
                onPressed: () => onChooseAll(ConflictChoice.mine),
              ),
              AppButton(
                key: ConflictScreen.takeAllKey,
                label: localCopy.mergeTakeAllIncoming(view.unsettled.length),
                variant: AppButtonVariant.text,
                onPressed: () => onChooseAll(ConflictChoice.theirs),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

String _displayValue(
  FieldConflict conflict,
  String encoded,
  LocalizedCopy copy,
) {
  if (conflict.kind != ConflictKind.template &&
      conflict.kind != ConflictKind.reference) {
    return encoded;
  }
  final Object? decoded = jsonDecode(encoded);
  if (decoded is! Map) return encoded;
  if (conflict.kind == ConflictKind.reference) {
    return decoded.entries
        .map((MapEntry<Object?, Object?> e) => '${e.key}: ${e.value}')
        .join('\n');
  }
  final Map<Object?, Object?> header = (decoded['header'] as Map)
      .cast<Object?, Object?>();
  final List<Object?> fields = (decoded['fields'] as List).cast<Object?>();
  return <String>[
    '${header['name'] ?? conflict.recordLabel} · v${header['version'] ?? 1}',
    for (final Map<Object?, Object?> field
        in fields.whereType<Map<Object?, Object?>>())
      '${field['label'] ?? field['field_key']}: ${copy.fieldTypeLabel('${field['type'] ?? 'text'}')}',
  ].join('\n');
}

class _Side extends StatelessWidget {
  const _Side({
    required this.heading,
    required this.value,
    required this.device,
    required this.at,
  });

  final String heading;
  final String value;
  final String device;
  final DateTime? at;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(heading, style: AppText.label),
          const SizedBox(height: Space.x1),
          Text(
            value.isEmpty ? localCopy.conflictEmpty : value,
            style: AppText.bodyStrong,
          ),
          const SizedBox(height: Space.x2),
          Text(localCopy.conflictWrittenBy(device, at), style: AppText.caption),
        ],
      ),
    );
  }
}

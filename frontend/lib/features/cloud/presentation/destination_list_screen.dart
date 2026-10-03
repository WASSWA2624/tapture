import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/destination_check.dart';
import 'destination_editor_sheet.dart';
import 'destination_labels.dart';
import 'destination_list_controller.dart';

/// Every configured destination, with add, edit, connection check and
/// removal (task 021 step 2). Each row names its type, folder and the
/// outcome of its last check; a destination is saved only after its check
/// succeeds, and removing one asks first and can be undone.
final class DestinationListScreen extends ConsumerWidget {
  /// Creates the page.
  const DestinationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<List<Destination>> destinations = ref.watch(
      destinationListProvider,
    );
    final bool canAdd =
        ref.watch(destinationKindsProvider).asData?.value.isNotEmpty ?? true;
    final Set<String> checking = ref.watch(destinationListControllerProvider);
    final bool listed = destinations.asData?.value.isNotEmpty ?? false;
    return AppPage(
      title: localCopy.destinationTitle,
      inset: false,
      footer: listed && canAdd
          ? AppPrimaryAction(
              key: const ValueKey<String>('destination-add'),
              label: localCopy.destinationAdd,
              onPressed: () => unawaited(_add(context)),
            )
          : null,
      body: AsyncValueView<List<Destination>>(
        value: destinations,
        onRetry: () => ref.invalidate(destinationListProvider),
        isEmpty: (List<Destination> rows) => rows.isEmpty,
        empty: () => canAdd
            ? AppEmptyState(
                icon: AppIcons.upload,
                headline: Copy.of(context).destinationEmptyHeadline,
                message: Copy.of(context).destinationEmptyMessage,
                actionLabel: Copy.of(context).destinationAdd,
                onAction: () => unawaited(_add(context)),
              )
            : AppEmptyState(
                icon: AppIcons.upload,
                headline: Copy.of(context).destinationUnavailableHeadline,
                message: Copy.of(context).destinationUnavailableMessage,
              ),
        data: (List<Destination> rows) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final Destination destination in rows)
              _row(
                context,
                ref,
                destination,
                checking: checking.contains(destination.id),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    WidgetRef ref,
    Destination destination, {
    required bool checking,
  }) {
    final LocalizedCopy localCopy = Copy.of(context);

    final DestinationCheck? check = DestinationCheck.decode(
      destination.lastCheck,
    );
    final String id = destination.id;
    return AppListTile(
      key: ValueKey<String>('destination-$id'),
      title: destination.label,
      subtitle: destinationSummary(
        destination,
        checking: checking,
        copy: localCopy,
      ),
      leading: Icon(
        check != null && !check.passed ? AppIcons.warning : AppIcons.upload,
      ),
      onTap: () => unawaited(_edit(context, destination)),
      trailing: AppOverflowMenu(
        key: ValueKey<String>('destination-actions-$id'),
        items: <AppOverflowAction>[
          AppOverflowAction(
            key: ValueKey<String>('destination-edit-$id'),
            label: localCopy.destinationEditAction,
            icon: AppIcons.edit,
            onTap: () => unawaited(_edit(context, destination)),
          ),
          AppOverflowAction(
            key: ValueKey<String>('destination-test-$id'),
            label: localCopy.destinationTest,
            icon: AppIcons.check,
            onTap: () => unawaited(_check(context, ref, destination)),
          ),
          AppOverflowAction(
            key: ValueKey<String>('destination-remove-$id'),
            label: localCopy.destinationRemove,
            icon: AppIcons.delete,
            onTap: () => unawaited(_remove(context, ref, destination)),
          ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final Destination? saved = await showDestinationEditor(context);
    if (saved != null && context.mounted) {
      showAppSnack(
        context,
        localCopy.destinationSaved(saved.label),
        tone: SnackTone.success,
      );
    }
  }

  Future<void> _edit(BuildContext context, Destination destination) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final Destination? saved = await showDestinationEditor(
      context,
      existing: destination,
    );
    if (saved != null && context.mounted) {
      showAppSnack(
        context,
        localCopy.destinationSaved(saved.label),
        tone: SnackTone.success,
      );
    }
  }

  Future<void> _check(
    BuildContext context,
    WidgetRef ref,
    Destination destination,
  ) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final Result<void> checked = await ref
        .read(destinationListControllerProvider.notifier)
        .check(destination);
    if (!context.mounted) {
      return;
    }
    switch (checked) {
      case Success<void>():
        showAppSnack(
          context,
          localCopy.destinationCheckPassed(destination.label),
          tone: SnackTone.success,
        );
      case FailureResult<void>(:final Failure failure):
        showAppSnack(
          context,
          Copy.of(context).failureMessage(failure),
          tone: SnackTone.error,
        );
    }
  }

  /// Asks once, then removes the row and its sign-in together. A
  /// half-finished removal says which half remains; a full one offers undo.
  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    Destination destination,
  ) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final DestinationListController controller = ref.read(
      destinationListControllerProvider.notifier,
    );
    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.destinationRemoveTitle,
      message: localCopy.destinationRemoveMessage,
      confirmLabel: localCopy.destinationRemove,
      destructive: true,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final BuildContext host = Navigator.of(
      context,
      rootNavigator: true,
    ).context;
    final Result<DestinationUndo> removed = await controller.remove(
      destination,
    );
    if (!host.mounted) {
      return;
    }
    switch (removed) {
      case FailureResult<DestinationUndo>(:final Failure failure):
        showAppSnack(
          host,
          Copy.of(host).failureMessage(failure),
          tone: SnackTone.error,
        );
      case Success<DestinationUndo>(:final DestinationUndo value):
        showAppSnack(
          host,
          localCopy.destinationRemoved(destination.label),
          undoLabel: localCopy.undo,
          onUndo: () => unawaited(_undo(host, destination, value)),
        );
    }
  }

  Future<void> _undo(
    BuildContext host,
    Destination destination,
    DestinationUndo undo,
  ) async {
    final LocalizedCopy localCopy = Copy.of(host);

    final Result<void> restored = await undo();
    if (!host.mounted) {
      return;
    }
    switch (restored) {
      case Success<void>():
        showAppSnack(
          host,
          localCopy.destinationRestored(destination.label),
          tone: SnackTone.success,
        );
      case FailureResult<void>(:final Failure failure):
        showAppSnack(
          host,
          Copy.of(host).failureMessage(failure),
          tone: SnackTone.error,
        );
    }
  }
}

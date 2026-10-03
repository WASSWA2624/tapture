import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

import 'record_delete_controller.dart';
import 'record_providers.dart';

/// Deletes records to the recycle bin (task 014 step 7, D12), for one record
/// or a whole selection.
///
/// The confirm names how many records and how long they stay restorable
/// (FE-SIMP-07). Each record is then deleted on its own, and a snack reports
/// the outcome with an undo that restores every record that was deleted
/// (FE-CONS-05). Nothing leaves storage: the files wait for the purge.
///
/// The widget is the icon control for a row, a page's bar or a bulk action
/// bar; [run] is the same flow for a menu entry.
final class RecordDeleteAction extends ConsumerWidget {
  /// Creates the control for the records [ids].
  const RecordDeleteAction({super.key, required this.ids, this.onDeleted});

  /// The records a press deletes. Empty disables the control.
  final List<String> ids;

  /// Called after a confirmed delete with what it did, for example to leave
  /// a deleted record's page or clear a selection.
  final ValueChanged<RecordDeleteOutcome>? onDeleted;

  /// Confirms, deletes every record in [ids] with [reason] on its tombstone,
  /// and reports the outcome in a snack with undo.
  ///
  /// Returns what the delete did, or null when nothing was asked or the
  /// operator cancelled. The snack and its undo still show when the widget
  /// behind [context] leaves the tree with the records it deleted.
  static Future<RecordDeleteOutcome?> run(
    BuildContext context,
    WidgetRef ref, {
    required List<String> ids,
    String reason = RecordDeleteController.operatorReason,
  }) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final List<String> targets = <String>{...ids}.toList();
    if (targets.isEmpty) {
      return null;
    }
    final RecordDeleteController controller = ref.read(
      recordDeleteControllerProvider.notifier,
    );
    final int days = ref.read(recordRetentionDaysProvider);
    final BuildContext host = _snackHost(context);
    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.recordsDeleteTitle(targets.length),
      message: localCopy.recordsDeleteMessage(
        records: targets.length,
        days: days,
      ),
      confirmLabel: localCopy.recordsDeleteConfirm,
      destructive: true,
    );
    if (!confirmed) {
      return null;
    }
    final RecordDeleteOutcome outcome = await controller.delete(
      targets,
      reason: reason,
    );
    if (host.mounted) {
      _reportDelete(host, controller, outcome);
    }
    return outcome;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool busy = ref.watch(recordDeleteControllerProvider);
    final String label = localCopy.recordsDeleteLabel(<String>{...ids}.length);
    return AppIconButton(
      icon: AppIcons.delete,
      semanticLabel: label,
      tooltip: label,
      onPressed: busy || ids.isEmpty
          ? null
          : () => unawaited(_press(context, ref)),
    );
  }

  Future<void> _press(BuildContext context, WidgetRef ref) async {
    final RecordDeleteOutcome? outcome = await run(context, ref, ids: ids);
    if (outcome != null) {
      onDeleted?.call(outcome);
    }
  }
}

/// A context that outlives the row, page or bar that started a delete: a
/// deleted record leaves its list, and its row with it. The root navigator
/// sits under the app's theme and scaffold messenger, so a snack shown from
/// it lands where the operator is looking.
BuildContext _snackHost(BuildContext context) {
  return Navigator.maybeOf(context, rootNavigator: true)?.context ?? context;
}

/// The snack after a delete: the count deleted with undo, a warning when
/// some failed, or an error when none was deleted.
void _reportDelete(
  BuildContext host,
  RecordDeleteController controller,
  RecordDeleteOutcome outcome,
) {
  final LocalizedCopy localCopy = Copy.of(host);

  final int deleted = outcome.succeeded.length;
  final int failed = outcome.failed.length;
  if (deleted == 0) {
    showAppSnack(
      host,
      _failureText(outcome, localCopy.recordsNotDeleted),
      tone: SnackTone.error,
    );
    return;
  }
  showAppSnack(
    host,
    failed == 0
        ? localCopy.recordsDeleted(deleted)
        : localCopy.recordsDeletedPartly(deleted: deleted, failed: failed),
    tone: failed == 0 ? SnackTone.info : SnackTone.warning,
    undoLabel: localCopy.undo,
    onUndo: () => unawaited(_undo(host, controller, outcome.succeeded)),
  );
}

/// Restores the records a delete moved to the bin, then says how it went.
Future<void> _undo(
  BuildContext host,
  RecordDeleteController controller,
  List<String> ids,
) async {
  final LocalizedCopy localCopy = Copy.of(host);

  final RecordDeleteOutcome outcome = await controller.restore(ids);
  if (!host.mounted) {
    return;
  }
  if (outcome.failed.isEmpty) {
    showAppSnack(
      host,
      localCopy.recordsRestored(outcome.succeeded.length),
      tone: SnackTone.success,
    );
    return;
  }
  showAppSnack(
    host,
    _failureText(outcome, localCopy.recordsNotRestored),
    tone: SnackTone.error,
  );
}

/// Why the records in [outcome] failed: one record's own failure message,
/// which says why, or [count] of them when several failed.
String _failureText(RecordDeleteOutcome outcome, String Function(int n) count) {
  if (outcome.succeeded.isEmpty && outcome.failed.length == 1) {
    final Failure failure = outcome.failed.values.single;
    return failure.message;
  }
  return count(outcome.failed.length);
}

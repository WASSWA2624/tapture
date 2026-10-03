import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/record_thumb.dart';

import '../domain/record_filter.dart';
import '../domain/record_photo.dart';
import '../domain/record_sort.dart';
import '../domain/record_summary.dart';
import 'record_delete_action.dart';
import 'record_selection.dart';
import 'records_list_controller.dart';
import 'records_page_providers.dart';

/// Row [index] of a project's records list, read from the page it falls in
/// (task 014 step 2): the record as an [AppListTile] with its number, name,
/// identifier, context, status and first photo (FE-CONS-06); a skeleton
/// while its page loads; why the page could not be read, with a tap to read
/// it again, when it failed.
///
/// Tap opens the record ([onOpen], else its page in the project); long-press
/// ticks it, and while any record is ticked a tap ticks too (FE-CONS-10).
/// Edit and delete sit at the end of the row, except in the [pane] and
/// while selecting.
final class RecordsListRow extends ConsumerWidget {
  /// Creates row [index] of [projectId]'s list under [criteria].
  const RecordsListRow({
    required this.projectId,
    required this.criteria,
    required this.index,
    this.pane = false,
    this.currentRecordId,
    this.onOpen,
    this.onShown,
    super.key,
  });

  /// A row every row of the list measures against: the tallest a row can be,
  /// with every slot filled. Laid out once, never shown or read.
  static Widget prototype({required bool pane}) => _PrototypeRow(pane: pane);

  /// The project whose records are listed.
  final String projectId;

  /// The filter and order the list reads its pages under.
  final RecordsListCriteria criteria;

  /// Where the row sits in the list, from 0.
  final int index;

  /// Whether the row sits in the narrow pane beside a record.
  final bool pane;

  /// The record open beside the list, marked as current.
  final String? currentRecordId;

  /// Opens a record by id. Null pushes the record's page in its project.
  final ValueChanged<String>? onOpen;

  /// Called once a row has been built, so Select all can tick the records
  /// the list has shown. Null for the measuring prototype.
  final ValueChanged<String>? onShown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int size = AppConstants.lists.pageSize;
    final ({String projectId, RecordFilter filter, RecordSort sort, int page})
    query = (
      projectId: projectId,
      filter: criteria.filter,
      sort: criteria.sort,
      page: index ~/ size,
    );
    final AsyncValue<List<RecordSummary>> page = ref.watch(
      recordsPageProvider(query),
    );
    final int offset = index % size;
    // A page being read again keeps showing what it held.
    final List<RecordSummary>? rows = page.value;
    if (rows != null && offset < rows.length) {
      return _SummaryRow(
        summary: rows[offset],
        projectId: projectId,
        pane: pane,
        current: rows[offset].id == currentRecordId,
        onOpen: onOpen,
        onShown: onShown,
      );
    }
    final Object? error = page.error;
    if (error != null) {
      return _PageFailedRow(
        failure: Failure.from(error),
        pane: pane,
        onRetry: () => ref.invalidate(recordsPageProvider(query)),
      );
    }
    return _SkeletonRow(pane: pane);
  }
}

/// A row whose page could not be read: why, and a tap to read it again.
class _PageFailedRow extends StatelessWidget {
  const _PageFailedRow({
    required this.failure,
    required this.pane,
    required this.onRetry,
  });

  final Failure failure;
  final bool pane;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return AppListTile(
      title: Copy.of(context).failureMessage(failure),
      subtitle: Copy.of(context).failureRecovery(failure) ?? localCopy.tryAgain,
      leading: Icon(
        AppIcons.error,
        color: context.colors.danger,
        size: Space.x6,
      ),
      dense: pane,
      onTap: onRetry,
    );
  }
}

/// One record as a list row.
class _SummaryRow extends ConsumerWidget {
  const _SummaryRow({
    required this.summary,
    required this.projectId,
    required this.pane,
    required this.current,
    required this.onOpen,
    required this.onShown,
  });

  final RecordSummary summary;
  final String projectId;
  final bool pane;
  final bool current;
  final ValueChanged<String>? onOpen;
  final ValueChanged<String>? onShown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final String id = summary.id;
    final bool selected = ref.watch(
      recordSelectionProvider(
        projectId,
      ).select((Set<String> ids) => ids.contains(id)),
    );
    final bool selecting = ref.watch(
      recordSelectionProvider(
        projectId,
      ).select((Set<String> ids) => ids.isNotEmpty),
    );
    final RecordPhoto? thumb = summary.thumb;
    final String subtitle = localCopy.recordsRowSubtitle(
      number: summary.number,
      identifier: summary.identifier,
      context: summary.contextLabel,
    );
    void toggle() {
      ref.read(recordSelectionProvider(projectId).notifier).toggle(id);
    }

    final Widget tile = AppListTile(
      key: ValueKey<String>('record-row-$id'),
      title: summary.name.trim().isNotEmpty
          ? summary.name
          : localCopy.recordsUntitled(summary.number),
      subtitle: subtitle.isEmpty ? null : subtitle,
      leading: thumb == null
          ? null
          : RecordThumb(
              sha256: thumb.sha256,
              storagePath: thumb.storagePath,
              quarterTurns: thumb.quarterTurns,
              hasCaption: thumb.hasCaption,
            ),
      status: AppStatusPill.badge(status: summary.status),
      dense: pane,
      selected: selected,
      current: current,
      onTap: selecting ? toggle : () => _open(context, id),
      onLongPress: toggle,
      trailing: pane || selecting
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppIconButton(
                  key: ValueKey<String>('record-edit-$id'),
                  icon: AppIcons.edit,
                  tooltip: localCopy.recordEdit,
                  semanticLabel: localCopy.recordEdit,
                  // The capture page edits photos and captions; values are
                  // edited from the record's page.
                  onPressed: () => unawaited(
                    context.push(
                      RoutePaths.projectRecordEdit(summary.projectId, id),
                    ),
                  ),
                ),
                const SizedBox(width: Space.x1),
                RecordDeleteAction(
                  key: ValueKey<String>('record-delete-$id'),
                  ids: <String>[id],
                ),
              ],
            ),
    );
    final ValueChanged<String>? note = onShown;
    if (note == null) {
      return tile;
    }
    return _ShownOnce(id: id, onShown: note, child: tile);
  }

  void _open(BuildContext context, String id) {
    final ValueChanged<String>? open = onOpen;
    if (open != null) {
      open(id);
      return;
    }
    unawaited(context.push(RoutePaths.projectRecord(summary.projectId, id)));
  }
}

/// Notes [id] once it has been built, and again when the row is reused for
/// a different record. The note runs after the frame, never during build.
class _ShownOnce extends StatefulWidget {
  const _ShownOnce({
    required this.id,
    required this.onShown,
    required this.child,
  });

  final String id;
  final ValueChanged<String> onShown;
  final Widget child;

  @override
  State<_ShownOnce> createState() => _ShownOnceState();
}

class _ShownOnceState extends State<_ShownOnce> {
  @override
  void initState() {
    super.initState();
    _note();
  }

  @override
  void didUpdateWidget(_ShownOnce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _note();
    }
  }

  void _note() {
    final String id = widget.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.id == id) {
        widget.onShown(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// What every row measures against: the tallest a row can be, with every
/// slot filled. Laid out once, never shown or read.
class _PrototypeRow extends StatelessWidget {
  const _PrototypeRow({required this.pane});

  final bool pane;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return AppListTile(
      title: localCopy.recordsUntitled(0),
      subtitle: localCopy.recordsRowSubtitle(number: 0),
      leading: const SizedBox.square(dimension: Sizes.minTapTarget),
      status: const AppStatusPill.badge(status: RecordStatus.needsReview),
      dense: pane,
      trailing: pane
          ? null
          : const SizedBox(
              width: Sizes.minTapTarget * 2 + Space.x1,
              height: Sizes.minTapTarget,
            ),
    );
  }
}

/// A row whose page is still loading: the row's shape, no content.
class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.pane});

  final bool pane;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AppColors colors = context.colors;
    return Semantics(
      label: localCopy.loading,
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Space.x4,
            vertical: pane ? Space.x1 : Space.x3,
          ),
          child: Row(
            children: <Widget>[
              SizedBox.square(
                dimension: Sizes.minTapTarget,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: Space.x3),
              Expanded(
                child: SizedBox(
                  height: Space.x4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

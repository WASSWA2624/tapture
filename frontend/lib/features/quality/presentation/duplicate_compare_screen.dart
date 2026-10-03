import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_card.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/record_thumb.dart';
import 'package:tapture/core/widgets/responsive/responsive_pair.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/records/records.dart' show RecordPhoto;

import '../domain/duplicate_choice.dart';
import '../domain/duplicate_pair_view.dart';
import '../domain/duplicate_resolution.dart';
import '../domain/duplicate_side.dart';
import 'duplicate_flow.dart';
import 'duplicates_controller.dart';
import 'quality_providers.dart';

/// Two records side by side (task 015): their photos, photo counts and
/// capture details, then only the fields that differ.
///
/// Updating the existing record is offered here and only here: the prompt
/// and the list lead to this screen, never straight to an override.
final class DuplicateCompareScreen extends ConsumerWidget {
  /// Creates the comparison of pair [pairId] in [projectId].
  const DuplicateCompareScreen({
    required this.projectId,
    required this.pairId,
    super.key,
  });

  /// The project both records belong to.
  final String projectId;

  /// The pair compared.
  final String pairId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<DuplicatePairView?> pair = ref.watch(
      duplicatePairProvider(pairId),
    );
    final DuplicatePairView? loaded = pair.asData?.value;
    final bool busy = ref.watch(duplicatesControllerProvider);
    return AppPage(
      key: const ValueKey<String>('route-duplicate-compare'),
      title: localCopy.duplicateCompareTitle,
      footer: loaded == null
          ? null
          : AppPrimaryAction(
              key: const ValueKey<String>('duplicate-compare-override'),
              label: localCopy.duplicateOverride,
              busy: busy,
              onPressed: busy ? null : () => unawaited(_override(context, ref)),
            ),
      body: AsyncValueView<DuplicatePairView?>(
        value: pair,
        loadingShape: SkeletonShape.detail,
        onRetry: () => ref.invalidate(duplicatePairProvider(pairId)),
        isEmpty: (DuplicatePairView? value) => value == null,
        empty: () => AppEmptyState(
          icon: AppIcons.duplicate,
          headline: Copy.of(context).duplicatesEmptyHeadline,
          message: Copy.of(context).duplicatePairGone,
          actionLabel: Copy.of(context).duplicateBackToList,
          onAction: () => context.go(RoutePaths.projectDuplicates(projectId)),
        ),
        data: (DuplicatePairView? value) => _Comparison(pair: value!),
      ),
    );
  }

  /// Confirms, then writes the new record's values and photos onto the
  /// existing one and leaves.
  Future<void> _override(BuildContext context, WidgetRef ref) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.duplicateOverrideConfirmTitle,
      message: localCopy.duplicateOverrideConfirmMessage,
      confirmLabel: localCopy.duplicateOverride,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    final bool done = await DuplicateFlow.apply(
      context,
      ref,
      pairId,
      const DuplicateResolution(DuplicateChoice.overrideExisting),
    );
    if (!done || !context.mounted) {
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.projectDuplicates(projectId));
    }
  }
}

class _Comparison extends StatelessWidget {
  const _Comparison({required this.pair});

  final DuplicatePairView pair;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ResponsivePair(
          stacksOnCompact: false,
          matchesHeights: true,
          start: _Side(
            key: const ValueKey<String>('duplicate-side-existing'),
            heading: localCopy.duplicateExistingRecord,
            side: pair.existing,
          ),
          end: _Side(
            key: const ValueKey<String>('duplicate-side-incoming'),
            heading: localCopy.duplicateNewRecord,
            side: pair.incoming,
          ),
        ),
        AppSectionHeader(title: localCopy.duplicateDifferingFields),
        if (pair.differences.isEmpty)
          AppBanner(
            message: localCopy.duplicateNoDifferenceMessage,
            icon: AppIcons.info,
            tone: SnackTone.info,
          )
        else
          for (final DuplicateDifference row in pair.differences)
            AppListTile(
              key: ValueKey<String>('duplicate-compare-${row.fieldKey}'),
              title: row.label,
              subtitle: localCopy.duplicateValueChange(
                row.existing,
                row.incoming,
              ),
            ),
      ],
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.heading, required this.side, super.key});

  final String heading;
  final DuplicateSide side;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AppColors colors = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            heading,
            style: AppText.label.copyWith(color: colors.onSurfaceMuted),
          ),
          const SizedBox(height: Space.x1),
          Text(
            DuplicateFlow.title(
              side.name,
              side.number,
              localizedCopy: Copy.of(context),
            ),
            style: AppText.bodyStrong.copyWith(color: colors.onSurface),
          ),
          Text(
            localCopy.duplicateCaptureDetail(
              side.capturedAt,
              side.capturedBy,
              side.contextLabel,
            ),
            style: AppText.caption.copyWith(color: colors.onSurfaceMuted),
          ),
          Text(
            localCopy.photosCount(side.photos.length),
            style: AppText.caption.copyWith(color: colors.onSurfaceMuted),
          ),
          if (side.photos.isNotEmpty) ...<Widget>[
            const SizedBox(height: Space.x2),
            Wrap(
              spacing: Space.x1,
              runSpacing: Space.x1,
              children: <Widget>[
                for (final RecordPhoto photo in side.photos)
                  RecordThumb(
                    sha256: photo.sha256,
                    storagePath: photo.storagePath,
                    quarterTurns: photo.quarterTurns,
                    hasCaption: photo.hasCaption,
                    semanticLabel: photo.caption.isEmpty
                        ? heading
                        : photo.caption,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

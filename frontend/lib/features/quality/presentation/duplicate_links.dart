import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_icons.dart';

import '../domain/duplicate_pair_view.dart';
import 'duplicate_flow.dart';
import 'quality_providers.dart';

/// A record's duplicate badges (task 015): one per record it is paired
/// with. A pair a person kept both of links to the other record; a pair
/// still waiting opens the duplicate prompt.
///
/// Shows nothing while there is nothing to link to.
final class DuplicateLinks extends ConsumerWidget {
  /// Creates the badges of [recordId] in [projectId].
  const DuplicateLinks({
    required this.projectId,
    required this.recordId,
    super.key,
  });

  /// The project the record belongs to.
  final String projectId;

  /// The record whose counterparts are shown.
  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final List<DuplicateCounterpart> counterparts =
        ref.watch(duplicateCounterpartsProvider(recordId)).value ??
        const <DuplicateCounterpart>[];
    if (counterparts.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: Space.x2),
      child: Wrap(
        spacing: Space.x2,
        runSpacing: Space.x1,
        children: <Widget>[
          for (final DuplicateCounterpart other in counterparts)
            AppChip(
              key: ValueKey<String>('duplicate-link-${other.pairId}'),
              icon: AppIcons.duplicate,
              label: other.resolved
                  ? localCopy.duplicateLinkedTo(
                      DuplicateFlow.title(
                        other.name,
                        other.number,
                        localizedCopy: Copy.of(context),
                      ),
                    )
                  : localCopy.duplicatePossibleOf(
                      DuplicateFlow.title(
                        other.name,
                        other.number,
                        localizedCopy: Copy.of(context),
                      ),
                    ),
              onTap: other.resolved
                  ? () => unawaited(
                      context.push(
                        RoutePaths.projectRecord(projectId, other.recordId),
                      ),
                    )
                  : () => unawaited(
                      DuplicateFlow.open(
                        context,
                        ref,
                        projectId: projectId,
                        pairId: other.pairId,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

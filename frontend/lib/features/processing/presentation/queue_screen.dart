import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../processing.dart';
import 'process_actions.dart';
import 'queue_providers.dart';

/// The queue: counts from queries, grouped by context.
class QueueScreen extends ConsumerWidget {
  /// Creates the queue. [projectId] limits the groups when set.
  const QueueScreen({super.key, this.projectId});

  /// When set, only this project's queue is shown.
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<QueueSnapshot> value = ref.watch(queueSnapshotProvider);
    return AppPage(
      title: Copy.queueTitle,
      scrollable: false,
      body: AsyncValueView<QueueSnapshot>(
        value: value,
        onRetry: () => ref.invalidate(queueSnapshotProvider),
        isEmpty: (QueueSnapshot snapshot) =>
            snapshot.unprocessed == 0 &&
            snapshot.queued == 0 &&
            snapshot.failed == 0 &&
            snapshot.groups.isEmpty,
        empty: () {
          return const AppEmptyState(
            icon: Icons.inbox_outlined,
            headline: Copy.queueEmptyHeadline,
            message: Copy.queueEmptyMessage,
          );
        },
        data: (QueueSnapshot snapshot) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('${Copy.queueUnprocessed} ${snapshot.unprocessed}'),
              Text('${Copy.queueQueued} ${snapshot.queued}'),
              Text('${Copy.queueFailed} ${snapshot.failed}'),
              ProcessActions(
                steps: const <ProgressStep>[],
                onProcessAll: snapshot.queued == 0 && snapshot.unprocessed == 0
                    ? null
                    : () {},
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.groups.length,
                  itemBuilder: (BuildContext context, int index) {
                    final QueueGroup group = snapshot.groups[index];
                    return AppListTile(
                      title: group.label,
                      subtitle: Copy.recordsCount(group.records),
                      onTap: () {},
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

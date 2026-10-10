import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart'
    show currentProjectProvider;

import 'records_list_controller.dart';
import 'records_list_view.dart';

/// The records list page (task 014 step 2): one project's records with
/// search, filters and sort, inside the project branch (`/projects/:id/records`).
///
/// Without [projectId] it lists the open project's records, and with no
/// project open it says so and offers to open one (FE-SIMP-11).
/// [initialStatus] is the route's `?filter=` status, such as the processing
/// notification's `needsReview`: it narrows the status filter for this
/// visit without changing what the project remembers.
final class RecordsListScreen extends ConsumerStatefulWidget {
  /// Creates the page for [projectId], or for the open project when null.
  const RecordsListScreen({this.projectId, this.initialStatus, super.key});

  /// The project whose records are listed. Null follows the open project.
  final String? projectId;

  /// The one status this visit lists, from the route. Null keeps the
  /// project's remembered filter.
  final RecordStatus? initialStatus;

  @override
  ConsumerState<RecordsListScreen> createState() => _RecordsListScreenState();
}

class _RecordsListScreenState extends ConsumerState<RecordsListScreen> {
  /// The project and status the route's filter was last applied to, so a
  /// rebuild never applies it twice and a new route applies it again.
  ({String projectId, RecordStatus status})? _applied;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final String? projectId =
        widget.projectId ?? ref.watch(currentProjectProvider);
    if (projectId == null) {
      return AppPage(
        key: const ValueKey<String>('route-records'),
        title: localCopy.navRecords,
        body: AppEmptyState(
          key: const ValueKey<String>('records-no-project'),
          icon: AppIcons.project,
          headline: localCopy.recordsNoProjectHeadline,
          message: localCopy.recordsNoProjectMessage,
          actionLabel: localCopy.recordsOpenProject,
          onAction: () => context.go(RoutePaths.projects),
        ),
      );
    }
    _narrowForVisit(projectId);
    return AppPage(
      key: const ValueKey<String>('route-records'),
      title: localCopy.navRecords,
      scrollable: false,
      inset: false,
      body: RecordsListView(projectId: projectId),
    );
  }

  /// Applies the route's status once per project and status, after the
  /// frame: a provider may not change while the tree builds. The first
  /// frame shows the list loading, so the unfiltered rows never show.
  void _narrowForVisit(String projectId) {
    final RecordStatus? status = widget.initialStatus;
    if (status == null) {
      return;
    }
    final ({String projectId, RecordStatus status}) visit = (
      projectId: projectId,
      status: status,
    );
    if (_applied == visit) {
      return;
    }
    _applied = visit;
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) {
        return;
      }
      ref
          .read(recordsListControllerProvider(projectId).notifier)
          .showOnly(status);
    });
  }
}

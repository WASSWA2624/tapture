import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_card.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;
import 'current_project.dart';

/// Open-project home: what to do next, with one primary capture action.
class ProjectHomeScreen extends ConsumerWidget {
  /// Creates the open-project home.
  const ProjectHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Project? details = ref.watch(currentProjectDetailsProvider);
    final AsyncValue<ProjectHomeView?> value = ref.watch(projectHomeProvider);
    final ProjectHomeView? view = value.asData?.value;
    return AppPage(
      key: const ValueKey<String>('route-project'),
      title: details?.name ?? Copy.navProjects,
      showAppBar: false,
      scrollable: false,
      footer: view == null
          ? null
          : AppPrimaryAction(
              label: Copy.continueCapturing,
              onPressed: () => context.go(_capture(view.project.id)),
            ),
      body: AsyncValueView<ProjectHomeView?>(
        value: value,
        isEmpty: (ProjectHomeView? loaded) => loaded == null,
        empty: () => AppEmptyState(
          icon: Icons.folder_open_outlined,
          headline: Copy.homeEmptyHeadline,
          message: Copy.homeEmptyMessage,
          actionLabel: Copy.navProjects,
          onAction: () => context.go(_projectsRoot),
        ),
        onRetry: () {
          ref.invalidate(projectListProvider);
          ref.invalidate(projectHomeCountsProvider);
        },
        data: (ProjectHomeView? loaded) => _HomeBody(view: loaded!),
      ),
    );
  }
}

/// Project, pinned context and pending counts for the home. Derived, never
/// stored (FE-STATE-06).
typedef ProjectHomeView = ({
  Project project,
  String context,
  ProjectHomeCounts counts,
});

/// Pinned context label on the home header. Defaults to the status-line
/// stub; 115 replaces the source. This file cannot import the status line
/// — that file imports the router.
final Provider<String> projectHomeContextProvider = Provider<String>((Ref _) {
  return Copy.statusNoContext;
});

/// Pending Review, Process, Export and Share counts for the open project.
final StreamProvider<ProjectHomeCounts> projectHomeCountsProvider =
    StreamProvider<ProjectHomeCounts>((Ref ref) {
      final String? id = ref.watch(currentProjectProvider);
      if (id == null) {
        return Stream<ProjectHomeCounts>.value(emptyProjectHomeCounts);
      }
      return ref.watch(projectRepositoryProvider).watchHome(id);
    }, retry: (int _, Object _) => null);

/// Combined home snapshot. Empty when no project is open; loading and
/// failure follow the list or the counts watch.
final Provider<AsyncValue<ProjectHomeView?>> projectHomeProvider =
    Provider<AsyncValue<ProjectHomeView?>>((Ref ref) {
      final Project? details = ref.watch(currentProjectDetailsProvider);
      final AsyncValue<List<ProjectListRow>> list = ref.watch(
        projectListProvider,
      );
      final AsyncValue<ProjectHomeCounts> counts = ref.watch(
        projectHomeCountsProvider,
      );
      final String context = ref.watch(projectHomeContextProvider);
      if (details == null) {
        return list.when(
          data: (List<ProjectListRow> _) {
            return const AsyncData<ProjectHomeView?>(null);
          },
          error: AsyncError<ProjectHomeView?>.new,
          loading: () => const AsyncLoading<ProjectHomeView?>(),
        );
      }
      return counts.when(
        data: (ProjectHomeCounts loaded) {
          return AsyncData<ProjectHomeView?>((
            project: details,
            context: context,
            counts: loaded,
          ));
        },
        error: AsyncError<ProjectHomeView?>.new,
        loading: () => const AsyncLoading<ProjectHomeView?>(),
      );
    });

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.view});

  final ProjectHomeView view;

  @override
  Widget build(BuildContext context) {
    final ProjectHomeCounts counts = view.counts;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(view.project.name, style: AppText.title),
          const SizedBox(height: Space.x1),
          Text(view.context, style: AppText.caption),
          const SizedBox(height: Space.x4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _CountCard(
                  cardKey: const ValueKey<String>('home-review'),
                  label: Copy.homeReview,
                  countLabel: Copy.homeReviewPending(counts.review),
                  onTap: () => context.go(_reviewList),
                ),
              ),
              const SizedBox(width: Space.x2),
              Expanded(
                child: _CountCard(
                  cardKey: const ValueKey<String>('home-process'),
                  label: Copy.homeProcess,
                  countLabel: Copy.homeProcessPending(counts.process),
                  onTap: () => context.go(_processList),
                ),
              ),
              const SizedBox(width: Space.x2),
              Expanded(
                child: _CountCard(
                  cardKey: const ValueKey<String>('home-export'),
                  label: Copy.homeExport,
                  countLabel: Copy.homeExportPending(counts.toExport),
                  onTap: () => context.go(_exportList),
                ),
              ),
              const SizedBox(width: Space.x2),
              Expanded(
                child: _CountCard(
                  cardKey: const ValueKey<String>('home-share'),
                  label: Copy.homeShare,
                  countLabel: Copy.homeSharePending(counts.toShare),
                  onTap: () => context.go(_shareList),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.cardKey,
    required this.label,
    required this.countLabel,
    required this.onTap,
  });

  final Key cardKey;
  final String label;
  final String countLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: cardKey,
      elevationLevel: 0,
      padding: const EdgeInsets.all(Space.x2),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: AppText.caption),
          const SizedBox(height: Space.x1),
          Text(
            countLabel,
            style: AppText.bodyStrong,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Must match [AppRoutes.capture]. This file cannot import `router.dart`.
String _capture(String id) {
  return '$_projectsRoot/${Uri.encodeComponent(id)}/$_captureSegment';
}

String _filtered(String root, String filter) {
  return Uri(
    path: root,
    queryParameters: <String, String>{_filterQuery: filter},
  ).toString();
}

/// Must match [AppRoutes] path helpers.
const String _projectsRoot = '/projects';
const String _recordsRoot = '/records';
const String _queueRoot = '/queue';
const String _exportsRoot = '/exports';
const String _captureSegment = 'capture';
const String _filterQuery = 'filter';
const String _reviewFilter = 'needsReview';
const String _processFilter = 'queued';
const String _exportFilter = 'approved';
const String _shareFilter = 'share';

final String _reviewList = _filtered(_recordsRoot, _reviewFilter);
final String _processList = _filtered(_queueRoot, _processFilter);
final String _exportList = _filtered(_recordsRoot, _exportFilter);
final String _shareList = _filtered(_exportsRoot, _shareFilter);

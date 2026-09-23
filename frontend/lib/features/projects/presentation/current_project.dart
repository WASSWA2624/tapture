import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/features/settings/settings.dart';

import '../domain/project_repository.dart';
import '../projects.dart' show projectRepositoryProvider;
import 'project_list_criteria.dart';
import 'project_list_filter.dart';

/// The single open-project id. Persists the choice, restores it on the
/// next launch, and is the source every project-scoped route reads
/// (FE-STATE-06).
final class CurrentProject extends Notifier<String?> {
  bool _openedThisSession = false;
  bool _launchConsumed = false;
  bool _resolved = false;

  /// Reads the persisted id, then confirms it still exists.
  @override
  String? build() {
    final SettingsStore store = ref.watch(projectSettingsStoreProvider);
    final String? persisted = store.read(SettingKeys.openProjectId);
    final ProjectRepository projects = ref.watch(projectRepositoryProvider);
    final StreamSubscription<List<Project>> sub = projects
        .watchAll(includeArchived: true)
        .listen((List<Project> rows) {
          unawaited(
            Future<void>.microtask(() {
              if (!ref.mounted) {
                return;
              }
              _resolve(store, rows);
            }),
          );
        });
    ref.onDispose(sub.cancel);
    return persisted;
  }

  /// Records [projectId] as the open project and persists it.
  void open(String projectId) {
    _openedThisSession = true;
    state = projectId;
    unawaited(_persist(projectId));
  }

  /// Clears the open project and the persisted id.
  void close() {
    _openedThisSession = true;
    state = null;
    unawaited(_persist(null));
  }

  /// One-shot launch resume. Returns the last project id, or null when
  /// none is open, the id has not resolved, or this was an in-session
  /// [open].
  String? consumeLaunchRestore() {
    if (_launchConsumed || _openedThisSession || !_resolved) {
      return null;
    }
    _launchConsumed = true;
    return state;
  }

  void _resolve(SettingsStore store, List<Project> rows) {
    final String? stored = store.read(SettingKeys.openProjectId);
    _resolved = true;
    if (stored == null) {
      return;
    }
    if (_exists(stored, rows)) {
      if (state != stored) {
        state = stored;
      }
      return;
    }
    unawaited(_persist(null));
    if (state == stored) {
      state = null;
    }
  }

  Future<void> _persist(String? id) async {
    final SettingsStore store = ref.read(projectSettingsStoreProvider);
    await store.write(SettingKeys.openProjectId, id);
  }

  bool _exists(String id, List<Project> rows) {
    for (final Project row in rows) {
      if (row.id == id) {
        return true;
      }
    }
    return false;
  }
}

/// Process-wide settings map [CurrentProject] persists to. [main] and
/// tests replace the empty fake so suites never open a database
/// (FE-TEST-03).
final Provider<SettingsStore> projectSettingsStoreProvider =
    Provider<SettingsStore>((Ref _) {
      return SettingsStore.fake();
    });

/// The open project id. Alias of [currentProjectProvider] so the
/// project-scope guard and status line keep one name.
final NotifierProvider<CurrentProject, String?> currentProjectProvider =
    NotifierProvider<CurrentProject, String?>(CurrentProject.new);

/// Same instance as [currentProjectProvider]. Kept so existing
/// `openProjectIdProvider` readers do not grow a second source.
final NotifierProvider<CurrentProject, String?> openProjectIdProvider =
    currentProjectProvider;

/// Active projects with counts for the landing list. Kept alive: the
/// status line and the list both watch it (FE-STATE-09). Archived rows
/// appear only when [projectListShowArchivedProvider] is on.
final StreamProvider<List<ProjectListRow>> projectListProvider =
    StreamProvider<List<ProjectListRow>>((Ref ref) {
      final bool includeArchived = ref.watch(projectListShowArchivedProvider);
      final ProjectListCriteria criteria = ref.watch(
        projectListCriteriaProvider,
      );
      return ref
          .watch(projectRepositoryProvider)
          .watchList(
            includeArchived:
                includeArchived ||
                criteria.statuses.contains(ProjectStatus.archived),
          );
    }, retry: (int _, Object _) => null);

/// How many active projects the Projects destination opens onto.
///
/// Derived from [projectListProvider] so the badge does not open a
/// second watch (FE-STATE-06). Archived rows are omitted even when the
/// landing list is showing them, so the number always matches the
/// default destination list.
final Provider<int> projectNavCountProvider = Provider<int>((Ref ref) {
  return ref
      .watch(projectListProvider)
      .maybeWhen(
        data: (List<ProjectListRow> rows) {
          int count = 0;
          for (final ProjectListRow row in rows) {
            if (row.project.status == ProjectStatus.active) {
              count += 1;
            }
          }
          return count;
        },
        orElse: () => 0,
      );
});

/// The open [Project], or null when none is open or the list has not
/// resolved it yet. Derived from [currentProjectProvider] and
/// [projectListProvider]; not a second stored copy (FE-STATE-06).
final Provider<Project?> currentProjectDetailsProvider = Provider<Project?>((
  Ref ref,
) {
  final String? id = ref.watch(currentProjectProvider);
  if (id == null) {
    return null;
  }
  final AsyncValue<List<ProjectListRow>> list = ref.watch(projectListProvider);
  return list.maybeWhen(
    data: (List<ProjectListRow> rows) {
      for (final ProjectListRow row in rows) {
        if (row.project.id == id) {
          return row.project;
        }
      }
      return null;
    },
    orElse: () => null,
  );
});

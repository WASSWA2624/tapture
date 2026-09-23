/// The projects feature: the projects records are filed under.
library;

export 'data/project_repository_impl.dart' show projectRepositoryProvider;
export 'domain/project.dart';
export 'domain/project_openable_file_lookup.dart';
export 'domain/project_settings.dart';
export 'domain/project_status.dart';
export 'presentation/current_project.dart'
    show
        currentProjectDetailsProvider,
        currentProjectProvider,
        openProjectIdProvider,
        projectListProvider,
        projectNavCountProvider,
        projectSettingsStoreProvider;
export 'presentation/project_list_actions.dart';
export 'presentation/project_list_criteria.dart';
export 'presentation/project_list_filter.dart'
    show
        projectListFilteredProvider,
        projectListSearchQueryProvider,
        projectListShowArchivedProvider;
export 'presentation/project_list_view.dart';
export 'presentation/project_open_externally_action.dart';

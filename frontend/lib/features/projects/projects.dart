/// The projects feature: the projects records are filed under.
library;

export 'data/project_repository_impl.dart' show projectRepositoryProvider;
export 'domain/project.dart';
export 'domain/project_settings.dart';
export 'domain/project_status.dart';
export 'presentation/current_project.dart'
    show
        currentProjectProvider,
        openProjectIdProvider,
        projectSettingsStoreProvider;

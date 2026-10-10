part of 'router.dart';

/// The type `route_guards.dart` is named for (FE-STR-06). The contract
/// publishes [RouteGuard] and [appGuards].
typedef RouteGuards = List<RouteGuard>;

/// One gate in the ordered redirect chain. Returns a location or null.
///
/// Takes [Ref] rather than [WidgetRef]: [WidgetRef] is sealed and needs a
/// widget, and guards must stay unit-testable without one (FE-STATE-04).
typedef RouteGuard = FutureOr<String?> Function(GoRouterState state, Ref ref);

/// Ordered redirect chain. Later tasks append a gate — sign-in, app lock —
/// as one entry rather than a second redirect.
List<RouteGuard> appGuards() {
  return <RouteGuard>[_appLock, _projectScope, _resumeIntended];
}

String? _appLock(GoRouterState state, Ref ref) {
  final String path = state.uri.path;
  if (path == AppRoutes.lock) {
    return null;
  }
  if (kDebugMode && path == WidgetGalleryScreen.route) {
    return null;
  }
  final AppLockSession session = ref.read(appLockSessionProvider);
  if (!session.enabled || session.unlocked) {
    return null;
  }
  return Uri(
    path: AppRoutes.lock,
    queryParameters: <String, String>{AppRoutes.fromQuery: _destination(state)},
  ).toString();
}

/// A project-scoped location needs an open project. A link that names a
/// project this device holds opens that project, so `/projects/<B>` never
/// renders the project that happened to be open. A link naming no known
/// project, with none open, diverts to the picker carrying the location.
Future<String?> _projectScope(GoRouterState state, Ref ref) async {
  if (state.metadata[_projectScopedKey] != true) {
    return null;
  }
  final String? open = ref.read(openProjectIdProvider);
  final String? named = state.pathParameters['projectId'];
  if (named != null) {
    final subscription = ref.listen(projectByIdProvider(named), (_, _) {});
    final Project? project;
    try {
      project = await ref.read(projectByIdProvider(named).future);
    } on Object {
      return AppRoutes.projects;
    } finally {
      subscription.close();
    }
    if (!ref.mounted) {
      return AppRoutes.projects;
    }
    if (project == null) {
      return AppRoutes.projects;
    }
    final String? recordId = state.pathParameters['recordId'];
    if (recordId != null) {
      final RecordEntry? record;
      try {
        record = (await ref.read(recordRepositoryProvider).byId(recordId))
            .getOrThrow();
      } on Object {
        return RoutePaths.projectRecords(named);
      }
      if (record == null ||
          record.status == RecordStatus.deleted ||
          record.projectId != named) {
        return RoutePaths.projectRecords(named);
      }
    }
  }
  if (named != null) {
    // The committed-route listener opens the project. Updating it during an
    // asynchronous redirect would refresh the previous route and cancel this one.
    return null;
  }
  if (open != null) {
    return null;
  }
  return Uri(
    path: AppRoutes.projects,
    queryParameters: <String, String>{AppRoutes.fromQuery: _destination(state)},
  ).toString();
}

/// Returns to a diverted location once a project is open. The picker's
/// choice wins: a location that named another project resumes inside the
/// project the operator picked.
String? _resumeIntended(GoRouterState state, Ref ref) {
  if (state.uri.path == AppRoutes.lock) {
    return null;
  }
  final String? from = state.uri.queryParameters[AppRoutes.fromQuery];
  if (from == null || from.isEmpty) {
    return null;
  }
  final String? open = ref.read(openProjectIdProvider);
  if (open == null) {
    return null;
  }
  if (!_isInternalLocation(from)) {
    return null;
  }
  return _inProject(from, open);
}

/// [location] with its `/projects/<id>` segment pointing at [projectId].
String _inProject(String location, String projectId) {
  final Uri uri = Uri.parse(location);
  final List<String> segments = uri.pathSegments;
  if (segments.length < 2 ||
      '/${segments.first}' != AppRoutes.projects ||
      segments[1] == projectId) {
    return location;
  }
  return uri
      .replace(
        path:
            AppRoutes.project(projectId) +
            segments
                .skip(2)
                .map((String part) => '/${Uri.encodeComponent(part)}')
                .join(),
      )
      .toString();
}

String _destination(GoRouterState state) {
  final Uri uri = state.uri;
  final Map<String, String> query = Map<String, String>.of(uri.queryParameters)
    ..remove(AppRoutes.fromQuery);
  return Uri(
    path: uri.path,
    queryParameters: query.isEmpty ? null : query,
  ).toString();
}

bool _isInternalLocation(String location) {
  final Uri? uri = Uri.tryParse(location);
  if (uri == null || uri.hasScheme || uri.host.isNotEmpty) {
    return false;
  }
  return uri.path.startsWith('/') && !uri.path.startsWith('//');
}

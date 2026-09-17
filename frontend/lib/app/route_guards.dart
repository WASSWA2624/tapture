part of 'router.dart';

/// The type `route_guards.dart` is named for (FE-STR-06). The contract
/// publishes [RouteGuard] and [appGuards].
typedef RouteGuards = List<RouteGuard>;

/// One gate in the ordered redirect chain. Returns a location or null.
///
/// Takes [Ref] rather than [WidgetRef]: [WidgetRef] is sealed and needs a
/// widget, and guards must stay unit-testable without one (FE-STATE-04).
typedef RouteGuard = String? Function(GoRouterState state, Ref ref);

/// Ordered redirect chain. Later tasks append a gate — first run, app lock —
/// as one entry rather than a second redirect.
List<RouteGuard> appGuards() {
  return <RouteGuard>[_firstRun, _projectScope, _resumeIntended];
}

/// Open project id the project-scope guard reads. Task 083's `CurrentProject`
/// becomes the source; until then this is none.
final NotifierProvider<OpenProjectId, String?> openProjectIdProvider =
    NotifierProvider<OpenProjectId, String?>(OpenProjectId.new);

/// Holds the open project id for the project-scope guard.
final class OpenProjectId extends Notifier<String?> {
  /// Starts with no project selected.
  @override
  String? build() => null;

  /// Records the open project, or clears it when [id] is null.
  void open(String? id) => state = id;
}

String? _firstRun(GoRouterState state, Ref ref) {
  final String path = state.uri.path;
  if (kDebugMode && path == WidgetGalleryScreen.route) {
    return null;
  }
  final bool completed = ref.read(firstRunProvider).completed;
  if (path == AppRoutes.firstRun) {
    return completed ? _captureTab : null;
  }
  if (completed) {
    return null;
  }
  return AppRoutes.firstRun;
}

String? _projectScope(GoRouterState state, Ref ref) {
  if (state.metadata[_projectScopedKey] != true) {
    return null;
  }
  if (ref.read(openProjectIdProvider) != null) {
    return null;
  }
  return Uri(
    path: AppRoutes.projects,
    queryParameters: <String, String>{AppRoutes.fromQuery: _destination(state)},
  ).toString();
}

String? _resumeIntended(GoRouterState state, Ref ref) {
  final String? from = state.uri.queryParameters[AppRoutes.fromQuery];
  if (from == null || from.isEmpty) {
    return null;
  }
  if (ref.read(openProjectIdProvider) == null) {
    return null;
  }
  if (!_isInternalLocation(from)) {
    return null;
  }
  return from;
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
  final Uri uri = Uri.parse(location);
  if (uri.hasScheme || uri.host.isNotEmpty) {
    return false;
  }
  return uri.path.startsWith('/') && !uri.path.startsWith('//');
}

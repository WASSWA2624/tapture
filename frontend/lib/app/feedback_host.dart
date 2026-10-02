import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/env.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/shell_title.dart';
import 'package:tapture/app/theme/theme_controller.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/network/network.dart';
import 'package:tapture/features/feedback/feedback.dart';
import 'package:tapture/features/feedback/presentation/feedback_overlay.dart';
import 'package:tapture/features/settings/presentation/offline_switch.dart';

import 'router.dart';

/// Wraps the root Navigator with the floating Feedback control and supplies
/// route context without making the feature depend on the router.
class FeedbackHost extends ConsumerWidget {
  /// Creates the host around [child].
  const FeedbackHost({super.key, required this.child});

  /// The complete routed app, including its dialogs and popup routes.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeedbackOverlay(
      origin: _origin(context, ref, ref.watch(_routeUriProvider)),
      child: child,
    );
  }
}

/// The router's current location, followed through its information
/// provider so the host rebuilds without holding widget state
/// (FE-STATE-01).
final NotifierProvider<_RouteUri, Uri> _routeUriProvider =
    NotifierProvider<_RouteUri, Uri>(_RouteUri.new);

class _RouteUri extends Notifier<Uri> {
  @override
  Uri build() {
    final GoRouteInformationProvider information = ref
        .watch(routerProvider)
        .routeInformationProvider;
    void changed() {
      final Uri next = information.value.uri;
      if (next != state) {
        state = next;
      }
    }

    information.addListener(changed);
    ref.onDispose(() => information.removeListener(changed));
    return information.value.uri;
  }
}

FeedbackOrigin _origin(BuildContext context, WidgetRef ref, Uri uri) {
  final String path = uri.path;
  final String route = uri.hasQuery ? '${uri.path}?${uri.query}' : path;
  return FeedbackOrigin(
    screen: ShellTitle.screen(ref, uri),
    route: route,
    routeName: _routeName(path),
    connectivity: _connectivity(ref),
    theme: _theme(context, ref),
    environment: Env.isDev ? 'development' : 'production',
    projectId: ref.watch(openProjectIdProvider),
  );
}

String _routeName(String path) {
  final String? named = _routeNames[path];
  if (named != null) {
    return named;
  }
  if (RoutePaths.isProjectCapture(path)) {
    return 'capture';
  }
  if (path.startsWith('${AppRoutes.projects}/')) {
    return 'project';
  }
  if (path.startsWith('${AppRoutes.records}/')) {
    return 'record';
  }
  return '';
}

/// Stable names feedback files a screen under, one per fixed path.
const Map<String, String> _routeNames = <String, String>{
  '/': 'projects',
  RoutePaths.projects: 'projects',
  RoutePaths.captureRoot: 'capture',
  RoutePaths.records: 'records',
  RoutePaths.more: 'more',
  RoutePaths.templates: 'templates',
  RoutePaths.queue: 'queue',
  RoutePaths.recycleBin: 'recycleBin',
  RoutePaths.settingsOperator: 'settingsOperator',
  RoutePaths.settingsCapture: 'settingsCapture',
  RoutePaths.settingsAi: 'settingsAi',
  RoutePaths.settingsLanguage: 'settingsLanguage',
  RoutePaths.settingsAppearance: 'settingsAppearance',
  RoutePaths.settingsStorage: 'settingsStorage',
  RoutePaths.settingsFiles: 'settingsFiles',
  RoutePaths.settingsSecurity: 'settingsSecurity',
  RoutePaths.settingsPrivacy: 'settingsPrivacy',
  RoutePaths.settingsAbout: 'settingsAbout',
};

String _connectivity(WidgetRef ref) {
  if (ref.watch(offlineByChoiceProvider)) {
    return 'offline by choice';
  }
  final NetworkState state =
      ref.watch(networkStateProvider).value ?? NetworkState.online;
  return switch (state) {
    NetworkState.online => 'online',
    NetworkState.metered => 'metered',
    NetworkState.offline => 'offline',
  };
}

String _theme(BuildContext context, WidgetRef ref) {
  return switch (ref.watch(themeModeProvider)) {
    AppThemeMode.light => 'light',
    AppThemeMode.dark => 'dark',
    AppThemeMode.outdoor => 'outdoor',
    AppThemeMode.system =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark
          ? 'system (dark)'
          : 'system (light)',
  };
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/env.dart';
import 'package:tapture/app/shell_title.dart';
import 'package:tapture/app/theme/theme_controller.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/network/network.dart';
import 'package:tapture/features/feedback/feedback.dart';
import 'package:tapture/features/feedback/presentation/feedback_overlay.dart';
import 'package:tapture/features/settings/presentation/offline_switch.dart';

import 'router.dart';

/// Wraps the nav shell with the floating Feedback control and the origin
/// the feature needs, so the feature never reads the router.
class FeedbackHost extends ConsumerWidget {
  /// Creates the host around [child].
  const FeedbackHost({super.key, required this.child});

  /// The four-destination chrome.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeedbackOverlay(origin: _origin(context, ref), child: child);
  }
}

FeedbackOrigin _origin(BuildContext context, WidgetRef ref) {
  final GoRouterState state = GoRouterState.of(context);
  final String path = state.uri.path;
  final String route = state.uri.hasQuery
      ? '${state.uri.path}?${state.uri.query}'
      : path;
  return FeedbackOrigin(
    screen: ShellTitle.screen(ref, state.uri),
    route: route,
    routeName: _routeName(path),
    connectivity: _connectivity(ref),
    theme: _theme(context, ref),
    environment: Env.isDev ? 'development' : 'production',
    projectId: ref.watch(openProjectIdProvider),
  );
}

String _routeName(String path) {
  if (path == AppRoutes.projects || path == '/') {
    return 'projects';
  }
  if (path == AppRoutes.records) {
    return 'records';
  }
  if (path == AppRoutes.more) {
    return 'more';
  }
  if (path == AppRoutes.settingsOperator) {
    return 'settingsOperator';
  }
  if (path == AppRoutes.settingsCapture) {
    return 'settingsCapture';
  }
  if (path == AppRoutes.settingsAppearance) {
    return 'settingsAppearance';
  }
  if (path == AppRoutes.settingsStorage) {
    return 'settingsStorage';
  }
  if (path == AppRoutes.settingsSecurity) {
    return 'settingsSecurity';
  }
  if (path == AppRoutes.settingsAbout) {
    return 'settingsAbout';
  }
  if (path == AppRoutes.templates) {
    return 'templates';
  }
  if (path == AppRoutes.queue) {
    return 'queue';
  }
  if (path.startsWith('${AppRoutes.projects}/') && path.endsWith('/capture')) {
    return 'capture';
  }
  if (path == '/capture') {
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

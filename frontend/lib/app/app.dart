/// The application shell: entry, router, theme and navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'env.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

export 'env.dart';
export 'theme/app_theme.dart';
export 'theme/outdoor_theme.dart';
export 'theme/theme_controller.dart';

/// The type `app.dart` is named for (FE-STR-06). The contract name is
/// [TaptureApp].
typedef App = TaptureApp;

/// The root widget: one [MaterialApp.router] placeholder under [ProviderScope].
class TaptureApp extends ConsumerWidget {
  /// Creates the application shell.
  const TaptureApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String title = ref.watch(_appTitleProvider);
    final AppThemeMode mode = ref.watch(themeModeProvider);
    final bool outdoor = mode == AppThemeMode.outdoor;
    return MaterialApp.router(
      title: title,
      theme: buildTheme(brightness: Brightness.light, outdoor: outdoor),
      darkTheme: buildTheme(brightness: Brightness.dark, outdoor: outdoor),
      themeMode: switch (mode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system || AppThemeMode.outdoor => ThemeMode.system,
      },
      routerDelegate: _placeholderDelegate,
      routeInformationParser: _placeholderParser,
    );
  }
}

/// Flavour-dependent chrome, provided at the scope rather than branched on
/// in a feature (FE-STATE-03).
final Provider<String> _appTitleProvider = Provider<String>((_) {
  return switch (Env.flavor) {
    Flavor.dev => 'Tapture Dev',
    Flavor.prod => 'Tapture',
  };
});

final _PlaceholderRouterDelegate _placeholderDelegate =
    _PlaceholderRouterDelegate();

final _PlaceholderRouteInformationParser _placeholderParser =
    _PlaceholderRouteInformationParser();

class _PlaceholderRouterDelegate extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Object get currentConfiguration => const Object();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: const <Page<void>>[MaterialPage<void>(child: Scaffold())],
      onDidRemovePage: (Page<Object?> page) {},
    );
  }

  @override
  Future<void> setNewRoutePath(Object configuration) async {}
}

class _PlaceholderRouteInformationParser
    extends RouteInformationParser<Object> {
  @override
  Future<Object> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    return const Object();
  }
}

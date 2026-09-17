/// The application shell: entry, router, theme and navigation.
library;

import 'package:flutter/material.dart' hide Router;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'env.dart';
import 'router.dart' show Router, routerProvider;
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

export 'env.dart';
export 'router.dart' hide Router;
export 'theme/app_theme.dart';
export 'theme/outdoor_theme.dart';
export 'theme/theme_controller.dart';

/// The type `app.dart` is named for (FE-STR-06). The contract name is
/// [TaptureApp].
typedef App = TaptureApp;

/// The root widget: one [MaterialApp.router] under [ProviderScope].
class TaptureApp extends ConsumerWidget {
  /// Creates the application shell.
  const TaptureApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String title = ref.watch(_appTitleProvider);
    final AppThemeMode mode = ref.watch(themeModeProvider);
    final bool outdoor = mode == AppThemeMode.outdoor;
    final Router router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: title,
      theme: buildTheme(brightness: Brightness.light, outdoor: outdoor),
      darkTheme: buildTheme(brightness: Brightness.dark, outdoor: outdoor),
      themeMode: switch (mode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system || AppThemeMode.outdoor => ThemeMode.system,
      },
      routerConfig: router,
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

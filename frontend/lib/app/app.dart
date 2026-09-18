/// The application shell: entry, router, theme and navigation.
library;

import 'package:flutter/material.dart' hide Router;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/ai/stt_service.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/error_boundary.dart';
import 'package:tapture/core/widgets/fields/dictation_scope.dart';
import 'package:tapture/features/settings/presentation/offline_switch.dart';
import 'package:tapture/features/settings/settings.dart';

import 'env.dart';
import 'router.dart' show AppRoutes, Router, routerProvider;
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'widgets/global_error_page.dart';

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
    final SttService speech = ref.watch(sttServiceProvider);
    final String voiceLanguage = ref
        .watch(offlineStoreProvider)
        .read(SettingKeys.voiceLanguage);
    final bool offline = ref.watch(offlineByChoiceProvider);
    return MaterialApp.router(
      title: title,
      theme: buildTheme(brightness: Brightness.light, outdoor: outdoor),
      darkTheme: buildTheme(brightness: Brightness.dark, outdoor: outdoor),
      themeMode: switch (mode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system || AppThemeMode.outdoor => ThemeMode.system,
      },
      builder: (BuildContext _, Widget? child) {
        // Above the navigator, so pushed screens and sheets dictate too.
        return DictationScope(
          service: speech,
          languageTag: voiceLanguage,
          onDeviceOnly: offline,
          child: ErrorBoundary(
            fallback: (Failure failure, VoidCallback retry) {
              return GlobalErrorPage(
                failure: failure,
                onRestart: retry,
                onOpenRecycleBin: () => router.go(AppRoutes.more),
              );
            },
            child: child ?? const SizedBox.shrink(),
          ),
        );
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

/// The application shell: entry, router, theme and navigation.
library;

import 'package:flutter/material.dart' hide Router;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/ai/stt_service.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/network/network.dart';
import 'package:tapture/core/widgets/error_boundary.dart';
import 'package:tapture/core/widgets/fields/dictation_scope.dart';
import 'package:tapture/features/processing/processing.dart'
    show unattendedProcessingProvider;
import 'package:tapture/features/settings/presentation/language_settings_screen.dart'
    show voiceLanguageProvider;
import 'package:tapture/features/settings/presentation/offline_switch.dart';

import 'env.dart';
import 'feedback_host.dart';
import 'locale_controller.dart';
import 'router.dart' show AppRoutes, Router, routerProvider;
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'widgets/global_error_page.dart';
import 'widgets/incoming_bundle_host.dart';
import 'widgets/status_line.dart' show networkStateProvider;

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
  const TaptureApp({this.receiveIncomingBundles = true, super.key});

  /// Receives shared packages in production. Isolated native fixtures disable
  /// delivery so they cannot consume a package intended for the installed app.
  final bool receiveIncomingBundles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String title = ref.watch(_appTitleProvider);
    final AppThemeMode mode = ref.watch(themeModeProvider);
    final bool outdoor = mode == AppThemeMode.outdoor;
    final Router router = ref.watch(routerProvider);
    final SttService speech = ref.watch(sttServiceProvider);
    final String voiceLanguage = ref.watch(voiceLanguageProvider);
    // Recognition stays on the device whenever no network path exists,
    // chosen or not, so dictation never waits on a dead connection
    // (FE-SEC-04).
    final bool offline =
        ref.watch(offlineByChoiceProvider) ||
        ref.watch(networkStateProvider).value == NetworkState.offline;
    // Keeps automatic processing and opportunistic reading listening for
    // the app's life; each stays off until its setting is on.
    ref.watch(unattendedProcessingProvider);
    return MaterialApp.router(
      title: title,
      locale: ref.watch(appLocaleProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
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
          child: FeedbackHost(
            child: ErrorBoundary(
              fallback: (Failure failure, VoidCallback retry) {
                return GlobalErrorPage(
                  failure: failure,
                  onRestart: retry,
                  onOpenRecycleBin: () => router.go(AppRoutes.recycleBin),
                );
              },
              child: receiveIncomingBundles
                  ? IncomingBundleHost(child: child ?? const SizedBox.shrink())
                  : child ?? const SizedBox.shrink(),
            ),
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
    Flavor.dev => Copy.appNameDev,
    Flavor.prod => Copy.appName,
  };
});

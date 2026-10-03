import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/theme_controller.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

/// Chooses System, Light, Dark or Outdoor. The shell re-themes at once.
class AppearanceSettingsScreen extends ConsumerWidget {
  /// Creates the Appearance screen.
  const AppearanceSettingsScreen({super.key});

  static List<Choice<AppThemeMode>> _options(LocalizedCopy copy) =>
      <Choice<AppThemeMode>>[
        Choice<AppThemeMode>(AppThemeMode.system, copy.themeModeSystem),
        Choice<AppThemeMode>(AppThemeMode.light, copy.themeModeLight),
        Choice<AppThemeMode>(AppThemeMode.dark, copy.themeModeDark),
        Choice<AppThemeMode>(AppThemeMode.outdoor, copy.themeModeOutdoor),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AppThemeMode mode = ref.watch(themeModeProvider);
    return AppPage(
      title: localCopy.settingsAppearanceTitle,
      body: AppRadioGroup<AppThemeMode>(
        label: localCopy.settingsAppearanceTitle,
        value: mode,
        options: _options(localCopy),
        onChanged: (AppThemeMode next) {
          unawaited(ref.read(themeModeProvider.notifier).setMode(next));
        },
      ),
    );
  }
}

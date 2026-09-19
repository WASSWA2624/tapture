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

  static const List<Choice<AppThemeMode>> _options = <Choice<AppThemeMode>>[
    Choice<AppThemeMode>(AppThemeMode.system, Copy.themeModeSystem),
    Choice<AppThemeMode>(AppThemeMode.light, Copy.themeModeLight),
    Choice<AppThemeMode>(AppThemeMode.dark, Copy.themeModeDark),
    Choice<AppThemeMode>(AppThemeMode.outdoor, Copy.themeModeOutdoor),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeMode mode = ref.watch(themeModeProvider);
    return AppPage(
      title: Copy.settingsAppearanceTitle,
      body: AppRadioGroup<AppThemeMode>(
        label: Copy.settingsAppearanceTitle,
        value: mode,
        options: _options,
        onChanged: (AppThemeMode next) {
          unawaited(ref.read(themeModeProvider.notifier).setMode(next));
        },
      ),
    );
  }
}

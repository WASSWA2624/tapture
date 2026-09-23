import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import 'offline_switch.dart';

// The notifier is private so this file holds one public class (FE-STR-06).
// ignore_for_file: library_private_types_in_public_api

/// The settings root: one tile per section, in a fixed order.
class SettingsScreen extends ConsumerWidget {
  /// Creates the settings root. [showAppBar] is false under the Settings tab.
  const SettingsScreen({super.key, this.showAppBar = true});

  /// When false, the shell already shows chrome.
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<_Section>> value = ref.watch(
      settingsSectionsProvider,
    );
    return AppPage(
      title: Copy.settingsTitle,
      showAppBar: showAppBar,
      inset: false,
      body: AsyncValueView<List<_Section>>(
        value: value,
        isEmpty: (List<_Section> sections) => sections.isEmpty,
        onRetry: () => ref.invalidate(settingsSectionsProvider),
        empty: () {
          return const AppEmptyState(
            icon: Icons.settings_outlined,
            headline: Copy.settingsEmptyHeadline,
            message: Copy.settingsEmptyMessage,
          );
        },
        data: (List<_Section> sections) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const OfflineSwitch(),
              for (int index = 0; index < sections.length; index++) ...<Widget>[
                if (index == 0 ||
                    sections[index - 1].group != sections[index].group)
                  AppSectionHeader(title: sections[index].group),
                AppListTile(
                  title: sections[index].title,
                  subtitle: sections[index].subtitle,
                  trailing: sections[index].route == null
                      ? null
                      : const Icon(Icons.chevron_right),
                  onTap: sections[index].route == null
                      ? null
                      : () => context.go(sections[index].route!),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Injects the section list so tests never depend on the router table.
Override settingsScreenOverride({
  required Future<List<({String title, String subtitle, String? route})>>
  Function()
  load,
}) {
  return settingsSectionsProvider.overrideWith((Ref ref) async {
    try {
      final List<({String title, String subtitle, String? route})> loaded =
          await load();
      return loaded
          .map(
            (({String title, String subtitle, String? route}) section) => (
              title: section.title,
              subtitle: section.subtitle,
              route: section.route,
              group: Copy.settingsGroupAbout,
            ),
          )
          .toList();
    } on Object catch (error) {
      Error.throwWithStackTrace(_asError(error), StackTrace.current);
    }
  });
}

/// The specification sections, in order. Later screens add a route
/// here rather than reshaping the list.
/// Local catalogue. Riverpod's default backoff would keep a failed
/// load in [AsyncLoading] for tens of seconds (FE-STATE-11).
final FutureProvider<List<_Section>> settingsSectionsProvider =
    FutureProvider<List<_Section>>(
      (Ref ref) async => _defaultSections,
      retry: (int _, Object _) => null,
    );

typedef _Section = ({
  String title,
  String subtitle,
  String? route,
  String group,
});

Object _asError(Object error) {
  if (error is Exception || error is Error) {
    return error;
  }
  return Exception(error.toString());
}

const List<_Section> _defaultSections = <_Section>[
  (
    title: Copy.operatorProfileTitle,
    subtitle: Copy.settingsOperatorSubtitle,
    route: RoutePaths.settingsOperator,
    group: Copy.settingsGroupProfileCapture,
  ),
  (
    title: Copy.navCapture,
    subtitle: Copy.settingsCaptureSubtitle,
    route: RoutePaths.settingsCapture,
    group: Copy.settingsGroupProfileCapture,
  ),
  (
    title: Copy.settingsAiTitle,
    subtitle: Copy.settingsAiSubtitle,
    route: RoutePaths.settingsAi,
    group: Copy.settingsGroupIntelligenceAppearance,
  ),
  (
    title: Copy.settingsAppearanceTitle,
    subtitle: Copy.settingsAppearanceSubtitle,
    route: RoutePaths.settingsAppearance,
    group: Copy.settingsGroupIntelligenceAppearance,
  ),
  (
    title: Copy.settingsStorageTitle,
    subtitle: Copy.settingsStorageSubtitle,
    route: RoutePaths.settingsStorage,
    group: Copy.settingsGroupStorageSecurity,
  ),
  (
    title: Copy.settingsSecurityTitle,
    subtitle: Copy.settingsSecuritySubtitle,
    route: RoutePaths.settingsSecurity,
    group: Copy.settingsGroupStorageSecurity,
  ),
  (
    title: Copy.settingsAboutTitle,
    subtitle: Copy.settingsAboutSubtitle,
    route: RoutePaths.settingsAbout,
    group: Copy.settingsGroupAbout,
  ),
];

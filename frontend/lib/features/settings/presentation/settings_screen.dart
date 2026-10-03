import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/shell_destination.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/feedback/feedback.dart'
    show DownloadFeedbackScreen, openFeedbackFlow;

import 'friction_report_controller.dart';
import 'offline_switch.dart';

// The notifier is private so this file holds one public class (FE-STR-06).
// ignore_for_file: library_private_types_in_public_api

/// The settings root: one tile per section, in a fixed order. Each tile's
/// title is its page's title.
///
/// From medium width up the rail's Settings replaces the compact More menu,
/// so the root first lists that menu's secondary destinations (Templates,
/// Unprocessed, Recycle bin). Compact reaches them from More instead, so
/// they are not repeated here.
class SettingsScreen extends ConsumerWidget {
  /// Creates the settings root.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AsyncValue<List<_Section>> value = ref.watch(
      settingsSectionsProvider,
    );
    final bool menuOnRail = context.sizeClass != SizeClass.compact;
    return AppPage(
      title: localCopy.settingsTitle,
      overflow: <AppOverflowAction>[
        if (ref.watch(fieldTrialProvider))
          AppOverflowAction(
            label: localCopy.frictionExport,
            icon: AppIcons.download,
            onTap: () => unawaited(
              openFeedbackFlow<void>(
                context,
                page: const DownloadFeedbackScreen(),
              ),
            ),
          ),
      ],
      inset: false,
      body: AsyncValueView<List<_Section>>(
        value: value,
        isEmpty: (List<_Section> sections) => sections.isEmpty,
        onRetry: () => ref.invalidate(settingsSectionsProvider),
        empty: () {
          final LocalizedCopy localCopy = Copy.of(context);

          return AppEmptyState(
            icon: AppIcons.settings,
            headline: localCopy.settingsEmptyHeadline,
            message: localCopy.settingsEmptyMessage,
            actionLabel: localCopy.tryAgain,
            onAction: () => ref.invalidate(settingsSectionsProvider),
          );
        },
        data: (List<_Section> sections) {
          final LocalizedCopy localCopy = Copy.of(context);

          final List<_Section> localizedSections = _localizeSections(
            sections,
            localCopy,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const OfflineSwitch(),
              if (menuOnRail) ...<Widget>[
                AppSectionHeader(title: localCopy.navMoreMenu),
                for (final ShellDestination destination in moreDestinations)
                  if (destination.path != RoutePaths.more)
                    AppListTile(
                      key: ValueKey<String>(
                        'settings-more-${destination.path}',
                      ),
                      title: destination.labelFor(localCopy),
                      leading: Icon(destination.icon),
                      trailing: const Icon(AppIcons.open),
                      onTap: () => context.go(destination.path),
                    ),
              ],
              for (
                int index = 0;
                index < localizedSections.length;
                index++
              ) ...<Widget>[
                if (index == 0 ||
                    localizedSections[index - 1].group !=
                        localizedSections[index].group)
                  AppSectionHeader(title: localizedSections[index].group),
                AppListTile(
                  title: localizedSections[index].title,
                  subtitle: localizedSections[index].subtitle,
                  trailing: localizedSections[index].route == null
                      ? null
                      : const Icon(AppIcons.open),
                  onTap: localizedSections[index].route == null
                      ? null
                      : () => context.go(localizedSections[index].route!),
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
              group: Copy.english.settingsGroupAbout,
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
      (Ref ref) async => _defaultSections(Copy.english),
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

List<_Section> _localizeSections(List<_Section> sections, LocalizedCopy copy) {
  final List<_Section> defaults = _defaultSections(Copy.english);
  final List<_Section> localized = _defaultSections(copy);
  final Map<_Section, _Section> translations = <_Section, _Section>{
    for (int index = 0; index < defaults.length; index++)
      defaults[index]: localized[index],
  };
  return <_Section>[
    for (final _Section section in sections) translations[section] ?? section,
  ];
}

List<_Section> _defaultSections(LocalizedCopy copy) => <_Section>[
  (
    title: copy.backendSettingsTitle,
    subtitle: copy.backendSettingsSubtitle,
    route: RoutePaths.settingsAccount,
    group: copy.settingsGroupProfileCapture,
  ),
  (
    title: copy.operatorProfileTitle,
    subtitle: copy.settingsOperatorSubtitle,
    route: RoutePaths.settingsOperator,
    group: copy.settingsGroupProfileCapture,
  ),
  (
    title: copy.relayTitle,
    subtitle: copy.settingsRelaySubtitle,
    route: RoutePaths.settingsRelay,
    group: copy.settingsGroupProfileCapture,
  ),
  (
    title: copy.settingsCaptureTitle,
    subtitle: copy.settingsCaptureSubtitle,
    route: RoutePaths.settingsCapture,
    group: copy.settingsGroupProfileCapture,
  ),
  (
    title: copy.settingsAiTitle,
    subtitle: copy.settingsAiSubtitle,
    route: RoutePaths.settingsAi,
    group: copy.settingsGroupIntelligenceAppearance,
  ),
  (
    title: copy.settingsLanguageTitle,
    subtitle: copy.settingsLanguageSubtitle,
    route: RoutePaths.settingsLanguage,
    group: copy.settingsGroupIntelligenceAppearance,
  ),
  (
    title: copy.settingsAppearanceTitle,
    subtitle: copy.settingsAppearanceSubtitle,
    route: RoutePaths.settingsAppearance,
    group: copy.settingsGroupIntelligenceAppearance,
  ),
  (
    title: copy.settingsStorageTitle,
    subtitle: copy.settingsStorageSubtitle,
    route: RoutePaths.settingsStorage,
    group: copy.settingsGroupStorageSecurity,
  ),
  (
    title: copy.settingsFilesTitle,
    subtitle: copy.settingsFilesSubtitle,
    route: RoutePaths.settingsFiles,
    group: copy.settingsGroupStorageSecurity,
  ),
  (
    title: copy.appLockTitle,
    subtitle: copy.settingsSecuritySubtitle,
    route: RoutePaths.settingsSecurity,
    group: copy.settingsGroupStorageSecurity,
  ),
  (
    title: copy.privacyScreenTitle,
    subtitle: copy.privacySubtitle,
    route: RoutePaths.settingsPrivacy,
    group: copy.settingsGroupStorageSecurity,
  ),
  (
    title: copy.settingsAboutTitle,
    subtitle: copy.settingsAboutSubtitle,
    route: RoutePaths.settingsAbout,
    group: copy.settingsGroupAbout,
  ),
];

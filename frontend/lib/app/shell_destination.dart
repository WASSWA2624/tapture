import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';

import 'route_paths.dart';

/// Immutable metadata shared by shell navigation and the status header.
final class ShellDestination {
  /// Creates one top-level destination.
  const ShellDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.compactLabel,
    this.compactIcon,
    this.dominant = false,
    this.hasList = false,
    this.localizedLabel,
  });

  /// Root path.
  final String path;

  /// Visible and semantic label.
  final String label;

  /// Explicit label identity for destinations sharing the same route.
  final LocalizedMessage? localizedLabel;

  /// Unselected navigation and header glyph.
  final IconData icon;

  /// Selected navigation glyph.
  final IconData selectedIcon;

  /// Optional label when a compact control opens a menu instead of a page.
  final String? compactLabel;

  /// Optional compact-menu glyph, shared by selected and unselected states.
  final IconData? compactIcon;

  /// Whether the compact camera action is visually dominant.
  final bool dominant;

  /// Whether expanded layouts provide a list pane.
  final bool hasList;

  /// Resolves navigation copy while preserving unknown custom labels.
  String labelFor(LocalizedCopy copy) => localizedLabel == null
      ? switch (path) {
          RoutePaths.projects => copy.navProjects,
          RoutePaths.captureRoot => copy.navCapture,
          RoutePaths.records => copy.navRecords,
          RoutePaths.more => copy.navMore,
          RoutePaths.templates => copy.navTemplates,
          RoutePaths.queue => copy.navQueue,
          RoutePaths.recycleBin => copy.recycleBinTitle,
          RoutePaths.transcripts => copy.navTranscripts,
          _ => label,
        }
      : copy.resolve(localizedLabel!);

  /// The short menu label in the app's current locale.
  String? compactLabelFor(LocalizedCopy copy) =>
      path == RoutePaths.more ? copy.navMoreMenu : compactLabel;
}

/// The one ordered source for the two application destinations.
final List<ShellDestination> shellDestinations = <ShellDestination>[
  ShellDestination(
    path: RoutePaths.projects,
    icon: AppIcons.project,
    selectedIcon: AppIcons.projectSelected,
    label: Copy.navProjects,
    hasList: true,
  ),
  ShellDestination(
    path: RoutePaths.more,
    icon: AppIcons.settings,
    selectedIcon: AppIcons.settingsSelected,
    label: Copy.navMore,
    compactLabel: Copy.navMoreMenu,
    compactIcon: AppIcons.moreHorizontal,
  ),
];

/// Working secondary destinations offered by the compact More menu. The
/// settings root lists the same rows from medium width up, where the rail's
/// Settings replaces that menu.
final List<ShellDestination> moreDestinations = <ShellDestination>[
  ShellDestination(
    path: RoutePaths.templates,
    label: Copy.navTemplates,
    icon: AppIcons.template,
    selectedIcon: AppIcons.template,
  ),
  ShellDestination(
    path: RoutePaths.recycleBin,
    label: Copy.recycleBinTitle,
    icon: AppIcons.recycleBin,
    selectedIcon: AppIcons.recycleBin,
  ),
  ShellDestination(
    path: RoutePaths.more,
    label: Copy.settingsTitle,
    localizedLabel: Copy.messages.settingsTitle,
    icon: AppIcons.settings,
    selectedIcon: AppIcons.settingsSelected,
  ),
];

/// Destination owning [uri], including project-scoped capture routes.
ShellDestination? shellDestinationFor(Uri uri) {
  final String path = uri.path;
  for (final ShellDestination destination in shellDestinations) {
    if (path == destination.path || path.startsWith('${destination.path}/')) {
      return destination;
    }
  }
  return null;
}

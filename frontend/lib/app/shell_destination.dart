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
  });

  /// Root path.
  final String path;

  /// Visible and semantic label.
  final String label;

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
}

/// The one ordered source for the four application destinations.
const List<ShellDestination> shellDestinations = <ShellDestination>[
  ShellDestination(
    path: RoutePaths.projects,
    icon: AppIcons.project,
    selectedIcon: AppIcons.projectSelected,
    label: Copy.navProjects,
    hasList: true,
  ),
  ShellDestination(
    path: RoutePaths.captureRoot,
    icon: AppIcons.camera,
    selectedIcon: AppIcons.cameraSelected,
    label: Copy.navCapture,
    dominant: true,
  ),
  ShellDestination(
    path: RoutePaths.records,
    icon: AppIcons.records,
    selectedIcon: AppIcons.recordsSelected,
    label: Copy.navRecords,
    hasList: true,
  ),
  ShellDestination(
    path: RoutePaths.more,
    icon: AppIcons.settings,
    selectedIcon: AppIcons.settingsSelected,
    label: Copy.navMore,
    compactLabel: Copy.navMoreMenu,
    compactIcon: AppIcons.more,
  ),
];

/// Working secondary destinations offered by the compact More menu.
const List<ShellDestination> moreDestinations = <ShellDestination>[
  ShellDestination(
    path: RoutePaths.templates,
    label: Copy.navTemplates,
    icon: AppIcons.template,
    selectedIcon: AppIcons.template,
  ),
  ShellDestination(
    path: RoutePaths.queue,
    label: Copy.navQueue,
    icon: AppIcons.queued,
    selectedIcon: AppIcons.queued,
  ),
  ShellDestination(
    path: RoutePaths.recycleBin,
    label: Copy.recycleBinTitle,
    icon: AppIcons.restore,
    selectedIcon: AppIcons.restore,
  ),
  ShellDestination(
    path: RoutePaths.more,
    label: Copy.settingsTitle,
    icon: AppIcons.settings,
    selectedIcon: AppIcons.settingsSelected,
  ),
];

/// Destination owning [uri], including project-scoped capture routes.
ShellDestination? shellDestinationFor(Uri uri) {
  final String path = uri.path;
  if (RoutePaths.isProjectCapture(path)) {
    return shellDestinations[1];
  }
  for (final ShellDestination destination in shellDestinations) {
    if (path == destination.path || path.startsWith('${destination.path}/')) {
      return destination;
    }
  }
  return null;
}

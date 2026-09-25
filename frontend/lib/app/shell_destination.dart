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

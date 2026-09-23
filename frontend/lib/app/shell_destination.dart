import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';

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
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder,
    label: Copy.navProjects,
    hasList: true,
  ),
  ShellDestination(
    path: RoutePaths.captureRoot,
    icon: Icons.photo_camera_outlined,
    selectedIcon: Icons.photo_camera,
    label: Copy.navCapture,
    dominant: true,
  ),
  ShellDestination(
    path: RoutePaths.records,
    icon: Icons.list_alt_outlined,
    selectedIcon: Icons.list_alt,
    label: Copy.navRecords,
    hasList: true,
  ),
  ShellDestination(
    path: RoutePaths.more,
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
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

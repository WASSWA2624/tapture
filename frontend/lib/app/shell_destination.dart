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
}

/// Route branches, independent of the number of visible navigation tabs.
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
  ),
];

/// Home tabs in priority order. Recycle bin belongs to Settings.
final List<ShellDestination> navigationDestinations = <ShellDestination>[
  shellDestinations.first,
  ShellDestination(
    path: RoutePaths.templates,
    label: Copy.navTemplates,
    icon: AppIcons.template,
    selectedIcon: AppIcons.template,
  ),
  shellDestinations.last,
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/network/network.dart';
import 'package:tapture/core/widgets/app_brand_lockup.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';

import '../router.dart';

/// Permanent one-line strip: where the operator is, and what is queued.
///
/// Each chip is a link. Counts are derived, never cached (FE-STATE-06).
class StatusLine extends ConsumerWidget {
  /// Creates the status line.
  const StatusLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String projectLabel = ref.watch(statusProjectLabelProvider);
    final String? projectId = ref.watch(openProjectIdProvider);
    final String contextLabel = ref.watch(statusContextProvider);
    final String templateLabel = ref.watch(statusTemplateLabelProvider);
    final NetworkState network =
        ref.watch(networkStateProvider).value ?? NetworkState.online;
    final bool byChoice = ref.watch(offlineByChoiceProvider);
    final int unprocessed = ref.watch(unprocessedCountProvider);
    final bool inverted =
        context.sizeClass == SizeClass.compact &&
        Theme.of(context).brightness != Brightness.dark;
    final AppColors colors = context.colors;
    return Material(
      color: inverted ? colors.primary : colors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.outline, width: Space.x0 / 2),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: Sizes.minTapTarget + Space.x2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x3),
            child: Row(
              children: <Widget>[
                AppBrandLockup(inverted: inverted),
                const SizedBox(width: Space.x2),
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      extensions: <ThemeExtension<dynamic>>[
                        inverted
                            ? colors.copyWith(surfaceVariant: colors.surface)
                            : colors,
                      ],
                    ),
                    child: AppChipRow(
                      scrollable: true,
                      chips: <AppChip>[
                        AppChip(
                          key: const ValueKey<String>('status-project'),
                          icon: Icons.work_outline,
                          label: _whereLabel(
                            projectId,
                            projectLabel,
                            contextLabel,
                          ),
                          onTap: () {
                            context.go(_projectLocation(projectId));
                          },
                        ),
                        AppChip(
                          key: const ValueKey<String>('status-template'),
                          icon: Icons.article_outlined,
                          label: templateLabel,
                          onTap: () => context.go(AppRoutes.templates),
                        ),
                        AppChip(
                          key: const ValueKey<String>('status-network'),
                          icon: _networkIcon(network, byChoice),
                          label: _networkLabel(network, byChoice),
                          onTap: () => context.go(AppRoutes.more),
                        ),
                        AppChip(
                          key: const ValueKey<String>('status-unprocessed'),
                          icon: Icons.pending_outlined,
                          label: Copy.unprocessedCount(unprocessed),
                          onTap: () => context.go(AppRoutes.queue),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Radio plus override, folded by [ConnectivityService]. Kept alive: the
/// shell reads it on every frame (FE-STATE-09).
final Provider<ConnectivityService> connectivityServiceProvider =
    Provider<ConnectivityService>((Ref ref) {
      final ConnectivityService service = ConnectivityService();
      ref.onDispose(service.dispose);
      return service;
    });

/// Live [NetworkState]. Not autoDispose: see [connectivityServiceProvider].
final StreamProvider<NetworkState> networkStateProvider =
    StreamProvider<NetworkState>((Ref ref) {
      return ref.watch(connectivityServiceProvider).watch();
    });

/// Whether the operator forced offline. Task 081 is the writer; until then
/// this is false so a radio-off is labelled as offline-by-radio.
final Provider<bool> offlineByChoiceProvider = Provider<bool>((Ref _) => false);

/// Project name on the line. Task 083 replaces the label.
final Provider<String> statusProjectLabelProvider = Provider<String>((Ref ref) {
  final String? id = ref.watch(openProjectIdProvider);
  return id ?? Copy.statusNoProject;
});

/// Pinned context label. Task 115 replaces this stub.
final Provider<String> statusContextProvider = Provider<String>((Ref _) {
  return Copy.statusNoContext;
});

/// Pinned template. Task 141 replaces this stub.
final Provider<String> statusTemplateLabelProvider = Provider<String>((Ref _) {
  return Copy.statusNoTemplate;
});

/// Unprocessed records. A later watch query feeds this; until then the
/// count is zero. Not autoDispose: the shell reads it every frame
/// (FE-STATE-09).
final Provider<int> unprocessedCountProvider = Provider<int>((Ref _) => 0);

/// A fake already-online radio so suites that are not about connectivity
/// never open the plugin (FE-TEST-03, FE-STR-11).
Override networkOnlineOverride() {
  return connectivityServiceProvider.overrideWith((Ref ref) {
    final ConnectivityService service = ConnectivityService.fake(
      source: Stream<NetworkState>.value(NetworkState.online),
    );
    ref.onDispose(service.dispose);
    return service;
  });
}

String _whereLabel(String? projectId, String project, String context) {
  if (projectId == null) {
    return Copy.statusNoProject;
  }
  if (context.isEmpty || context == Copy.statusNoContext) {
    return project;
  }
  return Copy.statusWhere(project, context);
}

String _projectLocation(String? id) {
  if (id == null) {
    return AppRoutes.projects;
  }
  return AppRoutes.project(id);
}

String _networkLabel(NetworkState state, bool byChoice) {
  if (byChoice) {
    return Copy.networkOfflineByChoice;
  }
  return switch (state) {
    NetworkState.online => Copy.networkOnline,
    NetworkState.metered => Copy.networkMetered,
    NetworkState.offline => Copy.networkOffline,
  };
}

IconData _networkIcon(NetworkState state, bool byChoice) {
  if (byChoice || state == NetworkState.offline) {
    return Icons.cloud_off;
  }
  if (state == NetworkState.metered) {
    return Icons.signal_cellular_alt;
  }
  return Icons.wifi;
}

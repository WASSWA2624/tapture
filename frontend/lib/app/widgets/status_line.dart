import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:tapture/app/shell_title.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/network/network.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/shell_header_scope.dart';
import 'package:tapture/features/context/domain/context_state.dart';
import 'package:tapture/features/context/presentation/context_providers.dart';
import 'package:tapture/features/projects/presentation/current_project.dart';
import 'package:tapture/features/settings/presentation/offline_switch.dart';

import '../router.dart';

/// Permanent one-line strip.
///
/// Every route shows the screen name. A branch root has no back control.
/// Nested routes add back, then that page's actions (FE-CONS-10).
/// Counts are derived, never cached (FE-STATE-06).
class StatusLine extends ConsumerWidget {
  /// Creates the status line.
  const StatusLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool compact = context.sizeClass == SizeClass.compact;
    final bool inverted =
        compact && Theme.of(context).brightness != Brightness.dark;
    final AppColors colors = context.colors;
    final Color bar = inverted
        ? colors.primary
        : (compact ? colors.surfaceVariant : colors.surface);
    final Color ink = inverted ? colors.onPrimary : colors.onSurface;
    final Uri uri = GoRouterState.of(context).uri;
    final bool root = ShellTitle.isRoot(uri);
    final String fallback = ShellTitle.screen(ref, uri);
    final ({
      String title,
      List<Widget> actions,
      List<AppOverflowAction> overflow,
    })?
    chrome = ShellHeaderScope.chromeOf(context);
    final String title = !root && chrome != null && chrome.title.isNotEmpty
        ? chrome.title
        : fallback;
    final List<AppOverflowAction> overflow =
        chrome?.overflow ?? const <AppOverflowAction>[];
    final List<Widget> actions = chrome?.actions ?? const <Widget>[];
    return Material(
      color: bar,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: inverted
              ? null
              : Border(
                  bottom: BorderSide(
                    color: colors.outline,
                    width: Space.x0 / 2,
                  ),
                ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: Sizes.minTapTarget + Space.x2,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x3),
            child: IconTheme(
              data: IconThemeData(color: ink),
              child: Row(
                children: <Widget>[
                  if (!root)
                    AppIconButton(
                      key: const ValueKey<String>('shell-back'),
                      icon: Icons.arrow_back,
                      semanticLabel: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      outlined: false,
                      onPressed: () => _back(context),
                    ),
                  if (!root) const SizedBox(width: Space.x2),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyStrong.copyWith(color: ink),
                    ),
                  ),
                  ...actions,
                  if (actions.isNotEmpty && overflow.isNotEmpty)
                    const SizedBox(width: Space.x2),
                  if (overflow.isNotEmpty)
                    AppOverflowMenu(
                      key: const ValueKey<String>('app-page-overflow'),
                      inverted: inverted,
                      items: overflow,
                    ),
                ],
              ),
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
      final StreamController<bool> override = StreamController<bool>(
        sync: true,
      );
      final ConnectivityService service = ConnectivityService(
        offlineOverride: override.stream,
      );
      // Seed after listen so a persisted choice is not dropped (broadcast
      // events added before a listener are lost).
      override.add(ref.read(offlineByChoiceProvider));
      ref.listen<bool>(offlineByChoiceProvider, (bool? _, bool next) {
        if (!override.isClosed) {
          override.add(next);
        }
      });
      ref.onDispose(() {
        unawaited(override.close());
        unawaited(service.dispose());
      });
      return service;
    });

/// Live [NetworkState]. Not autoDispose: see [connectivityServiceProvider].
final StreamProvider<NetworkState> networkStateProvider =
    StreamProvider<NetworkState>((Ref ref) {
      return ref.watch(connectivityServiceProvider).watch();
    });

/// Project name on the line. Derived from [currentProjectDetailsProvider].
final Provider<String> statusProjectLabelProvider = Provider<String>((Ref ref) {
  final String? id = ref.watch(openProjectIdProvider);
  if (id == null) {
    return Copy.statusNoProject;
  }
  return ref.watch(currentProjectDetailsProvider)?.name ?? id;
});

/// Pinned context label from the open project's [ContextState].
final Provider<String> statusContextProvider = Provider<String>((Ref ref) {
  final AsyncValue<ContextState> value = ref.watch(openProjectContextProvider);
  return contextStatusLabel(value.asData?.value ?? const ContextState());
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

void _back(BuildContext context) {
  final GoRouter router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
    return;
  }
  final Uri uri = GoRouterState.of(context).uri;
  if (uri.queryParameters.containsKey(AppRoutes.filterQuery)) {
    context.go(uri.path);
    return;
  }
  context.go(ShellTitle.parentOf(uri.path));
}

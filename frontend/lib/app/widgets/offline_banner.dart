import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/network/network.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/features/settings/presentation/offline_switch.dart';

// The notifier is private so this file holds one public class (FE-STR-06).
// ignore_for_file: library_private_types_in_public_api

/// Explains offline working on the transition into [NetworkState.offline].
///
/// Dismissible, never a dialog, and shown once per spell — not on rebuild
/// and not on navigation. Never shown when the operator chose to stay
/// offline.
class OfflineBanner extends ConsumerWidget {
  /// Creates the offline banner.
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool visible = ref.watch(offlineBannerVisibleProvider);
    if (!visible) {
      return const SizedBox.shrink();
    }
    return AppBanner(
      message: Copy.offlineWorking,
      icon: Icons.cloud_off,
      tone: SnackTone.info,
      onDismiss: () {
        ref.read(offlineBannerVisibleProvider.notifier).dismiss();
      },
    );
  }
}

/// Whether the banner is showing. Kept alive with the shell (FE-STATE-09).
final NotifierProvider<_OfflineBannerGate, bool> offlineBannerVisibleProvider =
    NotifierProvider<_OfflineBannerGate, bool>(_OfflineBannerGate.new);

class _OfflineBannerGate extends Notifier<bool> {
  @override
  bool build() {
    // Listen, do not watch: a rebuild or a navigation must not count as a
    // new transition into offline.
    ref.listen<AsyncValue<NetworkState>>(networkStateProvider, (
      AsyncValue<NetworkState>? previous,
      AsyncValue<NetworkState> next,
    ) {
      final NetworkState? from = previous?.value;
      final NetworkState? to = next.value;
      if (to == null) {
        return;
      }
      if (to == NetworkState.offline) {
        // Choosing to stay offline is not news to the operator, and the
        // status line already says so.
        if (from != NetworkState.offline &&
            !ref.read(offlineByChoiceProvider)) {
          state = true;
        }
        return;
      }
      state = false;
    });
    ref.listen<bool>(offlineByChoiceProvider, (bool? _, bool byChoice) {
      if (byChoice) {
        state = false;
      }
    });
    return false;
  }

  /// Hides the banner until the next transition into offline.
  void dismiss() {
    state = false;
  }
}

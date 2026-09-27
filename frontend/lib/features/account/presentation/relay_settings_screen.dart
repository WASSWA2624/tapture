import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';

/// Per-project relay controls. Sending exists only when relay is enabled.
class RelaySettingsScreen extends StatelessWidget {
  /// Creates the screen.
  const RelaySettingsScreen({
    super.key,
    required this.enabled,
    required this.neverRelay,
    required this.queued,
    required this.sent,
    required this.purged,
    this.onSend,
  });

  /// True after a project manager turns relay on.
  final bool enabled;

  /// A never-relay project offers no send action.
  final bool neverRelay;

  /// Packages waiting on this device.
  final int queued;

  /// Packages the server accepted.
  final int sent;

  /// Packages the server has purged.
  final int purged;

  /// Sends the queue. Null hides the action.
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    final bool canSend = enabled && !neverRelay;
    return AppPage(
      title: Copy.relayTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!enabled) const Text(Copy.relayOff),
          if (neverRelay) const Text(Copy.relayNever),
          Text('${Copy.relayQueued} $queued'),
          Text('${Copy.relaySent} $sent'),
          Text('${Copy.relayPurged} $purged'),
          if (canSend)
            AppButton(
              label: Copy.relaySend,
              onPressed: onSend,
            ),
        ],
      ),
    );
  }
}

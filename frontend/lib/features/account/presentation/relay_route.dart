import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/backend/relay_queue.dart';
import 'package:tapture/core/backend/relay_snapshot.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/network/offline_now.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/merge/merge.dart';
import 'package:tapture/features/projects/projects.dart';

import '../domain/role_gate.dart';
import 'account_session.dart';
import 'relay_controller.dart';

/// Optional encrypted change exchange, using the existing package and merge flow.
class RelayRoute extends ConsumerStatefulWidget {
  /// Opens the current project's relay controls.
  const RelayRoute({super.key});
  @override
  ConsumerState<RelayRoute> createState() => _RelayRouteState();
}

class _RelayRouteState extends ConsumerState<RelayRoute> {
  final TextEditingController _key = TextEditingController();
  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(backendSessionProvider);
    ref.watch(backendConfigProvider);
    final String? projectId = ref.watch(currentProjectProvider);
    final RoleGate? role = session == null
        ? null
        : roleGateFor(session.config, projectId: projectId);
    final bool online =
        !ref.watch(offlineNowProvider) && session?.canUseBackend == true;
    final action = ref.watch(relayControllerProvider);
    final RelayController controller = ref.read(
      relayControllerProvider.notifier,
    );
    return AppPage(
      title: Copy.relayTitle,
      body: AsyncValueView<RelaySnapshot?>(
        value: ref.watch(relaySnapshotProvider),
        isEmpty: (RelaySnapshot? value) => value == null,
        empty: () => const AppEmptyState(
          icon: AppIcons.project,
          headline: Copy.statusNoProject,
          message: Copy.relayChooseProject,
        ),
        onRetry: () => ref.invalidate(relaySnapshotProvider),
        data: (RelaySnapshot? loaded) {
          final RelaySnapshot view = loaded!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!online) const Text(Copy.backendUnreachable),
              AppListTile(
                title: Copy.relayQueued,
                subtitle: '${view.queued}',
                dense: true,
              ),
              AppListTile(
                title: Copy.relaySent,
                subtitle: '${view.sent}',
                dense: true,
              ),
              AppListTile(
                title: Copy.relayPurged,
                subtitle: '${view.purged}',
                dense: true,
              ),
              if (action.failure case final Failure failure)
                AppListTile(
                  title: failure.message,
                  subtitle: failure.recoveryAction,
                  dense: true,
                ),
              if (view.neverRelay) const Text(Copy.relayNever),
              if (!view.neverRelay &&
                  role?.allows(RoleCapability.manageProject) == true)
                AppSwitchTile(
                  title: Copy.relayEnable,
                  description: Copy.relayEnableHelp,
                  value: view.enabled,
                  enabled: online && !action.busy,
                  onChanged: (bool enabled) => unawaited(
                    controller.run(
                      (RelayQueue queue, String id) =>
                          queue.enable(id, enabled),
                    ),
                  ),
                ),
              if (!view.neverRelay &&
                  role?.allows(RoleCapability.relay) == true) ...<Widget>[
                if (!view.hasKey) ...<Widget>[
                  AppTextField(
                    label: Copy.relaySharedKey,
                    controller: _key,
                    obscureText: true,
                    requiredness: FieldRequiredness.required,
                  ),
                  const Text(Copy.relayKeyHelp),
                  AppButton(
                    label: Copy.save,
                    busy: action.busy,
                    onPressed: () => unawaited(
                      controller.run(
                        (RelayQueue queue, String id) =>
                            queue.saveKey(id, _key.text),
                      ),
                    ),
                  ),
                ],
                if (view.enabled && view.hasKey)
                  AppButton(
                    label: Copy.relayQueueProject,
                    busy: action.busy,
                    onPressed: () => unawaited(controller.queueProject()),
                  ),
                const SizedBox(height: Space.x2),
                AppButton(
                  label: Copy.relaySync,
                  variant: AppButtonVariant.secondary,
                  busy: action.busy,
                  onPressed: online
                      ? () => unawaited(
                          controller.run(
                            (RelayQueue queue, String id) => queue.sync(id),
                          ),
                        )
                      : null,
                ),
                for (final String id in view.incoming)
                  AppListTile(
                    title: Copy.relayReceivedPackage,
                    subtitle: id,
                    onTap: online && view.hasKey
                        ? () => unawaited(_preview(projectId!, id))
                        : null,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _preview(String projectId, String packageId) async {
    final RelayQueue? queue = ref.read(relayQueueProvider);
    if (queue == null) return;
    final Result<Uint8List> result = await queue.receive(projectId, packageId);
    if (!mounted) return;
    switch (result) {
      case FailureResult<Uint8List>(:final failure):
        showAppSnack(context, failure.message, tone: SnackTone.error);
      case Success<Uint8List>(:final value):
        await startPackageImport(
          context,
          ref,
          intoProjectId: projectId,
          supplied: PickedBytes(value, 'relay.tapture'),
          onApplied: () async {
            final Result<void> received = await queue.applied(
              projectId,
              packageId,
            );
            if (!mounted) {
              return;
            }
            ref.invalidate(relaySnapshotProvider);
            if (received is FailureResult<void>) {
              showAppSnack(
                context,
                received.failure.message,
                tone: SnackTone.error,
              );
            }
          },
        );
    }
  }
}

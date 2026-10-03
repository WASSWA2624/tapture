import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/features/cloud/cloud.dart';
import 'package:tapture/features/projects/projects.dart';

import '../settings.dart';
import 'egress_summary_screen.dart';
import 'privacy_settings_controller.dart';

/// Binds the privacy catalogue to durable preferences and controller intents.
final class PrivacySettingsScreen extends ConsumerWidget {
  /// Opens the live outbound-path settings.
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacy = ref.watch(privacySettingsControllerProvider);
    final PrivacySettingsController controller = ref.read(
      privacySettingsControllerProvider.notifier,
    );
    final SettingsStore settings = ref.watch(projectSettingsStoreProvider);
    final Project? project = ref.watch(currentProjectDetailsProvider);
    final AsyncValue<List<Destination>> destinations = ref.watch(
      _destinationsProvider,
    );
    final EgressSwitches switches = EgressSwitches.decode(
      settings.read(SettingKeys.egressOff),
    );
    Future<void> write<T>(SettingKey<T> key, T value) async {
      final Result<void> result = await controller.write(key, value);
      if (context.mounted) {
        if (result case FailureResult<void>(:final Failure failure)) {
          showAppSnack(
            context,
            Copy.of(context).failureMessage(failure),
            tone: SnackTone.error,
          );
        }
      }
    }

    Future<void> gps(bool on) async {
      final Result<void> result = await controller.gps(project, on);
      if (context.mounted) {
        if (result case FailureResult<void>(:final Failure failure)) {
          showAppSnack(
            context,
            Copy.of(context).failureMessage(failure),
            tone: SnackTone.error,
          );
        }
      }
    }

    return EgressSummaryScreen(
      providers: ref.watch(providerRegistryProvider).catalog,
      destinations: destinations.asData?.value ?? const <Destination>[],
      loading: destinations.isLoading,
      failure: destinations.hasError ? Failure.from(destinations.error!) : null,
      operationEnabled: (AiOperation operation) =>
          switches.allows(EgressSwitches.ai(operation)),
      uploadEnabled: (String id) => switches.allows(EgressSwitches.upload(id)),
      onOperation: (AiOperation operation, bool on) => unawaited(
        write(
          SettingKeys.egressOff,
          switches.toggled(EgressSwitches.ai(operation), on: on).encode(),
        ),
      ),
      onUpload: (String id, bool on) => unawaited(
        write(
          SettingKeys.egressOff,
          switches.toggled(EgressSwitches.upload(id), on: on).encode(),
        ),
      ),
      gpsOn:
          project?.settings.gpsEnabled ?? settings.read(SettingKeys.gpsEnabled),
      excludeCoordinates: settings.read(SettingKeys.excludeCoordinates),
      blurFaces: settings.read(SettingKeys.blurFaces),
      onGps: (bool on) => unawaited(gps(on)),
      onExclude: (bool on) =>
          unawaited(write(SettingKeys.excludeCoordinates, on)),
      onBlurFaces: (bool on) => unawaited(write(SettingKeys.blurFaces, on)),
      onRemoveCoordinates: project == null || privacy.removing
          ? null
          : () => _remove(context, ref),
      removedCoordinates: privacy.project == project?.id
          ? privacy.removed
          : null,
    );
  }

  Future<int> _remove(BuildContext context, WidgetRef ref) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final String? project = ref.read(currentProjectProvider);
    if (project == null) return 0;
    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.gpsPrivacyRemoveTitle,
      message: localCopy.gpsPrivacyRemoveMessage(
        ref.read(currentProjectDetailsProvider)?.name ?? project,
      ),
      confirmLabel: localCopy.gpsPrivacyRemoveConfirm,
      destructive: true,
    );
    if (!context.mounted ||
        !confirmed ||
        ref.read(currentProjectProvider) != project) {
      return 0;
    }
    final Result<int> result = await ref
        .read(privacySettingsControllerProvider.notifier)
        .remove(project);
    if (!context.mounted || ref.read(currentProjectProvider) != project) {
      return 0;
    }
    switch (result) {
      case Success<int>(:final int value):
        showAppSnack(
          context,
          localCopy.gpsPrivacyRemoved(value),
          tone: SnackTone.success,
        );
        return value;
      case FailureResult<int>(:final Failure failure):
        showAppSnack(
          context,
          Copy.of(context).failureMessage(failure),
          tone: SnackTone.error,
        );
        return 0;
    }
  }
}

final _destinationsProvider = StreamProvider.autoDispose<List<Destination>>(
  (Ref ref) => ref.watch(destinationRepositoryProvider).watchAll(),
);

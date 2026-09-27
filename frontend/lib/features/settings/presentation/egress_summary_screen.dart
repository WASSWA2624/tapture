import 'package:flutter/widgets.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';

import 'gps_privacy_section.dart';

/// Every outbound path, built from the provider catalogue and destinations.
///
/// The screen only reads flags and reports toggles. It sends nothing.
final class EgressSummaryScreen extends StatelessWidget {
  /// Creates the summary.
  const EgressSummaryScreen({
    this.providers = const <ProviderDescriptor>[],
    this.destinations = const <Destination>[],
    this.loading = false,
    this.failure,
    this.operationEnabled,
    this.uploadEnabled,
    this.onOperation,
    this.onUpload,
    this.gpsOn = false,
    this.excludeCoordinates = true,
    this.onGps,
    this.onExclude,
    this.onRemoveCoordinates,
    super.key,
  });

  /// Catalogue from [ProviderRegistry.catalog].
  final List<ProviderDescriptor> providers;

  /// Saved upload destinations.
  final List<Destination> destinations;

  /// Whether the lists are still loading.
  final bool loading;

  /// Why the summary could not be read.
  final Failure? failure;

  /// Whether [operation] is allowed to send. Off when omitted.
  final bool Function(AiOperation operation)? operationEnabled;

  /// Whether uploads to a destination are allowed. Off when omitted.
  final bool Function(String id)? uploadEnabled;

  /// Flips one operation.
  final void Function(AiOperation operation, bool enabled)? onOperation;

  /// Flips one destination.
  final void Function(String id, bool enabled)? onUpload;

  /// Whether captures store a location.
  final bool gpsOn;

  /// Whether exports omit coordinates.
  final bool excludeCoordinates;

  /// Flips location capture.
  final ValueChanged<bool>? onGps;

  /// Flips export exclusion.
  final ValueChanged<bool>? onExclude;

  /// Removes coordinates already stored and returns how many changed.
  final Future<int> Function()? onRemoveCoordinates;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppPage(
        title: Copy.privacyScreenTitle,
        body: AppErrorState(failure: failed),
      );
    }
    if (loading) {
      return const AppPage(title: Copy.privacyScreenTitle, body: AppSkeleton());
    }
    final List<Widget> rows = <Widget>[
      for (final ProviderDescriptor provider in providers)
        for (final AiOperation operation in provider.operations)
          AppSwitchTile(
            key: ValueKey<String>('egress-${provider.id}-${operation.name}'),
            title: provider.label,
            description: '${_sends(operation)} · ${provider.label}',
            value: operationEnabled?.call(operation) ?? false,
            onChanged: (bool enabled) => onOperation?.call(operation, enabled),
          ),
      for (final Destination destination in destinations)
        AppSwitchTile(
          key: ValueKey<String>('egress-upload-${destination.id}'),
          title: destination.label,
          description: '${Copy.egressSendsFile} · ${destination.label}',
          value: uploadEnabled?.call(destination.id) ?? false,
          onChanged: (bool enabled) => onUpload?.call(destination.id, enabled),
        ),
    ];
    return AppPage(
      title: Copy.privacyScreenTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (rows.isEmpty)
            const AppEmptyState(
              icon: AppIcons.export,
              headline: Copy.privacyEmptyHeadline,
              message: Copy.privacyEmptyMessage,
            )
          else
            ...rows,
          GpsPrivacySection(
            gpsOn: gpsOn,
            excludeCoordinates: excludeCoordinates,
            onGps: onGps,
            onExclude: onExclude,
            onRemove: onRemoveCoordinates,
          ),
        ],
      ),
    );
  }

  static String _sends(AiOperation operation) {
    return switch (operation) {
      AiOperation.readText => Copy.egressSendsImage,
      AiOperation.extractFields ||
      AiOperation.refineText => Copy.egressSendsText,
      AiOperation.transcribe => Copy.egressSendsAudio,
    };
  }
}

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
    this.removedCoordinates,
    this.blurFaces = false,
    this.onBlurFaces,
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

  /// Count from the last committed removal.
  final int? removedCoordinates;

  /// Whether exported photos must pass face detection and blurring.
  final bool blurFaces;

  /// Persists the face-blurring preference.
  final ValueChanged<bool>? onBlurFaces;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Failure? failed = failure;
    if (failed != null) {
      return AppPage(
        title: localCopy.privacyScreenTitle,
        body: AppErrorState(failure: failed),
      );
    }
    if (loading) {
      return AppPage(
        title: localCopy.privacyScreenTitle,
        body: const AppSkeleton(),
      );
    }
    final List<Widget> rows = <Widget>[
      for (final ProviderDescriptor provider in providers)
        for (final AiOperation operation in provider.operations)
          AppSwitchTile(
            key: ValueKey<String>('egress-${provider.id}-${operation.name}'),
            title: provider.label,
            description: '${_sends(operation, localCopy)} · ${provider.label}',
            value: operationEnabled?.call(operation) ?? false,
            onChanged: (bool enabled) => onOperation?.call(operation, enabled),
          ),
      for (final Destination destination in destinations)
        AppSwitchTile(
          key: ValueKey<String>('egress-upload-${destination.id}'),
          title: destination.label,
          description: '${localCopy.egressSendsFile} · ${destination.label}',
          value: uploadEnabled?.call(destination.id) ?? false,
          onChanged: (bool enabled) => onUpload?.call(destination.id, enabled),
        ),
    ];
    return AppPage(
      title: localCopy.privacyScreenTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (rows.isEmpty)
            AppEmptyState(
              icon: AppIcons.export,
              headline: localCopy.privacyEmptyHeadline,
              message: localCopy.privacyEmptyMessage,
            )
          else
            ...rows,
          GpsPrivacySection(
            gpsOn: gpsOn,
            excludeCoordinates: excludeCoordinates,
            onGps: onGps,
            onExclude: onExclude,
            onRemove: onRemoveCoordinates,
            removed: removedCoordinates,
          ),
          AppSwitchTile(
            key: const ValueKey<String>('privacy-blur-faces'),
            title: localCopy.faceBlurTitle,
            description: localCopy.faceBlurEffect,
            value: blurFaces,
            enabled: onBlurFaces != null,
            onChanged: (bool on) => onBlurFaces?.call(on),
          ),
        ],
      ),
    );
  }

  static String _sends(AiOperation operation, LocalizedCopy copy) {
    return switch (operation) {
      AiOperation.readText => copy.egressSendsImage,
      AiOperation.extractFields ||
      AiOperation.refineText => copy.egressSendsText,
      AiOperation.transcribe => copy.egressSendsAudio,
    };
  }
}
